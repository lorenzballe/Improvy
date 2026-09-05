import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/screens/key_analytics_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/screens/stats_screen.dart';
import 'package:improvy/widgets/paywall_modal.dart';

import 'screens_render_test.dart' show loadRealFonts, providerWith;

/// Translation is where a tight layout goes to die. "RANK" becomes
/// "POSIZIONE", "Answer Delay" becomes "Pausa prima della risposta", and a
/// label that fitted in English is suddenly clipped, ellipsised, or overflowing
/// with the yellow stripes that release builds hide.
///
/// So every screen is laid out again in each language, on the smallest phone
/// the app supports. Under `flutter test` an overflow is an exception and the
/// test fails — which is the only way to find these without twelve devices.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  /// An iPhone SE. If a translation fits here it fits everywhere.
  const small = Size(320, 568);

  Future<void> show(
      WidgetTester t, Widget child, AppProvider provider, Locale locale) async {
    t.view.physicalSize = small;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
          scaffoldBackgroundColor: const Color(0xFF0F0A1A),
          useMaterial3: true,
          fontFamily: 'Lexend',
        ),
        home: child,
      ),
    ));
    // Entrance animations run on real controllers; settle the ones that end.
    await t.pump(const Duration(milliseconds: 700));
  }

  for (final code in ['it', 'es', 'fr', 'de', 'pt']) {
    final locale = Locale(code);

    group(code, () {
      testWidgets('home', (t) async {
        await show(
          t,
          HomeScreen(
              onShowPaywall: ([_]) {},
              onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {},
              onStartDaily: () {}),
          await providerWith(populated: true),
          locale,
        );
      });

      testWidgets('stats', (t) async {
        await show(t, const StatsScreen(),
            await providerWith(populated: true), locale);
      });

      testWidgets('key analysis', (t) async {
        await show(
          t,
          KeyAnalyticsScreen(keyName: 'C', onBack: () {}, onShowPaywall: ([_]) {}),
          await providerWith(populated: true),
          locale,
        );
      });

      testWidgets('settings', (t) async {
        await show(
          t,
          SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}),
          await providerWith(),
          locale,
        );
      });

      testWidgets('note to number setup', (t) async {
        await show(
          t,
          NoteToNumberSetup(
              initialKey: 'B♭',
              isPro: false,
              onShowPaywall: () {},
              onCancel: () {},
              onStart: (_, _, _, _) {}),
          await providerWith(),
          locale,
        );
      });

      testWidgets('…of what setup', (t) async {
        await show(
          t,
          OfWhatSetup(
              isPro: false, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
          await providerWith(),
          locale,
        );
      });

      testWidgets('custom setup', (t) async {
        await show(
          t,
          CustomModeSetup(
              initialKey: 'F♯', onCancel: () {}, onStart: (_, _, _, _, _) {}),
          await providerWith(),
          locale,
        );
      });

      testWidgets('pocket setup', (t) async {
        await show(
          t,
          PocketModeSetup(
              initialKey: 'D♭',
              isPro: true,
              onShowPaywall: () {},
              onCancel: () {},
              onStart: (_) {}),
          await providerWith(),
          locale,
        );
      });

      testWidgets('session summary', (t) async {
        final p = await providerWith(populated: true);
        await show(
          t,
          SessionSummaryScreen(
            sessionData: const {
              'key': 'C',
              'mode': 'diatonic',
              'accuracy': 100,
              'correct': 30,
              'total': 30,
              'time': 92,
              'difficulty': 1,
            },
            progressData: p.progressData,
            onRetry: () {},
            onBack: () {},
            onNextDifficulty: (_) {},
          ),
          p,
          locale,
        );
      });

      testWidgets('paywall', (t) async {
        await show(t, PaywallModal(onClose: () {}, onPurchase: () async {}),
            await providerWith(), locale);
      });
    });
  }
}
