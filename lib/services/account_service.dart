import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:math' show Random;

import 'package:crypto/crypto.dart' show sha256;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/firebase_config.dart';
import '../firebase_options.dart';
import 'analytics_service.dart';
import 'promo_code_service.dart';
import 'purchase_service.dart';

/// Who is signed in, in the app's own terms — so nothing above this service
/// has to know Firebase types, and a test can put a user here directly.
@immutable
class AccountUser {
  final String uid;
  final String? email;

  /// `apple.com`, `google.com` or `password`.
  final String provider;

  const AccountUser({required this.uid, required this.email, required this.provider});

  bool get isApple => provider == 'apple.com';
  bool get isGoogle => provider == 'google.com';
  bool get isEmail => provider == 'password';
}

/// How a sign-in attempt ended. The UI turns each into one sentence; the
/// distinction is the whole point, because "Sign-in failed" for a mistyped
/// password and for a dead network want opposite reactions.
enum AccountOutcome {
  success,
  cancelled,
  wrongCredentials,
  weakPassword,
  emailInUse,
  invalidEmail,
  offline,
  needsRecentLogin,
  notConfigured,
  error,
}

/// Accounts, backed by Firebase Auth.
///
/// One thing exists to be true here: **Pro follows the person, not the
/// phone.** A purchase already follows the store account it was made on, but
/// stops at the platform border; a promo code, before this, was a flag in one
/// phone's storage. So on sign-in the account is handed to RevenueCat
/// (the purchase side) and asked about its redemption (the code side), and
/// on sign-out both are given back.
///
/// Everything here is a no-op until firebase_options.dart is filled in —
/// see [FirebaseConfig.isConfigured].
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  /// The signed-in user, or null. Widgets listen to this.
  final ValueNotifier<AccountUser?> user = ValueNotifier(null);

  /// Fired with the account's "Pro by code" standing whenever it is learned:
  /// true after a redemption is found (or made), false on sign-out.
  void Function(bool byCode, String? code)? onCodeProChanged;

  /// Fired once the account has been handed to analytics, so the profile can
  /// be pushed again under the real identity rather than waiting for whatever
  /// happens to change next.
  void Function()? onIdentified;

  bool _ready = false;
  bool get isReady => _ready;

  StreamSubscription<User?>? _auth;

  Future<void> init() async {
    if (!FirebaseConfig.isConfigured) {
      if (kDebugMode) debugPrint('[Account] firebase_options.dart is placeholders — accounts off');
      return;
    }
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _ready = true;
    await GoogleSignIn.instance.initialize(
      clientId: FirebaseConfig.googleIosClientId,
      serverClientId: FirebaseConfig.isPlaceholder(FirebaseConfig.googleWebClientId)
          ? null
          : FirebaseConfig.googleWebClientId,
    );
    _auth = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  // ── sign in ──────────────────────────────────────────────────────────────

  Future<AccountOutcome> signInWithGoogle() async {
    if (!_ready) return AccountOutcome.notConfigured;
    AnalyticsService.instance.capture(Ev.signInStarted, {'provider': 'google'});
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return _fail('google', 'no id token', AccountOutcome.error);
      await FirebaseAuth.instance
          .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      return _ok('google');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return AccountOutcome.cancelled;
      return _fail('google', e, AccountOutcome.error);
    } on FirebaseAuthException catch (e) {
      return _fail('google', e, _map(e));
    } catch (e) {
      return _fail('google', e, AccountOutcome.error);
    }
  }

  Future<AccountOutcome> signInWithApple() async {
    if (!_ready) return AccountOutcome.notConfigured;
    AnalyticsService.instance.capture(Ev.signInStarted, {'provider': 'apple'});
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        // The native sheet. The nonce ties the token Apple returns to this
        // one request, which Firebase checks.
        final raw = _nonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: const [AppleIDAuthorizationScopes.email],
          nonce: sha256.convert(utf8.encode(raw)).toString(),
        );
        final credential = OAuthProvider('apple.com').credential(
          idToken: apple.identityToken,
          rawNonce: raw,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } else {
        // Android has no native sheet; Firebase runs Apple's web flow in a
        // custom tab and brings the result back itself.
        final provider = AppleAuthProvider()..addScope('email');
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      return _ok('apple');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return AccountOutcome.cancelled;
      return _fail('apple', e, AccountOutcome.error);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' || e.code == 'canceled') return AccountOutcome.cancelled;
      return _fail('apple', e, _map(e));
    } catch (e) {
      return _fail('apple', e, AccountOutcome.error);
    }
  }

  Future<AccountOutcome> signInWithEmail(String email, String password) async {
    if (!_ready) return AccountOutcome.notConfigured;
    AnalyticsService.instance.capture(Ev.signInStarted, {'provider': 'password'});
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return _ok('password');
    } on FirebaseAuthException catch (e) {
      return _fail('password', e, _map(e));
    } catch (e) {
      return _fail('password', e, AccountOutcome.error);
    }
  }

  Future<AccountOutcome> createWithEmail(String email, String password) async {
    if (!_ready) return AccountOutcome.notConfigured;
    AnalyticsService.instance.capture(Ev.signInStarted, {'provider': 'password', 'new': true});
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email.trim(), password: password);
      return _ok('password', created: true);
    } on FirebaseAuthException catch (e) {
      return _fail('password', e, _map(e));
    } catch (e) {
      return _fail('password', e, AccountOutcome.error);
    }
  }

  Future<AccountOutcome> sendPasswordReset(String email) async {
    if (!_ready) return AccountOutcome.notConfigured;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return AccountOutcome.success;
    } on FirebaseAuthException catch (e) {
      return _map(e);
    } catch (_) {
      return AccountOutcome.error;
    }
  }

  // ── sign out / delete ────────────────────────────────────────────────────

  Future<void> signOut() async {
    if (!_ready) return;
    AnalyticsService.instance.capture(Ev.signedOut);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  /// Apple requires that an app which creates accounts can also delete them,
  /// in the app. Firebase refuses when the sign-in is old; the UI then asks
  /// for a fresh sign-in and tries again.
  Future<AccountOutcome> deleteAccount() async {
    if (!_ready) return AccountOutcome.notConfigured;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return AccountOutcome.error;
    try {
      // Give up Pro-by-code first: the auth token is still valid here, and
      // once the user is gone nothing could clean the redemption up.
      await PromoCodeService.instance.forget(u.uid);
      await u.delete();
      AnalyticsService.instance.capture(Ev.accountDeleted);
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      return AccountOutcome.success;
    } on FirebaseAuthException catch (e) {
      return _map(e);
    } catch (e) {
      AnalyticsService.instance.error(Ev.signInFailed, e, {'step': 'delete'});
      return AccountOutcome.error;
    }
  }

  // ── internals ────────────────────────────────────────────────────────────

  Future<void> _onAuth(User? u) async {
    if (u == null) {
      user.value = null;
      onCodeProChanged?.call(false, null);
      await PurchaseService.instance.reset();
      // Anonymous again, and deliberately a NEW anonymous: the next person to
      // pick this phone up must not inherit the last one's identity.
      await AnalyticsService.instance.resetIdentity();
      return;
    }
    final provider = u.providerData.isNotEmpty ? u.providerData.first.providerId : 'password';
    user.value = AccountUser(uid: u.uid, email: u.email, provider: provider);
    // The account id, not the address: it never changes, so a person stays one
    // person across both phones and across an email change. Everything this
    // device did while anonymous is merged in by this call.
    await AnalyticsService.instance.identify(u.uid, properties: {
      'account': true,
      'auth_provider': provider,
      'email': u.email,
    });
    onIdentified?.call();
    // The purchase side: the store receipt now belongs to this person.
    await PurchaseService.instance.identify(u.uid);
    // The code side: has this person already spent one?
    final code = await PromoCodeService.instance.redeemedCode(u.uid);
    if (code != null) onCodeProChanged?.call(true, code);
  }

  AccountOutcome _ok(String provider, {bool created = false}) {
    AnalyticsService.instance.capture(Ev.signedIn, {'provider': provider, 'new': created});
    return AccountOutcome.success;
  }

  AccountOutcome _fail(String provider, Object e, AccountOutcome outcome) {
    if (kDebugMode) debugPrint('[Account] $provider sign-in failed: $e');
    AnalyticsService.instance.error(Ev.signInFailed, e, {'provider': provider, 'outcome': outcome.name});
    return outcome;
  }

  static AccountOutcome _map(FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          AccountOutcome.wrongCredentials,
        'weak-password' => AccountOutcome.weakPassword,
        'email-already-in-use' ||
        'account-exists-with-different-credential' =>
          AccountOutcome.emailInUse,
        'invalid-email' || 'missing-email' => AccountOutcome.invalidEmail,
        'network-request-failed' => AccountOutcome.offline,
        'requires-recent-login' => AccountOutcome.needsRecentLogin,
        _ => AccountOutcome.error,
      };

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @visibleForTesting
  void dispose() {
    _auth?.cancel();
  }
}
