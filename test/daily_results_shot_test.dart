@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/daily_results_screen.dart';

import 'screens_render_test.dart' as layout show loadRealFonts;
import 'store_screenshot_test.dart' as store show loadRealFonts;
import 'site_screens_test.dart' show seeded, frame;

/// The Daily Challenge result, at iPhone 16 Pro size, after a real run.
///
///   flutter test test/daily_results_shot_test.dart --run-skipped --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<AppProvider> played(List<bool> answers) async {
    final p = await seeded();
    final now = DateTime.now();
    // A run of dailies this month, so the calendar has a shape.
    for (var i = 1; i < 12; i++) {
      if (i == 5) continue;
      final d = now.subtract(Duration(days: i));
      p.dailyResults[day(d)] = DailyResult(
        dateKey: day(d), key: 'G', answers: [for (var q = 0; q < 10; q++) (q + i) % 6 != 2],
        timeMs: 24000, completed: true, timestamp: d.millisecondsSinceEpoch,
      );
    }
    p.startDailyChallenge();
    final degrees = p.activeDailyDegrees;
    for (var i = 0; i < degrees.length; i++) {
      final ok = i < answers.length ? answers[i] : true;
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
    return p;
  }

  for (final (name, answers) in [
    ('daily_result', [true, true, false, true, true, true, true, false, true, true]),
    ('daily_result_perfect', <bool>[]),
  ]) {
    testWidgets(name, (t) async {
      await layout.loadRealFonts();
      await store.loadRealFonts();
      final p = await played(answers);
      await frame(t, DailyResultsScreen(onDone: () {}), p);
      await expectLater(find.byType(DailyResultsScreen), matchesGoldenFile('goldens/$name.png'));
      if (answers.isNotEmpty) {
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
        await t.pumpAndSettle();
        await expectLater(find.byType(DailyResultsScreen),
            matchesGoldenFile('goldens/${name}_bottom.png'));
      }
    });
  }
}
