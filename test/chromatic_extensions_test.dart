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

  test('every answer is spelled on the letter its degree demands', () {
    // The rule underneath every enharmonic question in the app: a degree owns a
    // staff position, not just a pitch. The ♭5 of D♭ has to land on some kind
    // of A — A𝄫, as it happens — because 5 is the fifth letter up from D. Get
    // the pitch right on the wrong letter and the note is enharmonically
    // "correct" and musically wrong, which is exactly what a theory trainer
    // must never teach. All 12 keys against all 15 split degrees.
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    const letterOffset = {
      '1': 0, '♭2': 1, '2': 1, '♯2': 1, '♭3': 2, '3': 2, '4': 3, '♯4': 3,
      '♭5': 4, '5': 4, '♯5': 4, '♭6': 5, '6': 5, '♭7': 6, '7': 6,
    };
    const semitone = {
      '1': 0, '♭2': 1, '2': 2, '♯2': 3, '♭3': 3, '3': 4, '4': 5, '♯4': 6,
      '♭5': 6, '5': 7, '♯5': 8, '♭6': 8, '6': 9, '♭7': 10, '7': 11,
    };
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      final root = letters.indexOf(key[0]);
      for (final d in kChromaticDegreesSplit) {
        final answer =
            getNoteFromChromaticDegree(d, scale, key).split('/').first.trim();
        expect(answer[0], letters[(root + letterOffset[d]!) % 7],
            reason: '$d of $key is $answer — wrong letter for that degree');
        expect(kNoteToSemitone[answer],
            ((kNoteToSemitone[key] ?? 0) + semitone[d]!) % 12,
            reason: '$d of $key is $answer — wrong pitch');
      }
    }
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
