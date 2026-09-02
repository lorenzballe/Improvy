import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/app_info.dart';
import 'package:improvy/constants/levels.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/daily_results_screen.dart';
import 'package:improvy/screens/free_mode_screen.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/screens/key_analytics_screen.dart';
import 'package:improvy/screens/legal_screen.dart';
import 'package:improvy/screens/onboarding_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/screens/stats_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/daily_challenge_card.dart';
import 'package:improvy/widgets/level_up_modal.dart';
import 'package:improvy/widgets/paywall_modal.dart';
import 'package:improvy/widgets/whats_new_modal.dart';
import 'package:improvy/constants/release_notes.dart';
import 'package:improvy/widgets/quiz_reveal_modal.dart';
import 'package:improvy/l10n/l10n.dart';

/// Does every screen actually lay out?
///
/// Release builds swallow layout errors, so a RenderFlex overflow ships
/// invisible and only shows as a clipped, yellow-striped widget on someone's
/// phone. Under `flutter test` the assertions are live: a screen that
/// overflows, throws, or divides by zero fails here.
///
/// The small viewport is the point — 320×568 is an iPhone SE, the tightest
/// screen the app has to survive, and the one every layout bug appears on
/// first.
const _small = Size(320, 568);
const _phone = Size(390, 844);

Future<AppProvider> providerWith({bool populated = false}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  if (populated) {
    // A handful of real games, some wrong, one timed out — enough for every
    // chart, average and confusion row to have something to draw.
    for (final key in ['C', 'G', 'B♭']) {
      p.selectKey(key);
      p.startMode(TrainingMode.diatonic, overrideKey: key);
      for (var i = 0; i < 8; i++) {
        final correct = i % 3 != 0;
        p.recordAnswer(
          isCorrect: correct,
          responseTime: 900 + i * 120,
          answerDetails: AnswerRecord(
            degree: '${(i % 7) + 1}',
            note: 'E',
            // An empty selection is how a timed-out question is recorded.
            selectedNote: i == 5 ? '' : (correct ? 'E' : 'F'),
            tonality: key,
            mode: 'diatonic',
            isReverse: false,
            difficulty: 1,
            responseTime: 900 + i * 120,
            isCorrect: correct,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
      p.finishSession();
      p.exitTrainer();
    }
  }
  return p;
}

extension on WidgetTester {
  /// Pumps [child] at [size] inside the app's real theme and provider.
  Future<void> show(Widget child, AppProvider provider, Size size) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
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
    );
    // Entrance animations run on real controllers; settle them without waiting
    // on the ones that repeat forever.
    await pump(const Duration(milliseconds: 700));
  }
}

/// Without this the test runner measures every glyph in its own uniform-width
/// stand-in font, and the widths it reports are fiction: real screens are
/// reported as overflowing and real overflows are hidden. Every face the app
/// actually ships has to be loaded for a layout test to mean anything.
Future<void> loadRealFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await family('Lexend', [
    'Lexend-Light.ttf', 'Lexend-Regular.ttf', 'Lexend-Medium.ttf',
    'Lexend-SemiBold.ttf', 'Lexend-Bold.ttf', 'Lexend-ExtraBold.ttf',
    'Lexend-Black.ttf',
  ]);
  await family('Outfit', [
    'Outfit-Light.ttf', 'Outfit-Regular.ttf', 'Outfit-Medium.ttf',
    'Outfit-SemiBold.ttf', 'Outfit-Bold.ttf',
  ]);
  await family('NotoMusic', ['NotoMusic-Regular.ttf']);
  await family('Bravura', ['Bravura.otf']);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  for (final size in [_small, _phone]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    group('$label · empty state', () {
      testWidgets('home', (t) async {
        await t.show(
          HomeScreen(onShowPaywall: ([_]) {}, onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {}, onStartDaily: () {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('stats', (t) async {
        await t.show(const StatsScreen(), await providerWith(), size);
      });

      testWidgets('settings', (t) async {
        await t.show(
          SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}),
          await providerWith(),
          size,
        );
        // Outward-facing rows people are told exist: the handle is published
        // on the row itself, so a wrong or vanished one is a visible promise
        // broken, not just a dead tap.
        expect(find.text('@$kInstagramHandle'), findsOneWidget);
        expect(find.text(kSupportEmail), findsOneWidget);
      });

      testWidgets('free mode — a tap advances the counter', (t) async {
        await t.show(const FreeModeScreen(), await providerWith(), size);
        // Nothing done yet, so LEFT and RUN both read 200.
        expect(find.text('200'), findsNWidgets(2));
        // The whole screen is the button: tapping the empty middle must count.
        await t.tapAt(Offset(size.width / 2, size.height / 2));
        await t.pump(const Duration(milliseconds: 400));
        // Asserted on LEFT, not on DONE: the degree on screen is drawn at
        // random and can itself be '1', '9', '11' … so matching those texts
        // would pass or fail depending on the draw. 199 cannot be a degree.
        expect(find.text('199'), findsOneWidget);
      });

      testWidgets('free mode — the bar uncovers the spectrum, never stretches it', (t) async {
        await t.show(const FreeModeScreen(), await providerWith(), size);
        for (var i = 0; i < 100; i++) {
          await t.tapAt(Offset(size.width / 2, size.height / 2));
          await t.pump(const Duration(milliseconds: 20));
        }
        await t.pump(const Duration(milliseconds: 400));

        final fill = find.byWidgetPredicate((w) {
          if (w is! Container) return false;
          final d = w.decoration;
          if (d is! BoxDecoration) return false;
          final g = d.gradient;
          return g is LinearGradient && g.colors.length == kFreeSpectrum.length &&
              g.colors.first == kFreeSpectrum.first;
        });
        expect(fill, findsOneWidget);

        // Half way through, the gradient must still be laid out across the
        // WHOLE track and simply be clipped — painting it into the filled part
        // instead would measure about half here, which is exactly the
        // squeezed-rainbow look this guards against. Compared against the
        // track itself rather than a hand-computed width, so padding and
        // borders can move without this becoming a false alarm.
        final track = find.byWidgetPredicate((w) =>
            w is Container && w.color == Colors.white.withValues(alpha: 0.08));
        expect(track, findsOneWidget);
        expect(t.getSize(fill).width, closeTo(t.getSize(track).width, 0.5));
      });

      testWidgets('free mode — the end of a run lays out', (t) async {
        await t.show(const FreeModeScreen(), await providerWith(), size);
        // Tap all the way through: the summary is a screen of its own and has
        // to survive the narrow phone like every other state here.
        for (var i = 0; i < 200; i++) {
          await t.tapAt(Offset(size.width / 2, size.height / 2));
          await t.pump(const Duration(milliseconds: 20));
        }
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text('0'), findsOneWidget); // LEFT
        expect(find.text('NUMBERS DONE'), findsOneWidget);
        expect(find.text('GO AGAIN'), findsOneWidget);
      });
    });

    group('$label · with history', () {
      testWidgets('home', (t) async {
        await t.show(
          HomeScreen(onShowPaywall: ([_]) {}, onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {}, onStartDaily: () {}),
          await providerWith(populated: true),
          size,
        );
      });

      testWidgets('stats', (t) async {
        await t.show(const StatsScreen(), await providerWith(populated: true), size);
      });

      testWidgets('key analytics', (t) async {
        final p = await providerWith(populated: true);
        await t.show(
          KeyAnalyticsScreen(keyName: 'C', onBack: () {}, onShowPaywall: ([_]) {}),
          p,
          size,
        );
      });
    });

    group('$label · in play', () {
      testWidgets('trainer, diatonic', (t) async {
        final p = await providerWith();
        await t.show(
          TrainerScreen(
            mode: TrainingMode.diatonic,
            selectedKey: 'C',
            difficulty: 1,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'CDE',
            onExit: () {},
            onAnswer: (_, __, ___) {},
            onFinish: (_) {},
          ),
          p,
          size,
        );
      });

      testWidgets('trainer, chromatic — the widest labels', (t) async {
        final p = await providerWith();
        await t.show(
          TrainerScreen(
            mode: TrainingMode.chromatic,
            selectedKey: 'F♯',
            difficulty: 3,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'DoReMi',
            onExit: () {},
            onAnswer: (_, __, ___) {},
            onFinish: (_) {},
          ),
          p,
          size,
        );
      });

      testWidgets('trainer, the Daily Challenge with its clock', (t) async {
        final p = await providerWith();
        p.startDailyChallenge();
        await t.show(
          TrainerScreen(
            mode: TrainingMode.diatonic,
            selectedKey: p.todayChallenge.key,
            difficulty: 2,
            numberOfQuestions: 10,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'CDE',
            questionSequence: p.activeDailyDegrees,
            isDaily: true,
            totalTimeMs: 40000,
            onExit: () {},
            onAnswer: (_, __, ___) {},
            onFinish: (_) {},
          ),
          p,
          size,
        );
      });

      testWidgets('trainer, note to number — fifteen answer buttons', (t) async {
        final p = await providerWith();
        await t.show(
          TrainerScreen(
            mode: TrainingMode.noteToNumber,
            selectedKey: 'D♭',
            difficulty: 1,
            adaptiveDifficulty: false,
            sessionHistory: const [],
            notation: 'CDE',
            onExit: () {},
            onAnswer: (_, __, ___) {},
            onFinish: (_) {},
          ),
          p,
          size,
        );
      });
    });

    group('$label · setup screens', () {
      testWidgets('custom mode', (t) async {
        await t.show(
          CustomModeSetup(initialKey: 'F♯', onCancel: () {}, onStart: (_, __, ___, ____, _____) {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('note to number', (t) async {
        await t.show(
          NoteToNumberSetup(initialKey: 'B♭', isPro: false, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('…Of What?, free — the locked extensions', (t) async {
        await t.show(
          OfWhatSetup(isPro: false, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('pocket mode, Pro — every degree unlocked', (t) async {
        await t.show(
          PocketModeSetup(
            initialKey: 'D♭', isPro: true, onShowPaywall: () {},
            onCancel: () {}, onStart: (_) {},
          ),
          await providerWith(),
          size,
        );
      });
    });

    group('$label · results and modals', () {
      testWidgets('session summary, a perfect run', (t) async {
        final p = await providerWith(populated: true);
        await t.show(
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
          size,
        );
      });

      testWidgets('daily results, out of time', (t) async {
        final p = await providerWith();
        p.startDailyChallenge();
        for (var i = 0; i < 4; i++) {
          p.recordAnswer(
            isCorrect: i.isEven,
            responseTime: 1400,
            answerDetails: AnswerRecord(
              degree: '5', note: 'G', selectedNote: 'G',
              tonality: p.todayChallenge.key, mode: 'diatonic',
              isReverse: false, difficulty: 2, responseTime: 1400,
              isCorrect: i.isEven,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
        p.finishSession();
        await t.show(DailyResultsScreen(onDone: () {}), p, size);
      });

      testWidgets('the daily card, before and after playing', (t) async {
        final p = await providerWith();
        await t.show(
          Scaffold(body: Center(child: DailyChallengeCard(onStart: () {}))),
          p,
          size,
        );
        p.startDailyChallenge();
        p.recordAnswer(
          isCorrect: true, responseTime: 1000,
          answerDetails: AnswerRecord(
            degree: '3', note: 'E', selectedNote: 'E',
            tonality: p.todayChallenge.key, mode: 'diatonic',
            isReverse: false, difficulty: 2, responseTime: 1000,
            isCorrect: true, timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        p.finishSession();
        await t.pump(const Duration(milliseconds: 400));
      });

      testWidgets('the widget reveal card', (t) async {
        await t.show(
          QuizRevealModal(
            question: '♯11 of A♭',
            answer: 'D',
            musicalKey: 'A♭',
            onClose: () {},
            onTrainKey: () {},
          ),
          await providerWith(),
          size,
        );
        // The answer lands on its own beat; make sure that state lays out too.
        await t.pump(const Duration(milliseconds: 1200));
      });

      testWidgets('onboarding', (t) async {
        await t.show(
          OnboardingScreen(onComplete: () {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('level up, the longest animal name', (t) async {
        await t.show(
          LevelUpModal(animal: getAnimalLevel(100), onClose: () {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('the paywall', (t) async {
        await t.show(
          PaywallModal(onClose: () {}, onPurchase: () async {}),
          await providerWith(),
          size,
        );
      });

      testWidgets('legal text', (t) async {
        await t.show(
          const LegalScreen(title: 'Privacy Policy', body: kPrivacyPolicyBody),
          await providerWith(),
          size,
        );
      });

      testWidgets("what's new, the current release", (t) async {
        await t.show(
          WhatsNewModal(
            release: kReleases.first,
            onDismiss: () {},
            onRead: () {},
          ),
          await providerWith(),
          size,
        );
      });
    });
  }
}
