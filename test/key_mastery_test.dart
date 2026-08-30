import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/constants/levels.dart';
import 'package:improvy/models/key_progress.dart';
import 'package:improvy/providers/app_provider.dart';

/// [KeyProgress.normalProgress] is the forward ladder — Degree to Note,
/// diatonic inside chromatic. These pin down the two containment rules it is
/// built on, and the anchors that fix its scale. The number on the tile is the
/// mean of this and its two siblings; see the group at the bottom.
KeyProgress k({List<int>? d, List<int>? c}) =>
    KeyProgress(key: 'C', diatonicLevels: d, chromaticLevels: c);

void main() {
  group('the anchors', () {
    test('a finished Diatonic is half the key', () {
      expect(k(d: [30, 40, 50]).normalProgress, 50);
    });

    test('and it stays half however scrappy the tiers below were', () {
      // Master is the same questions with less time, so a perfect Master says
      // everything the two tiers under it could have said.
      expect(k(d: [0, 0, 50]).normalProgress, 50);
      expect(k(d: [3, 11, 50]).normalProgress, 50);
    });

    test('a finished Chromatic is the whole key', () {
      // It contains the diatonic degrees, so there is nothing left to prove.
      expect(k(c: [30, 40, 50]).normalProgress, 100);
      expect(k(c: [0, 0, 50]).normalProgress, 100);
    });

    test('47/50 on chromatic Master, and nothing else, is 94%', () {
      // The case the old formula got wrong: it answered 19%.
      expect(k(c: [0, 0, 47]).normalProgress, 94);
    });
  });

  group('containment', () {
    test('chromatic evidence counts for the diatonic row at the same tier', () {
      // 24/30 chromatic Apprentice means at most 6 wrong out of 30 across all
      // twelve degrees, so the seven cannot be worse than that.
      final key = k(c: [24, 0, 0]);
      expect((key.diatonicReach * 100).round(), 27); // 0.8 over one tier of three
      expect(key.normalProgress, 27);
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
        final now = k(d: grid.sublist(0, 3), c: grid.sublist(3)).normalProgress;
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
      expect(key.normalProgress, 100);
    });
  });

  group('nothing and everything', () {
    test('an untouched key is zero', () => expect(k().normalProgress, 0));
    test('a full key is one hundred',
        () => expect(k(d: [30, 40, 50], c: [30, 40, 50]).normalProgress, 100));
    test('over-cap scores cannot push it past 100',
        () => expect(k(d: [99, 99, 99], c: [99, 99, 99]).normalProgress, 100));
  });

  group('the gate and the percentage read the same evidence', () {
    test('a key proved through Chromatic opens its Diatonic tiers', () {
      // Otherwise the app contradicts itself: 94% of the key, and Virtuoso
      // still padlocked because that ladder was never walked.
      final key = k(c: [0, 0, 47]);
      expect(key.normalProgress, 94);
      expect(AppProvider.highestUnlockedTier(key.effectiveDiatonic), 3);
    });

    test('but Diatonic never opens Chromatic', () {
      // The containment runs one way: the twelve are not inside the seven.
      final key = k(d: [30, 40, 50]);
      expect(AppProvider.highestUnlockedTier(key.effectiveChromatic), 1);
    });

    test('an unproved key opens on Apprentice only', () {
      expect(AppProvider.highestUnlockedTier(k().effectiveDiatonic), 1);
    });
  });

  _bestIsNeverInferred();
  _theThreeFamilies();
  _theTile();
  _theAnimalLadder();

  group('what the gate makes impossible', () {
    test('a tier can only hold a score if the one below is at 80%', () {
      // The saved score is the best ever reached and never falls, and a tier
      // will not open below 80% of the one under it. So a row like
      // [75%, 75%, 50%] cannot be reached: 75% of Apprentice is 22 or 23 of
      // 30, under the 24 needed, so Virtuoso was never playable.
      const apprenticeAt75 = 23; // of 30
      expect(apprenticeAt75, lessThan(kTierUnlock[1]));
      expect(AppProvider.highestUnlockedTier([apprenticeAt75, 0, 0]), 1,
          reason: 'Virtuoso must still be shut at 75%');
    });

    test('the lowest a row can sit once Master is open', () {
      // 80% of both tiers below, and Master not yet played.
      final key = k(c: [24, 32, 0]);
      expect(AppProvider.highestUnlockedTier(key.effectiveChromatic), 3);
      expect(key.normalProgress, 53);
    });
  });
}
/// BEST is a record, and a record is a run you ran. The closure credits you
/// for tiers you never played — it must never claim you scored in them.
void _bestIsNeverInferred() {
  test('the raw score stays raw however much the closure credits', () {
    final key = k(c: [24, 32, 47]);
    // Credited everywhere, because chromatic Master proves the rest.
    expect(key.effectiveDiatonic[0], 28); // 94% of 30
    // But nothing was ever scored in Diatonic, and the BEST line reads this.
    expect(key.diatonicLevels[0], 0);
    expect(key.diatonicProgress, 0);
  });
}

/// The three families share one rule, and the free half of each is exactly
/// half the score. That symmetry is the paywall's whole story, so it is worth
/// a test rather than a comment.
void _theThreeFamilies() {
  group('one ladder, three times', () {
    test('the core half is worth exactly half, in all three', () {
      // Degree→Note: the seven scale degrees, free in every key.
      expect(KeyProgress(key: 'C', diatonicLevels: [30, 40, 50]).normalProgress, 50);
      // Note→Degree: the same seven, asked backwards. Also free.
      expect(
          KeyProgress(key: 'C', ntnDiatonicLevels: [30, 40, 50])
              .noteToNumberProgress,
          50);
      // …Of What?: the six chord tones. Also free.
      expect(
          KeyProgress(key: 'C', harmonizerLevels: [30, 40, 50])
              .harmonizerProgress,
          50);
    });

    test('and the complete half takes each of them to a hundred', () {
      expect(KeyProgress(key: 'C', chromaticLevels: [30, 40, 50]).normalProgress, 100);
      expect(
          KeyProgress(key: 'C', ntnChromaticLevels: [30, 40, 50])
              .noteToNumberProgress,
          100);
      expect(
          KeyProgress(key: 'C', harmonizerAllLevels: [30, 40, 50])
              .harmonizerProgress,
          100);
    });

    test('the containment runs inward in all three, never outward', () {
      expect(
          KeyProgress(key: 'C', ntnDiatonicLevels: [30, 40, 50])
              .effectiveNtnChromatic,
          [0, 0, 0]);
      expect(
          KeyProgress(key: 'C', harmonizerLevels: [30, 40, 50])
              .effectiveHarmonizerAll,
          [0, 0, 0]);
    });

    test('a save from before the harmonizer split keeps its chord scores', () {
      final old = KeyProgress.fromJson({
        'key': 'C',
        'harmonizerLevels': [30, 40, 50],
      });
      expect(old.harmonizerLevels, [30, 40, 50]);
      expect(old.harmonizerAllLevels, [0, 0, 0]);
      // Those runs were chord-tone runs, and they still say what they said.
      expect(old.harmonizerProgress, 50);
    });
  });
}

/// The number on the tile: the three families, evenly, and the average of the
/// twelve tiles is what the animal reads.
void _theTile() {
  group('the number on the tile', () {
    test('the two directions are 40 each, the harmonizer 20', () {
      // Reading a degree and naming the note, and its mirror, are the everyday
      // work. Naming the key a note belongs to is rarer and more advanced.
      expect(k(d: [30, 40, 50], c: [30, 40, 50]).totalProgress, 40);
      expect(
          KeyProgress(key: 'C', ntnChromaticLevels: [30, 40, 50]).totalProgress,
          40);
      expect(
          KeyProgress(key: 'C', harmonizerAllLevels: [30, 40, 50])
              .totalProgress,
          20);
    });

    test('the weights sum to one, whatever they are set to', () {
      expect(
          KeyProgress.kNormalWeight +
              KeyProgress.kNoteToNumberWeight +
              KeyProgress.kHarmonizerWeight,
          closeTo(1.0, 1e-9));
    });

    test('the free half of all three is exactly half the key', () {
      // Diatonic, Note to Number diatonic and the chord tones are the three
      // free halves. Each family is half free, so ANY weighting of the three
      // lands here — the paywall's line does not depend on the weights.
      final free = KeyProgress(
        key: 'C',
        diatonicLevels: [30, 40, 50],
        ntnDiatonicLevels: [30, 40, 50],
        harmonizerLevels: [30, 40, 50],
      );
      expect(free.totalProgress, 50);
    });

    test('everything is a hundred', () {
      final all = KeyProgress(
        key: 'C',
        chromaticLevels: [30, 40, 50],
        ntnChromaticLevels: [30, 40, 50],
        harmonizerAllLevels: [30, 40, 50],
      );
      expect(all.totalProgress, 100);
    });

    test('no family can carry another', () {
      // Three separate skills over the same twelve notes. Fluency one way
      // says nothing about the other two, so nothing flows sideways.
      final forward = k(d: [30, 40, 50], c: [30, 40, 50]);
      expect(forward.noteToNumberProgress, 0);
      expect(forward.harmonizerProgress, 0);
    });
  });
}

/// The animal ladder is the app's only long-term reward, so where its rungs
/// sit is a product decision, not an accident of arithmetic.
void _theAnimalLadder() {
  group('the animal ladder', () {
    test('the first rung is close enough to reach in a sitting', () {
      // One key taken to 100% is 8.33% of the global figure, and the first
      // animal now sits at 2% — roughly two good sessions rather than fourteen.
      expect(kAnimalThresholds.first, lessThanOrEqualTo(3));
      expect(getAnimalLevel(0).level, 1);
      expect(getAnimalLevel(kAnimalThresholds.first).level, 2);
    });

    test('every rung is higher than the last, and the gaps widen', () {
      var previousGap = 0.0;
      for (var i = 0; i < kAnimalThresholds.length; i++) {
        final gap = kAnimalThresholds[i] - (i == 0 ? 0 : kAnimalThresholds[i - 1]);
        expect(gap, greaterThan(previousGap),
            reason: 'rung ${i + 2} is not harder to reach than the one below');
        previousGap = gap;
      }
    });

    test('there are exactly as many rungs as animals above the first', () {
      expect(kAnimalThresholds.length, kAnimalLevelCount - 1);
      expect(getAnimalLevel(100).level, kAnimalLevelCount);
    });

    test('free play stops two animals short of the top', () {
      // Every family is half free, so a free player caps at 50% however much
      // they grind — and the last two animals are the thing being sold.
      expect(getAnimalLevel(50).level, kAnimalLevelCount - 2);
    });
  });
}
