import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/models/key_progress.dart';

/// The percentage on a key is the number the whole app hangs on: it drives the
/// home tiles, the Skill Mastery list and the animal level. These pin down the
/// two containment rules it is built on, and the anchors that fix its scale.
KeyProgress k({List<int>? d, List<int>? c}) =>
    KeyProgress(key: 'C', diatonicLevels: d, chromaticLevels: c);

void main() {
  group('the anchors', () {
    test('a finished Diatonic is half the key', () {
      expect(k(d: [30, 40, 50]).totalProgress, 50);
    });

    test('and it stays half however scrappy the tiers below were', () {
      // Master is the same questions with less time, so a perfect Master says
      // everything the two tiers under it could have said.
      expect(k(d: [0, 0, 50]).totalProgress, 50);
      expect(k(d: [3, 11, 50]).totalProgress, 50);
    });

    test('a finished Chromatic is the whole key', () {
      // It contains the diatonic degrees, so there is nothing left to prove.
      expect(k(c: [30, 40, 50]).totalProgress, 100);
      expect(k(c: [0, 0, 50]).totalProgress, 100);
    });

    test('47/50 on chromatic Master, and nothing else, is 94%', () {
      // The case the old formula got wrong: it answered 19%.
      expect(k(c: [0, 0, 47]).totalProgress, 94);
    });
  });

  group('containment', () {
    test('chromatic evidence counts for the diatonic row at the same tier', () {
      // 24/30 chromatic Apprentice means at most 6 wrong out of 30 across all
      // twelve degrees, so the seven cannot be worse than that.
      final key = k(c: [24, 0, 0]);
      expect((key.diatonicReach * 100).round(), 27); // 0.8 over one tier of three
      expect(key.totalProgress, 27);
    });

    test('diatonic evidence says nothing about the altered degrees', () {
      // The containment runs one way only: the seven are inside the twelve,
      // the twelve are not inside the seven.
      expect(k(d: [30, 40, 50]).chromaticReach, 0);
    });

    test('a harder tier never counts for less than an easier one', () {
      // Monotone in both directions: adding any run can only raise the number.
      var previous = 0;
      for (final grid in [
        [0, 0, 0, 0, 0, 0],
        [20, 0, 0, 0, 0, 0],
        [30, 0, 0, 0, 0, 0],
        [30, 30, 0, 0, 0, 0],
        [30, 40, 0, 0, 0, 0],
        [30, 40, 50, 0, 0, 0],
        [30, 40, 50, 25, 0, 0],
        [30, 40, 50, 30, 40, 0],
        [30, 40, 50, 30, 40, 50],
      ]) {
        final now = k(d: grid.sublist(0, 3), c: grid.sublist(3)).totalProgress;
        expect(now, greaterThanOrEqualTo(previous), reason: 'went down at $grid');
        previous = now;
      }
      expect(previous, 100);
    });
  });

  group('the per-mode bars stay raw', () {
    test('a chromatic run does not fill the diatonic bar', () {
      // The headline percentage infers; a bar labelled DIATONIC must report.
      final key = k(c: [0, 0, 50]);
      expect(key.diatonicProgress, 0);
      expect(key.chromaticProgress, 42); // 50 of 120
      expect(key.totalProgress, 100);
    });
  });

  group('nothing and everything', () {
    test('an untouched key is zero', () => expect(k().totalProgress, 0));
    test('a full key is one hundred',
        () => expect(k(d: [30, 40, 50], c: [30, 40, 50]).totalProgress, 100));
    test('over-cap scores cannot push it past 100',
        () => expect(k(d: [99, 99, 99], c: [99, 99, 99]).totalProgress, 100));
  });
}
