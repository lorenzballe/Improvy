import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/constants/app_colors.dart';
import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/screens/free_mode_screen.dart';
import 'package:improvy/utils/music_engine.dart';

/// Free Mode shows one number at a time, named the way Chromatic mode names
/// what it asks — never a slash pair, and never skewing which pitch turns up.
void main() {
  test('never draws a slash spelling', () {
    final rng = math.Random(1);
    var base = '';
    for (var i = 0; i < 5000; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      expect(d.spelling.contains('/'), isFalse, reason: 'drew ${d.spelling}');
    }
  });

  test('only ever draws a name Chromatic mode would ask by', () {
    // The contract: Free Mode and the trainer name a degree from the same
    // list, so a name that shows up here must be one the trainer could ask.
    final legal = <String>{
      for (final d in kChromaticDegrees) ...chromaticDegreeNames(d),
    };
    final rng = math.Random(2);
    var base = '';
    for (var i = 0; i < 5000; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      expect(legal, contains(d.spelling));
    }
  });

  test('upper-structure names are in the pool, not just the spellings', () {
    // Guards the earlier bug: drawing only the enharmonic splits meant 9, ♯9,
    // 11, ♯11, 13, ♭13 and ♭9 could never appear, so Free Mode asked a
    // narrower set of names than Chromatic mode did.
    final rng = math.Random(9);
    var base = '';
    final seen = <String>{};
    for (var i = 0; i < 20000; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      seen.add(d.spelling);
    }
    for (final ext in ['♭9', '9', '♯9', '11', '♯11', '♭13', '13']) {
      expect(seen, contains(ext), reason: '$ext never drawn');
    }
  });

  test('every drawn name has a degree colour once normalised', () {
    // A name with no colour would render white and break the colour language
    // the rest of the app teaches.
    for (final d in kChromaticDegrees) {
      for (final name in chromaticDegreeNames(d)) {
        expect(
          AppColors.degreeColors[normalizeExtension(name)],
          isNotNull,
          reason: '$name (from $d) has no colour',
        );
      }
    }
  });

  test('pitches come up evenly — many-named ones are not over-drawn', () {
    // The bug this guards: drawing uniformly from the names would give the
    // three-name pitches (♭3/♯2 → ♭3, ♯2, ♯9) three tickets against one for
    // 1, 3, 5 and 7, so they would appear three times as often.
    const draws = 120000;
    final perBase = <String, int>{};
    final rng = math.Random(3);
    var base = '';
    for (var i = 0; i < draws; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      perBase[d.base] = (perBase[d.base] ?? 0) + 1;
    }

    expect(perBase.length, kChromaticDegrees.length);
    final expected = draws / kChromaticDegrees.length;
    for (final entry in perBase.entries) {
      // Generous band: this is checking there is no structural skew, not that
      // the RNG is perfectly flat.
      expect(
        (entry.value - expected).abs() / expected,
        lessThan(0.06),
        reason: '${entry.key} drawn ${entry.value}, expected ~${expected.round()}',
      );
    }
  });

  test('within a pitch, every one of its names gets an equal share', () {
    const draws = 240000;
    final rng = math.Random(4);
    var base = '';
    final perName = <String, int>{};
    for (var i = 0; i < draws; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      perName[d.spelling] = (perName[d.spelling] ?? 0) + 1;
    }
    for (final deg in kChromaticDegrees) {
      final names = chromaticDegreeNames(deg);
      if (names.length == 1) continue;
      final counts = names.map((n) => perName[n] ?? 0).toList();
      final total = counts.reduce((a, b) => a + b);
      final share = total / names.length;
      for (var i = 0; i < names.length; i++) {
        expect(
          (counts[i] - share).abs() / share,
          lessThan(0.06),
          reason: '$deg: ${names[i]} got ${counts[i]} of $total across $names',
        );
      }
    }
  });

  test('the same pitch never repeats back to back', () {
    final rng = math.Random(5);
    var base = '';
    for (var i = 0; i < 5000; i++) {
      final d = nextFreeDegree(rng, base);
      expect(d.base, isNot(base));
      base = d.base;
    }
  });
}
