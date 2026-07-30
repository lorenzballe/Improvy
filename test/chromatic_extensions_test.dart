import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/utils/music_engine.dart';

/// Chromatic mode must ask its degrees by the names a chart actually prints —
/// 9, 11, 13 and the altered ♭9/♯9/♯11/♭13 — not only by their base names.
/// Whatever name is used, the note to press is the same, and the stats must
/// still file the answer under the base degree.
void main() {
  test('every extension up to 13 is reachable in chromatic mode', () {
    final everyName = {
      for (final deg in kChromaticDegrees) ...chromaticDegreeNames(deg),
    };

    for (final ext in ['♭9', '9', '♯9', '11', '♯11', '♭13', '13']) {
      expect(everyName, contains(ext),
          reason: '$ext must be askable in chromatic mode');
    }
  });

  test('the names of each degree are exactly its spellings plus its extension',
      () {
    expect(chromaticDegreeNames('1'), ['1']);
    expect(chromaticDegreeNames('♭2'), ['♭2', '♭9']);
    expect(chromaticDegreeNames('2'), ['2', '9']);
    expect(chromaticDegreeNames('♭3/♯2'), ['♭3', '♯2', '♯9']);
    expect(chromaticDegreeNames('3'), ['3']);
    expect(chromaticDegreeNames('4'), ['4', '11']);
    expect(chromaticDegreeNames('♯4/♭5'), ['♯4', '♭5', '♯11']);
    expect(chromaticDegreeNames('5'), ['5']);
    expect(chromaticDegreeNames('♭6/♯5'), ['♭6', '♯5', '♭13']);
    expect(chromaticDegreeNames('6'), ['6', '13']);
    expect(chromaticDegreeNames('♭7'), ['♭7']);
    expect(chromaticDegreeNames('7'), ['7']);
  });

  test('an extension name resolves to the same note as its base degree', () {
    for (final key in kKeys) {
      final scale = calculateMajorScale(key);
      for (final entry in kChromaticExtensionOf.entries) {
        final base = getNoteFromChromaticDegree(entry.key, scale, key);
        final ext = getNoteFromChromaticDegree(entry.value, scale, key);
        expect(areEnharmonicEquivalent(base, ext), isTrue,
            reason: 'in $key, ${entry.value} must be the same note as '
                '${entry.key} (got $ext vs $base)');
      }
    }
  });

  test('an answer asked as an extension is still counted as its base degree',
      () {
    // What the stats screens do with a recorded degree.
    expect(romanDegree('9'), romanDegree('2'));
    expect(romanDegree('♭9'), romanDegree('♭2'));
    expect(romanDegree('♯9'), romanDegree('♯2'));
    expect(romanDegree('11'), romanDegree('4'));
    expect(romanDegree('♯11'), romanDegree('♯4'));
    expect(romanDegree('♭13'), romanDegree('♭6'));
    expect(romanDegree('13'), romanDegree('6'));

    // What the adaptive picker does with it.
    expect(normalizeExtension('13'), '6');
    expect(normalizeExtension('♯11'), '♯4');
  });

  test('diatonic mode stays 1–7, with no extension names', () {
    const diatonic = ['1', '2', '3', '4', '5', '6', '7'];
    for (final d in diatonic) {
      expect(kChromaticDegrees.contains(d) || d == '1', isTrue);
    }
    // The diatonic branch of the trainer asks `next` verbatim — these are the
    // only labels it can produce, and none of them is an extension.
    for (final d in diatonic) {
      expect(int.tryParse(d), isNotNull,
          reason: 'a diatonic question is a bare scale degree');
      expect(int.parse(d) <= 7, isTrue);
    }
  });
}
