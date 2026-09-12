import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/services/storage_service.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// Reminders were never delivered, and the app said they were on.
///
/// The OS permission was only ever requested from the priming sheet, which
/// needs a rare run of good sessions to appear and appears once in a
/// lifetime. Everyone else turned reminders on in Settings, watched the card
/// light up amber, and got nothing — the switch stored a preference and
/// scheduled notifications the system then dropped on the floor.
///
/// These pin the two halves of the fix: the switch asks, and when the answer
/// is no the card says so instead of pretending.
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

  group('the switch and the OS', () {
    test('turning reminders on asks, and a refusal is recorded', () async {
      // No platform plugin under a unit test, so the request can only fail —
      // which is the case that matters: the app must notice.
      final p = await fresh();
      expect(p.notifBlocked, isFalse);
      await p.setNotifDailyOn(true);
      expect(p.notifDailyOn, isTrue, reason: 'the preference is still theirs');
      expect(p.notifBlocked, isTrue,
          reason: 'the OS said no, and the app has to know that');
      expect(p.notifCanAsk, isFalse, reason: 'it has now been asked');
    });

    test('turning them off stops claiming anything is blocked', () async {
      final p = await fresh();
      await p.setNotifDailyOn(true);
      await p.setNotifDailyOn(false);
      expect(p.notifBlocked, isFalse);
    });

    test('the choice survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final p = AppProvider(storage);
      await p.init();
      await p.setNotifDailyOn(true);

      final again = AppProvider(storage);
      await again.init();
      expect(again.notifDailyOn, isTrue);
      // And the app re-reads the OS rather than trusting the old answer: the
      // permission is changed outside the app, where nothing tells us.
      expect(again.notifBlocked, isFalse, reason: 'not known until asked');
      await again.refreshNotifPermission();
      expect(again.notifBlocked, isTrue);
    });

    test('a brand new install is the broken state, and knows it', () async {
      // The switch ships ON. Before this, that meant the card was amber from
      // the first launch with no permission behind it and nothing delivered,
      // for everyone who never saw the priming sheet.
      final p = await fresh();
      expect(p.notifDailyOn, isTrue);
      await p.refreshNotifPermission();
      expect(p.notifBlocked, isTrue);
      expect(p.notifCanAsk, isTrue, reason: 'the OS has never been asked yet');
    });

    test('once asked, the offer becomes the system settings', () async {
      final p = await fresh();
      await p.allowNotifications();
      expect(p.notifBlocked, isTrue, reason: 'refused, under test');
      expect(p.notifCanAsk, isFalse,
          reason: 'both platforms ask once; after that only settings can undo it');
    });

    test('turning the switch off claims nothing', () async {
      final p = await fresh();
      await p.setNotifDailyOn(false);
      expect(p.notifBlocked, isFalse);
      expect(p.notifCanAsk, isFalse);
    });
  });

  testWidgets('the card owns up, and offers the way out', (t) async {
    final p = await fresh();
    t.view.physicalSize = const Size(390, 3400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
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

    // Off: nothing to warn about.
    await p.setNotifDailyOn(false);
    await t.pump();
    expect(find.byKey(const Key('notif-blocked')), findsNothing);

    // On, never asked: the row owns up and the button asks.
    await p.refreshNotifPermission();
    await p.setNotifDailyOn(true);
    await t.pump();
    expect(find.byKey(const Key('notif-blocked')), findsOneWidget);

    // Asked and refused: the button becomes the way into the settings, which
    // is the only thing left that can undo it.
    expect(find.byKey(const Key('notif-open-settings')), findsOneWidget);
    expect(find.byKey(const Key('notif-allow')), findsNothing);
  });
}
