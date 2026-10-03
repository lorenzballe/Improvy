import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:improvy/constants/levels.dart';
import 'package:improvy/constants/release_notes.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/daily_results_screen.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/screens/key_analytics_screen.dart';
import 'package:improvy/screens/legal_screen.dart';
import 'package:improvy/screens/onboarding_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/screens/stats_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/widgets/daily_challenge_card.dart';
import 'package:improvy/widgets/level_up_modal.dart';
import 'package:improvy/widgets/paywall_modal.dart';
import 'package:improvy/widgets/quiz_reveal_modal.dart';
import 'package:improvy/widgets/whats_new_modal.dart';
import 'package:improvy/l10n/l10n.dart';

import 'screens_render_test.dart' show loadRealFonts, providerWith;

/// Someone who has asked the OS for larger type gets a different app.
///
/// main.dart lets that request through up to 1.3x, and an overflow at that
/// size throws under `flutter test` — so the loud failures are already
/// covered. The quiet one is not: a line that fitted at 1.0x and is
/// ellipsised at 1.3x breaks no assertion anywhere. It just stops saying what
/// it said, and the reader who most needed the words is the one who loses
/// them.
///
/// So each screen is laid out twice, at 1.0x and at the 1.3x ceiling, and the
/// cut lines are compared. Text that is ellipsised at both sizes is a
/// deliberate design choice and is left alone; text that is only cut at 1.3x
/// is the regression this guards against.
///
/// The small phone is the point: 320x568 is where it appears first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  const small = Size(320, 568);

  /// Every line the layout gave up on, read off the render tree. A paragraph
  /// reports this itself once maxLines or the box has run out of room, which
  /// is the same moment the ellipsis appears on screen.
  Set<String> cutLines(WidgetTester t) {
    final out = <String>{};
    void walk(RenderObject o) {
      if (o is RenderParagraph && o.didExceedMaxLines) {
        out.add(o.text.toPlainText().trim());
      }
      o.visitChildren(walk);
    }

    walk(t.renderObject(find.byType(MaterialApp)));
    return out;
  }

  Future<Set<String>> layOut(
      WidgetTester t, Widget child, AppProvider provider, double scale) async {
    t.view.physicalSize = small;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MediaQuery(
        data: MediaQueryData(
          size: small,
          textScaler: TextScaler.linear(scale),
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
            scaffoldBackgroundColor: const Color(0xFF0F0A1A),
            useMaterial3: true,
            fontFamily: 'Lexend',
          ),
          home: child,
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 700));
    return cutLines(t);
  }

  /// A screen, and the provider state it needs to be worth looking at.
  final screens = <String, Future<(Widget, AppProvider)> Function()>{
    'home, empty': () async => (
          HomeScreen(
              onShowPaywall: ([_]) {},
              onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {},
              onStartDaily: () {}),
          await providerWith()
        ),
    'home, with history': () async => (
          HomeScreen(
              onShowPaywall: ([_]) {},
              onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {},
              onStartDaily: () {}),
          await providerWith(populated: true)
        ),
    'stats': () async =>
        (const StatsScreen(), await providerWith(populated: true)),
    'key analytics': () async => (
          KeyAnalyticsScreen(
              keyName: 'C', onBack: () {}, onShowPaywall: ([_]) {}),
          await providerWith(populated: true)
        ),
    'settings': () async => (
          SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}),
          await providerWith()
        ),
    'custom mode setup': () async => (
          CustomModeSetup(
              initialKey: 'F#', onCancel: () {}, onStart: (_, _, _, _, _) {}),
          await providerWith()
        ),
    'note to number setup': () async => (
          NoteToNumberSetup(
              initialKey: 'Bb',
              isPro: false,
              onShowPaywall: () {},
              onCancel: () {},
              onStart: (_, _, _, _) {}),
          await providerWith()
        ),
    'of what setup': () async => (
          OfWhatSetup(
              isPro: false,
              onShowPaywall: () {},
              onCancel: () {},
              onStart: (_, _, _, _) {}),
          await providerWith()
        ),
    'pocket mode setup': () async => (
          PocketModeSetup(
              initialKey: 'Db',
              isPro: true,
              onShowPaywall: () {},
              onCancel: () {},
              onStart: (_) {}),
          await providerWith()
        ),
    'trainer, chromatic': () async => (
          TrainerScreen(
            mode: TrainingMode.chromatic,
            selectedKey: 'F#',
            difficulty: 3,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'DoReMi',
            onExit: () {},
            onAnswer: (_, _, _) {},
            onFinish: (_) {},
          ),
          await providerWith()
        ),
    'trainer, note to number': () async => (
          TrainerScreen(
            mode: TrainingMode.noteToNumber,
            selectedKey: 'Db',
            difficulty: 1,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'CDE',
            onExit: () {},
            onAnswer: (_, _, _) {},
            onFinish: (_) {},
          ),
          await providerWith()
        ),
    'session summary': () async {
      final p = await providerWith(populated: true);
      return (
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
        p
      );
    },
    'daily results': () async {
      final p = await providerWith();
      p.startDailyChallenge();
      for (var i = 0; i < 4; i++) {
        p.recordAnswer(
          isCorrect: i.isEven,
          responseTime: 1400,
          answerDetails: AnswerRecord(
            degree: '5',
            note: 'G',
            selectedNote: 'G',
            tonality: p.todayChallenge.key,
            mode: 'diatonic',
            isReverse: false,
            difficulty: 2,
            responseTime: 1400,
            isCorrect: i.isEven,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
      p.finishSession();
      return (DailyResultsScreen(onDone: () {}), p);
    },
    'the daily card': () async => (
          Scaffold(body: Center(child: DailyChallengeCard(onStart: () {}))),
          await providerWith()
        ),
    'the widget reveal card': () async => (
          QuizRevealModal(
            question: 'sharp 11 of Ab',
            answer: 'D',
            musicalKey: 'Ab',
            onClose: () {},
            onTrainKey: () {},
          ),
          await providerWith()
        ),
    'onboarding': () async =>
        (OnboardingScreen(onComplete: () {}), await providerWith()),
    'level up, the longest animal name': () async => (
          LevelUpModal(animal: getAnimalLevel(100), onClose: () {}),
          await providerWith()
        ),
    'the paywall': () async => (
          PaywallModal(onClose: () {}, onPurchase: () async {}),
          await providerWith()
        ),
    'legal text': () async => (
          const LegalScreen(title: 'Privacy Policy', body: kPrivacyPolicyBody),
          await providerWith()
        ),
    'whats new': () async => (
          WhatsNewModal(
              release: kReleases.first, onDismiss: () {}, onRead: () {}),
          await providerWith()
        ),
  };

  group('larger type cuts nothing it did not already cut', () {
    screens.forEach((name, build) {
      testWidgets(name, (t) async {
        final (childAt1, providerAt1) = await build();
        final before = await layOut(t, childAt1, providerAt1, 1.0);
        expect(t.takeException(), isNull,
            reason: '$name does not lay out at 1.0x');

        // Rebuilt rather than re-pumped: a provider carries session state, and
        // a screen that has already animated once is not the same screen.
        final (childAt13, providerAt13) = await build();
        final after = await layOut(t, childAt13, providerAt13, 1.3);
        expect(t.takeException(), isNull,
            reason: '$name does not lay out at 1.3x');

        final newlyCut = after.difference(before);
        expect(
          newlyCut,
          isEmpty,
          reason: 'At 1.3x these lines are ellipsised on $name although they '
              'fitted at 1.0x, so the reader who asked for larger type is the '
              'one who stops being told: $newlyCut',
        );
      });
    });
  });
}
