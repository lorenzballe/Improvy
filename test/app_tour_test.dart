@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/levels.dart';
import 'package:improvy/constants/release_notes.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/screens/free_mode_screen.dart';
import 'package:improvy/screens/key_analytics_screen.dart';
import 'package:improvy/screens/legal_screen.dart';
import 'package:improvy/screens/onboarding_screen.dart';
import 'package:improvy/screens/root_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/widgets/level_up_modal.dart';
import 'package:improvy/widgets/paywall_modal.dart';
import 'package:improvy/widgets/quiz_reveal_modal.dart';
import 'package:improvy/widgets/whats_new_modal.dart';

import 'screens_render_test.dart' as layout show loadRealFonts;
import 'store_screenshot_test.dart' as store show loadRealFonts;
import 'site_screens_test.dart' show seeded, frame, settle;

/// Every screen of the app at iPhone 16 Pro size with a believable player's
/// data, for reading the whole app side by side as one design. Long screens
/// are captured again scrolled.
///
///   flutter test test/app_tour_test.dart --run-skipped --update-goldens
///
/// The images land in test/tour/ (not committed).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await layout.loadRealFonts();
    await store.loadRealFonts();
  });

  Future<void> snap(WidgetTester t, String name) => expectLater(
      find.byType(MaterialApp), matchesGoldenFile('tour/$name.png'));

  /// The screen, then the screen scrolled by a page, then by two.
  Future<void> pages(WidgetTester t, String name, {int count = 3}) async {
    await snap(t, '${name}_1');
    for (var i = 2; i <= count; i++) {
      final s = find.byType(Scrollable);
      if (s.evaluate().isEmpty) return;
      await t.drag(s.first, const Offset(0, -640), warnIfMissed: false);
      await settle(t);
      await snap(t, '${name}_$i');
    }
  }

  testWidgets('home', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await pages(t, '01_home');
  });

  testWidgets('choose mode', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await t.tap(find.text('G').first);
    await settle(t);
    await pages(t, '02_choose_mode', count: 2);
  });

  testWidgets('stats', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await t.tap(find.text('Stats').last);
    await settle(t);
    await pages(t, '03_stats', count: 4);
  });

  testWidgets('settings', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await t.tap(find.text('Settings').last);
    await settle(t);
    await pages(t, '04_settings', count: 4);
  });

  testWidgets('key analytics', (t) async {
    await frame(t, KeyAnalyticsScreen(keyName: 'G', onBack: () {}, onShowPaywall: ([_]) {}),
        await seeded());
    await pages(t, '05_key_analytics', count: 3);
  });

  Widget trainer(TrainingMode mode, String key) => TrainerScreen(
        mode: mode,
        selectedKey: key,
        difficulty: 1,
        adaptiveDifficulty: false,
        sessionHistory: const [],
        notation: 'CDE',
        onExit: () {},
        onAnswer: (_, _, _) {},
        onFinish: (_) {},
      );

  for (final (name, mode) in [
    ('06_trainer_diatonic', TrainingMode.diatonic),
    ('07_trainer_chromatic', TrainingMode.chromatic),
    ('08_trainer_n2n', TrainingMode.noteToNumber),
  ]) {
    testWidgets(name, (t) async {
      await frame(t, trainer(mode, 'E♭'), await seeded());
      await snap(t, name);
    });
  }

  testWidgets('summary', (t) async {
    final p = await seeded();
    await frame(
        t,
        SessionSummaryScreen(
          sessionData: const {
            'key': 'G', 'mode': 'diatonic', 'accuracy': 87, 'correct': 26,
            'total': 30, 'time': 92, 'difficulty': 1,
          },
          progressData: p.progressData,
          onRetry: () {},
          onBack: () {},
          onNextDifficulty: (_) {},
        ),
        p);
    await pages(t, '09_summary', count: 2);
  });

  testWidgets('setups', (t) async {
    final p = await seeded();
    await frame(t, NoteToNumberSetup(initialKey: 'C', isPro: true, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}), p);
    await snap(t, '10_setup_n2n');
    await frame(t, OfWhatSetup(isPro: false, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}), p);
    await snap(t, '11_setup_ofwhat');
    await frame(t, PocketModeSetup(initialKey: 'C', isPro: true, onShowPaywall: () {}, onCancel: () {}, onStart: (_) {}), p);
    await snap(t, '12_setup_pocket');
    await frame(t, CustomModeSetup(initialKey: 'C', onCancel: () {}, onStart: (_, _, _, _, _) {}), p);
    await snap(t, '13_setup_custom');
  });

  // The modals sit over a page in the app; alone they have no Material.
  Widget over(Widget modal) => Scaffold(
        backgroundColor: const Color(0xFF0F0A1A),
        body: Stack(children: [Positioned.fill(child: modal)]),
      );

  testWidgets('modals', (t) async {
    final p = await seeded();
    p.setIsPro(false);
    await frame(t, over(PaywallModal(onClose: () {}, onPurchase: () async {})), p);
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await settle(t);
    await pages(t, '14_paywall', count: 2);
    await frame(t, over(LevelUpModal(animal: getAnimalLevel(40), onClose: () {})), p);
    await snap(t, '15_level_up');
    await frame(t, over(WhatsNewModal(release: kReleases.first, onDismiss: () {}, onRead: () {})), p);
    await snap(t, '16_whats_new');
    await frame(t, over(QuizRevealModal(question: '♭6 of E♭', answer: 'C♭', musicalKey: 'E♭', onClose: () {}, onTrainKey: () {})), p);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await snap(t, '17_quiz_reveal');
  });

  testWidgets('first run', (t) async {
    final p = await seeded();
    await frame(t, OnboardingScreen(onComplete: () {}), p);
    await snap(t, '18_onboarding');
    await frame(t, const FreeModeScreen(), p);
    await snap(t, '19_free_mode');
    await frame(t, const LegalScreen(title: 'Privacy Policy', body: kPrivacyPolicyBody), p);
    await snap(t, '20_legal');
  });
}
