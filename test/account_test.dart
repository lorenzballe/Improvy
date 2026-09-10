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

  group('until the Firebase project exists', () {
    test('the options are placeholders and the app knows it', () {
      expect(FirebaseConfig.isConfigured, isFalse);
      expect(FirebaseConfig.googleIosClientId, isNull);
      for (final o in [DefaultFirebaseOptions.android, DefaultFirebaseOptions.ios]) {
        expect(o.apiKey, startsWith(FirebaseConfig.placeholder));
        expect(o.projectId, startsWith(FirebaseConfig.placeholder));
      }
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.improvy.app');
    });

    test('every door answers "not available" instead of throwing', () async {
      final a = AccountService.instance;
      expect(a.isReady, isFalse);
      expect(await a.signInWithGoogle(), AccountOutcome.notConfigured);
      expect(await a.signInWithApple(), AccountOutcome.notConfigured);
      expect(await a.signInWithEmail('a@b.c', 'secret1'), AccountOutcome.notConfigured);
      expect(await a.createWithEmail('a@b.c', 'secret1'), AccountOutcome.notConfigured);
      expect(await a.deleteAccount(), AccountOutcome.notConfigured);
      await a.signOut(); // and this simply returns
    });

    test('nothing in ios/ has been touched yet', () {
      // The Sign in with Apple entitlement only signs once the App ID has
      // the capability, so it must not appear before the project does — or
      // the next build dies at codesign for a feature that cannot work yet.
      expect(File('ios/Runner/Runner.entitlements').readAsStringSync(),
          isNot(contains('applesignin')));
      expect(File('ios/Runner/Info.plist').readAsStringSync(),
          isNot(contains('googleusercontent')));
    });
  });

  group('the build stays in step', () {
    test('the precompiled Firestore matches the SDK firebase_core pins', () {
      final podfile = File('ios/Podfile').readAsStringSync();
      final tag = RegExp(r"firestore-ios-sdk-frameworks\.git', :tag => '([\d.]+)'")
          .firstMatch(podfile)
          ?.group(1);
      expect(tag, isNotNull, reason: 'the Podfile should pin the binary Firestore');
      final lock = File('pubspec.lock').readAsStringSync();
      final core = RegExp(r'  firebase_core:\n(?:.*\n){1,9}?    version: "([^"]+)"')
          .firstMatch(lock)
          ?.group(1);
      expect(core, isNotNull);
      final home = Platform.environment['HOME'] ?? '/root';
      final pinned = File('$home/.pub-cache/hosted/pub.dev/firebase_core-$core/ios/firebase_sdk_version.rb');
      if (!pinned.existsSync()) {
        markTestSkipped('pub cache not at $home/.pub-cache');
        return;
      }
      final sdk = RegExp(r"'([\d.]+)'").firstMatch(pinned.readAsStringSync())?.group(1);
      expect(tag, sdk,
          reason: 'a mismatched tag fails pod install on Codemagic; bump the Podfile tag');
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
