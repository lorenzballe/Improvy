@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/daily_results_screen.dart';
import 'package:improvy/screens/pocket_mode_screen.dart';
import 'package:improvy/screens/root_screen.dart';
import 'package:improvy/utils/music_engine.dart';
import 'package:improvy/widgets/tablet_fit.dart';

import 'screens_render_test.dart' as layout show loadRealFonts;
import 'store_screenshot_test.dart' as store show loadRealFonts;
import 'site_screens_test.dart'
    show seeded, frame, settle, play, trainer, noteAnswers, degreeAnswers;

/// The raw app screens behind the App Store and Google Play screenshots, from
/// the real widgets, on each device the stores ask for:
///
///   iphone — 6.9" iPhone, 440×956 points at 3× (1320×2868)
///   ipad   — 13" iPad, 1032×1376 points at 2× (2064×2752)
///
///     flutter test test/store_listing_test.dart --run-skipped --update-goldens
///     python3 tool/store_screenshots.py
///
/// The script sets each one under its headline at the exact store sizes, into
/// store_listing/. The raw renders land in test/store/ (not committed).
class _Device {
  final String name;
  final Size points;
  final double scale, top, bottom;
  const _Device(this.name, this.points, this.scale, this.top, this.bottom);
}

const _devices = [
  _Device('iphone', Size(440, 956), 3, 62, 34),
  _Device('ipad', Size(1032, 1376), 2, 24, 20),
];

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Today's Daily Challenge, played with two slips, on top of a month of them.
Future<AppProvider> _playedDaily() async {
  final p = await seeded();
  final now = DateTime.now();
  for (var i = 1; i < 12; i++) {
    if (i == 5) continue;
    final d = now.subtract(Duration(days: i));
    p.dailyResults[_day(d)] = DailyResult(
      dateKey: _day(d), key: 'G', answers: [for (var q = 0; q < 10; q++) (q + i) % 6 != 2],
      timeMs: 24000, completed: true, timestamp: d.millisecondsSinceEpoch,
    );
  }
  p.startDailyChallenge();
  final degrees = p.activeDailyDegrees;
  for (var i = 0; i < degrees.length; i++) {
    final ok = i != 3 && i != 9;
    p.recordAnswer(
      isCorrect: ok,
      responseTime: 1400 + i * 90,
      answerDetails: AnswerRecord(
        degree: degrees[i], note: 'E', selectedNote: ok ? 'E' : 'F',
        tonality: p.todayChallenge.key, mode: p.todayChallenge.mode.storageKey,
        isReverse: p.todayChallenge.mode == TrainingMode.noteToNumber,
        difficulty: DailyChallenge.difficulty, responseTime: 1400 + i * 90,
        isCorrect: ok, timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
  p.finishSession();
  // The run took real seconds; a test plays it in none.
  final c = p.todayChallenge;
  final r = p.dailyResults[c.dateKey]!;
  p.dailyResults = {
    ...p.dailyResults,
    c.dateKey: DailyResult(
      dateKey: r.dateKey, key: r.key, answers: r.answers, timeMs: 27400,
      completed: r.completed, timestamp: r.timestamp, mode: r.mode,
    ),
  };
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await layout.loadRealFonts();
    await store.loadRealFonts();
  });

  for (final d in _devices) {
    // As main.dart builds it: on a tablet the app fills the screen, scaled.
    Future<void> show(WidgetTester t, Widget home, AppProvider p) => frame(
        t, TabletFit(child: home), p,
        points: d.points, scale: d.scale, top: d.top, bottom: d.bottom);
    Future<void> snap(String name) =>
        expectLater(find.byType(MaterialApp), matchesGoldenFile('store/${d.name}_$name.png'));

    testWidgets('${d.name} chromatic', (t) async {
      await show(t, trainer(TrainingMode.chromatic, key: 'E♭'), await seeded());
      await play(t, n: 21, missAt: 13, isAnswer: (q, b) => noteAnswers(q, 'E♭', b),
          spelled: (q, b) => b.split('/').contains(
              getNoteFromChromaticDegree(q, calculateMajorScale('E♭'), 'E♭')));
      await snap('1_chromatic');
    });

    testWidgets('${d.name} home', (t) async {
      await show(t, const RootScreen(), await seeded());
      await snap('2_home');
    });

    testWidgets('${d.name} daily', (t) async {
      await show(t, DailyResultsScreen(onDone: () {}), await _playedDaily());
      await snap('3_daily');
    });

    testWidgets('${d.name} stats', (t) async {
      await show(t, const RootScreen(), await seeded());
      await t.tap(find.text('Stats').last);
      await settle(t);
      await snap('4_stats');
    });

    testWidgets('${d.name} note to number', (t) async {
      await show(t, trainer(TrainingMode.noteToNumber, key: 'D'), await seeded());
      await play(t, n: 19, missAt: 12, isAnswer: (q, b) => degreeAnswers(q, 'D', b),
          spelled: (q, b) => getNoteFromChromaticDegree(b, calculateMajorScale('D'), 'D') == q);
      await snap('6_n2n');
    });

    testWidgets('${d.name} pocket', (t) async {
      await show(
        t,
        PocketModeScreen(
          config: const PocketConfig(key: 'C', degrees: ['1', '2', '3', '4', '5', '6', '7'],
              delayMs: 5000, questions: 30, shuffleKeys: false),
          onExit: (_) {},
        ),
        await seeded(),
      );
      while (t.takeException() != null) {}
      for (var k = 0; k < 900; k++) {
        await t.pump(const Duration(milliseconds: 100));
        while (t.takeException() != null) {}
        final revealed = find.text('ANSWER').evaluate().isNotEmpty;
        final far = find.textContaining('/30').evaluate().any((e) {
          final v = int.tryParse(((e.widget as Text).data ?? '').split('/').first) ?? 0;
          return v >= 8;
        });
        if (revealed && far) break;
      }
      await t.pump(const Duration(milliseconds: 600));
      while (t.takeException() != null) {}
      await snap('5_pocket');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 30));
      while (t.takeException() != null) {}
    });
  }
}
