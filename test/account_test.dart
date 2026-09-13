import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/config/firebase_config.dart';
import 'package:improvy/firebase_options.dart';
import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/services/account_service.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/account_sheet.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// Pro follows the person, not the phone. These pin the two halves of that
/// which can be checked without a Firebase project: how the two doors to Pro
/// combine, and that the app is exactly as it was until the project exists.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  Future<AppProvider> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();
    return p;
  }

  group('two doors to Pro', () {
    test('a code opens it', () async {
      final p = await fresh();
      expect(p.isPro, isFalse);
      p.setCodePro(true, 'LAUNCH2026');
      expect(p.isPro, isTrue);
      expect(p.promoCode, 'LAUNCH2026');
    });

    test('signing out closes the code door and not the store door', () async {
      final p = await fresh();
      p.setIsPro(true);
      p.setCodePro(true, 'X-1');
      p.setCodePro(false);
      expect(p.isPro, isTrue, reason: 'the purchase is still theirs');
      expect(p.promoCode, isNull);
    });

    test('a refund closes the store door and not the code door', () async {
      final p = await fresh();
      p.setCodePro(true, 'X-1');
      p.setIsPro(true);
      p.setIsPro(false);
      expect(p.isPro, isTrue, reason: 'the code was spent on the account');
    });

    test('a licence on the account is a third door, with the same rules', () async {
      final p = await fresh();
      p.setWebPro(true);
      expect(p.isPro, isTrue);
      // Signing out takes it with it — it is the account's — and touches
      // neither of the other two.
      p.setIsPro(true);
      p.setWebPro(false);
      expect(p.isPro, isTrue, reason: 'the purchase is still theirs');
      p.setIsPro(false);
      p.setCodePro(true, 'X-1');
      p.setWebPro(false);
      expect(p.isPro, isTrue, reason: 'the code is still theirs');
    });

    test('the licence survives a restart, like the code', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final a = AppProvider(storage);
      await a.init();
      a.setWebPro(true);
      final b = AppProvider(storage);
      await b.init();
      expect(b.isPro, isTrue);
    });

    test('the code survives a restart', () async {
      // Firestore answers after launch; the app must not open locked for the
      // seconds until it does.
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final a = AppProvider(storage);
      await a.init();
      a.setCodePro(true, 'KEEP');
      final b = AppProvider(storage);
      await b.init();
      expect(b.isPro, isTrue);
      expect(b.promoCode, 'KEEP');
    });

    test('losing Pro either way switches adaptive difficulty off', () async {
      final p = await fresh();
      p.setCodePro(true, 'X-1');
      p.setAdaptiveDifficulty(true);
      p.setCodePro(false);
      expect(p.adaptiveDifficulty, isFalse);
    });
  });

  group('the Firebase project', () {
    test('is improvy-f470f, with both platforms under com.improvy.app', () {
      // The Kotlin namespace is com.improvy.improvy, which is only where the
      // sources live. Registering THAT in Firebase mints an OAuth client for
      // an app that does not exist, and Google sign-in fails on a device with
      // nothing in the logs to say why.
      expect(FirebaseConfig.isConfigured, isTrue);
      for (final o in [DefaultFirebaseOptions.android, DefaultFirebaseOptions.ios]) {
        expect(o.projectId, 'improvy-f470f');
        expect(o.messagingSenderId, '376089080639');
        expect(o.apiKey, isNot(startsWith(FirebaseConfig.placeholder)));
      }
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.improvy.app');
      expect(File('android/app/build.gradle.kts').readAsStringSync(),
          contains('applicationId = "com.improvy.app"'));
    });

    test('each app carries its own key and id', () {
      // Two apps in one project: same project, different API key and app id.
      // Pasting one app's block into both is the easy mistake here.
      final a = DefaultFirebaseOptions.android;
      final i = DefaultFirebaseOptions.ios;
      expect(a.apiKey, isNot(i.apiKey));
      expect(a.appId, contains(':android:'));
      expect(i.appId, contains(':ios:'));
    });

    test('the OAuth clients are the project\'s own', () {
      // Every client ID starts with the project number. One copied from
      // another project is the one mistake that still compiles.
      const sender = '376089080639';
      expect(FirebaseConfig.googleIosClientId, startsWith('$sender-'));
      expect(FirebaseConfig.googleIosClientId, endsWith('.apps.googleusercontent.com'));
      expect(FirebaseConfig.googleWebClientId, startsWith('$sender-'));
      expect(FirebaseConfig.googleWebClientId, endsWith('.apps.googleusercontent.com'));
      // Web and iOS are different clients; using one for the other is a
      // silent failure on whichever platform got the wrong one.
      expect(FirebaseConfig.googleWebClientId, isNot(FirebaseConfig.googleIosClientId));
      expect(FirebaseConfig.authDomain, 'improvy-f470f.firebaseapp.com');
    });

    test('ios/ is in step with the options', () {
      // tool/sync_firebase_ios.dart writes both of these. A rotated client id
      // or a regenerated firebase_options.dart leaves them stale, and the
      // failure is a sign-in sheet that opens, succeeds, and never returns.
      final reversed = FirebaseConfig.googleIosClientId!.split('.').reversed.join('.');
      expect(File('ios/Runner/Info.plist').readAsStringSync(), contains(reversed));
      expect(File('ios/Runner/Runner.entitlements').readAsStringSync(),
          contains('com.apple.developer.applesignin'));
    });

    test('a service that never initialised answers, instead of throwing', () {
      // init() is best-effort at startup: a device that cannot reach Firebase
      // must cost the account, not the launch.
      final a = AccountService.instance;
      expect(a.isReady, isFalse);
    });

    test('every door answers "not available" before init', () async {
      final a = AccountService.instance;
      expect(await a.signInWithGoogle(), AccountOutcome.notConfigured);
      expect(await a.signInWithApple(), AccountOutcome.notConfigured);
      expect(await a.signInWithEmail('a@b.c', 'secret1'), AccountOutcome.notConfigured);
      expect(await a.createWithEmail('a@b.c', 'secret1'), AccountOutcome.notConfigured);
      expect(await a.deleteAccount(), AccountOutcome.notConfigured);
      await a.signOut(); // and this simply returns
    });
  });

  group('the build stays in step', () {
    test('the Podfile names nothing Firebase', () {
      // Firebase comes in through Swift Package Manager. Naming any of it in
      // the Podfile as well links the same framework twice, and the archive
      // dies on "Multiple commands produce ... Metadata.appintents" — after
      // "Xcode archive done", so the failure costs a whole build and reads
      // like a signing problem rather than a duplicate dependency.
      // Comments are allowed to name it — the one above the removal explains
      // exactly this — so only real pod lines count.
      final lines = File('ios/Podfile')
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'));
      final declared = RegExp("pod ['\"]([^'\"]+)");
      final pods = lines
          .map((l) => declared.firstMatch(l)?.group(1))
          .whereType<String>()
          .toList();
      for (final pod in pods) {
        expect(pod.toLowerCase(), isNot(contains('firebase')), reason: pod);
        expect(pod.toLowerCase(), isNot(contains('google')), reason: pod);
      }
      // And the matcher itself still sees a pod line, so this cannot pass by
      // failing to look.
      expect(declared.firstMatch("  pod 'FirebaseFirestore', :git => '…'")?.group(1),
          'FirebaseFirestore');
    });

    test('Codemagic syncs ios/ from the options before it builds', () {
      final ci = File('codemagic.yaml').readAsStringSync();
      expect(ci, contains('dart run tool/sync_firebase_ios.dart'));
      expect(ci.indexOf('sync_firebase_ios'), lessThan(ci.indexOf('Install CocoaPods')));
      expect(ci, contains('com.apple.developer.applesignin'));
    });

    test('the rules only let a code be spent together with a redemption', () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules, contains("allow list: if false"));
      expect(rules, contains("request.resource.data.uses == resource.data.uses + 1"));
      expect(rules, contains("redemptionAfter(request.auth.uid).data.code == code"));
      expect(rules, contains("request.resource.data.at == request.time"));
      expect(File('firebase.json').readAsStringSync(), contains('firestore.rules'));
    });
  });

  group('in Settings', () {
    Future<AppProvider> pumpSettings(WidgetTester t) async {
      final p = await fresh();
      t.view.physicalSize = const Size(390, 3200);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(() => AccountService.instance.user.value = null);
      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true, fontFamily: 'Lexend'),
          home: SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}),
        ),
      ));
      await t.pump(const Duration(milliseconds: 700));
      return p;
    }

    /// The sheet slides up over a whole (tall) test viewport; one long pump
    /// moves the clock but not the animation, so it is driven in frames.
    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('the account card offers to sign in, and the sheet opens from it', (t) async {
      await pumpSettings(t);
      expect(find.byKey(const Key('account-signed-out')), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('account-sign-in')));
      await t.tap(find.byKey(const Key('account-sign-in')));
      await settle(t);
      expect(find.byType(AccountSheet), findsOneWidget);
      // On an Android test host Google leads; Apple is still offered.
      expect(find.byKey(const Key('account-google')), findsOneWidget);
      expect(find.byKey(const Key('account-apple')), findsOneWidget);
      expect(find.byKey(const Key('account-email')), findsOneWidget);
    });

    testWidgets('signed in, the card names the account and can leave', (t) async {
      await pumpSettings(t);
      AccountService.instance.user.value =
          const AccountUser(uid: 'u1', email: 'lorenzo@example.com', provider: 'google.com');
      await t.pump();
      expect(find.text('lorenzo@example.com'), findsOneWidget);
      expect(find.byKey(const Key('account-sign-out')), findsOneWidget);
      expect(find.byKey(const Key('account-delete')), findsOneWidget);
    });

    testWidgets('a Pro from another door sees no code card at all', (t) async {
      // Nothing to unlock, nothing to show which code did it.
      final p = await pumpSettings(t);
      expect(find.byKey(const Key('promo-field')), findsOneWidget);
      p.setWebPro(true);
      await t.pump();
      expect(find.byKey(const Key('promo-field')), findsNothing);
      expect(find.byKey(const Key('promo-redeemed')), findsNothing);
    });

    testWidgets('a redeemed code is shown, and the field is gone', (t) async {
      final p = await pumpSettings(t);
      expect(find.byKey(const Key('promo-field')), findsOneWidget);
      p.setCodePro(true, 'LAUNCH2026');
      await t.pump();
      expect(find.byKey(const Key('promo-redeemed')), findsOneWidget);
      expect(find.textContaining('LAUNCH2026'), findsOneWidget);
      expect(find.byKey(const Key('promo-field')), findsNothing);
    });

    testWidgets('redeeming while signed out asks for the account first', (t) async {
      await pumpSettings(t);
      await t.ensureVisible(find.byKey(const Key('promo-field')));
      await t.enterText(find.byKey(const Key('promo-field')), 'launch 2026');
      await t.pump();
      await t.tap(find.byKey(const Key('promo-redeem')));
      await settle(t);
      expect(find.byType(AccountSheet), findsOneWidget,
          reason: 'the code is spent on an account, so it starts by making one');
    });

    testWidgets('the email form opens inside the sheet', (t) async {
      await pumpSettings(t);
      await t.ensureVisible(find.byKey(const Key('account-sign-in')));
      await t.tap(find.byKey(const Key('account-sign-in')));
      await settle(t);
      await t.tap(find.byKey(const Key('account-email')));
      await settle(t);
      expect(find.byKey(const Key('account-email-go')), findsOneWidget);
      expect(find.byKey(const Key('account-forgot')), findsOneWidget);
      // Switch to creating, and the forgot link — meaningless there — goes.
      await t.tap(find.byKey(const Key('account-switch')));
      await settle(t);
      expect(find.byKey(const Key('account-forgot')), findsNothing);
      // A tap with placeholders configured says so, in words, not a crash.
      await t.tap(find.byKey(const Key('account-email-go')));
      await settle(t);
      expect(find.byKey(const Key('account-message')), findsOneWidget);
    });
  });
}
