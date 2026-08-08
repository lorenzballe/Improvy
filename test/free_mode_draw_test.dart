import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/screens/free_mode_screen.dart';

/// Free Mode shows one number at a time and never a slash pair, so the draw
/// has to split the enharmonic degrees without skewing which pitch comes up.
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

  test('every spelling drawn is a real single degree', () {
    // The 15 single spellings: the 9 unambiguous degrees plus both names of
    // each of the three enharmonic ones.
    final singles = <String>{
      ...kChromaticDegrees.where((d) => !d.contains('/')),
      ...kDegreeSplitMap.values.expand((v) => v),
    };
    final rng = math.Random(2);
    var base = '';
    for (var i = 0; i < 5000; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      expect(singles, contains(d.spelling));
    }
  });

  test('pitches come up evenly — enharmonics are not over-drawn', () {
    // The bug this guards: drawing uniformly from the 15 spellings would give
    // ♭3/♯2, ♯4/♭5 and ♭6/♯5 two tickets each, so those three pitches would
    // appear ~50% more often than the other nine.
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
      // Generous band: this is checking there is no structural 1.5x skew, not
      // that the RNG is perfectly flat.
      expect(
        (entry.value - expected).abs() / expected,
        lessThan(0.06),
        reason: '${entry.key} drawn ${entry.value}, expected ~${expected.round()}',
      );
    }
  });

  test('both spellings of an enharmonic pitch are used, evenly', () {
    final rng = math.Random(4);
    var base = '';
    final perSpelling = <String, int>{};
    for (var i = 0; i < 120000; i++) {
      final d = nextFreeDegree(rng, base);
      base = d.base;
      perSpelling[d.spelling] = (perSpelling[d.spelling] ?? 0) + 1;
    }
    for (final pair in kDegreeSplitMap.values) {
      final a = perSpelling[pair[0]] ?? 0;
      final b = perSpelling[pair[1]] ?? 0;
      expect(a, greaterThan(0));
      expect(b, greaterThan(0));
      expect((a - b).abs() / (a + b), lessThan(0.05), reason: '$pair split $a/$b');
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
