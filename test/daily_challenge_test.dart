import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/utils/music_engine.dart';

/// The daily is the one run everybody plays against the same questions, so its
/// shape has to hold: same challenge from the same date on any device, every
/// question answerable, and a clock that stays tied to the question count.
void main() {
  test('the whole world gets the same challenge for a given day', () {
    final a = DailyChallenge.forDate(DateTime(2026, 8, 12));
    final b = DailyChallenge.forDate(DateTime(2026, 8, 12));
    expect(a.key, b.key);
    expect(a.degrees, b.degrees);
    // A different day must actually differ, or the seed is not doing its job.
    final other = DailyChallenge.forDate(DateTime(2026, 8, 13));
    expect(other.degrees, isNot(a.degrees));
  });

  test('every question has an answer on the chromatic board', () {
    // The real risk of moving the daily to chromatic degrees: the answer board
    // is built from the mode, so a degree the board cannot express would be
    // unanswerable. Checked across a month of challenges, every key.
    for (var day = 1; day <= 31; day++) {
      final c = DailyChallenge.forDate(DateTime(2026, 3, day));
      final scale = calculateMajorScale(c.key);
      final board = getChromaticButtons(scale, c.key)
          .map((b) => b.note)
          .toSet();
      for (final deg in c.degrees) {
        final answer = getNoteFromChromaticDegree(deg, scale, c.key);
        expect(
          board.any((n) => areEnharmonicEquivalent(n, answer)),
          isTrue,
          reason: 'day $day, key ${c.key}: degree $deg answers $answer, '
              'which is not on the board $board',
        );
      }
    }
  });

  test('every degree is asked once before any repeat', () {
    final c = DailyChallenge.forDate(DateTime(2026, 8, 12));
    expect(c.degrees.length, DailyChallenge.questionCount);
    final firstPass = c.degrees.take(kChromaticDegrees.length).toSet();
    expect(firstPass.length, kChromaticDegrees.length,
        reason: 'the opening run should cover every degree exactly once');
    expect(firstPass, containsAll(kChromaticDegrees));
  });

  test('no question repeats back to back', () {
    for (var day = 1; day <= 31; day++) {
      final c = DailyChallenge.forDate(DateTime(2026, 5, day));
      for (var i = 1; i < c.degrees.length; i++) {
        expect(c.degrees[i], isNot(c.degrees[i - 1]),
            reason: 'day $day repeated ${c.degrees[i]} back to back');
      }
    }
  });

  test('the clock follows the question count instead of drifting from it', () {
    expect(DailyChallenge.totalTimeMs,
        DailyChallenge.questionCount * DailyChallenge.msPerQuestion);
    expect(DailyChallenge.totalTimeMs, 42000);
    // The daily should be harder than an ordinary Virtuoso question (3.2s),
    // which is the whole point of tightening it.
    expect(DailyChallenge.msPerQuestion, lessThan(3200));
    // And the stated rule must match the clock actually used.
    expect(DailyChallenge.rule, '15 questions · 42 seconds');
  });

  test('starting it runs a chromatic session at the recorded difficulty', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();

    p.startDailyChallenge();

    // A diatonic session would build a seven-note board and leave the
    // chromatic questions unanswerable.
    expect(p.activeMode, TrainingMode.chromatic);
    expect(p.chromaticDifficulty, DailyChallenge.difficulty);
    expect(p.dailyChallengeActive, isTrue);
    expect(p.activeDailyDegrees?.length, DailyChallenge.questionCount);
  });
}
