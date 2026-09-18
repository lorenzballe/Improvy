import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/training_mode.dart';

/// The daily now states how hard it is, and how hard tomorrow will be. A
/// rating is only worth showing if it varies and if it is honest, so this
/// checks both: that a year lands in all three bands, and that the things the
/// score claims to measure actually move it.
void main() {
  DailyChallenge dayOf(DailyDifficulty band) {
    var d = DateTime(2026, 1, 1);
    for (var i = 0; i < 400; i++) {
      final c = DailyChallenge.forDate(d.add(Duration(days: i)));
      if (c.rating == band) return c;
    }
    fail('no $band day in over a year');
  }

  test('a year uses all three bands, and none of them swallows it', () {
    final counts = <DailyDifficulty, int>{};
    final start = DateTime(2026, 1, 1);
    for (var i = 0; i < 365; i++) {
      final c = DailyChallenge.forDate(start.add(Duration(days: i)));
      counts[c.rating] = (counts[c.rating] ?? 0) + 1;
    }
    for (final band in DailyDifficulty.values) {
      final n = counts[band] ?? 0;
      expect(n, greaterThan(365 ~/ 10),
          reason: '$band is too rare to be worth a word: $counts');
      expect(n, lessThan((365 * 7) ~/ 10),
          reason: '$band swallows the year: $counts');
    }
  });

  test('each band is reachable and ordered by score', () {
    final light = dayOf(DailyDifficulty.light);
    final steady = dayOf(DailyDifficulty.steady);
    final tough = dayOf(DailyDifficulty.tough);
    expect(light.difficultyScore, lessThan(steady.difficultyScore));
    expect(steady.difficultyScore, lessThan(tough.difficultyScore));
  });

  test('the same date always rates the same, on any device', () {
    final a = DailyChallenge.forDate(DateTime(2026, 7, 14));
    final b = DailyChallenge.forDate(DateTime(2026, 7, 14, 23, 59));
    expect(a.rating, b.rating);
    expect(a.difficultyScore, b.difficultyScore);
  });

  test('the direction counts: same key, same questions, harder ask', () {
    const degrees = ['2', '3', '4', '5', '6', '7', '2', '3', '4', '5', '6', '7', '2', '3', '4'];
    int scoreFor(TrainingMode m) => DailyChallenge(
          dateKey: '2026-01-01',
          key: 'C',
          degrees: degrees,
          mode: m,
        ).difficultyScore;
    expect(scoreFor(TrainingMode.chromatic), lessThan(scoreFor(TrainingMode.noteToNumber)));
    expect(scoreFor(TrainingMode.noteToNumber), lessThan(scoreFor(TrainingMode.ofWhat)));
  });

  test('a remote key scores above C, and altered degrees above plain ones', () {
    const plain = ['2', '3', '4', '5', '6', '7', '2', '3', '4', '5', '6', '7', '2', '3', '4'];
    const sharp = ['♯2', '♭3', '♯4', '♭6', '♭7', '♯2', '♭3', '♯4', '♭6', '♭7', '♯2', '♭3', '♯4', '♭6', '♭7'];
    int score(String key, List<String> degrees) => DailyChallenge(
          dateKey: '2026-01-01',
          key: key,
          degrees: degrees,
        ).difficultyScore;
    expect(score('C', plain), lessThan(score('F♯', plain)));
    expect(score('C', plain), lessThan(score('C', sharp)));
  });

  test('every key the daily can draw has a signature size', () {
    for (final k in DailyChallenge.ofWhatNotes) {
      expect(DailyChallenge.keySignatureSize.containsKey(k), isTrue, reason: k);
    }
  });

  test("tomorrow is tomorrow's challenge, not a guess about it", () {
    final now = DateTime(2026, 3, 30, 22, 10);
    expect(DailyChallenge.tomorrow(now).dateKey, '2026-03-31');
    expect(
      DailyChallenge.tomorrow(now).degrees,
      DailyChallenge.forDate(DateTime(2026, 3, 31)).degrees,
    );
    // Across a month end, and across a year end.
    expect(DailyChallenge.tomorrow(DateTime(2026, 12, 31)).dateKey, '2027-01-01');
  });
}
