import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/utils/music_engine.dart';

/// "Simple note names" promises one spelling per pitch class, everywhere.
///
/// The promise is easy to break by accident: the normal spelling is computed
/// per key, so a single missed call site puts F♭ on a key cap in E♭ while the
/// button below it says E. These pin the promise down in every key.
void main() {
  test('the twelve names are the ones a player actually writes', () {
    expect(kSimpleNoteNames, [
      'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B',
    ]);
    // Flats everywhere except the tritone — that one is F♯, not G♭.
    expect(simpleNoteName(6), 'F♯');
  });

  test('buttons carry no slash and no double accidental, in every key', () {
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      final labels = getChromaticButtons(scale, key, simpleNames: true)
          .map((b) => b.label)
          .toList();
      expect(labels.length, 12);
      for (final l in labels) {
        expect(l.contains('/'), isFalse, reason: 'key $key: "$l" has a slash');
        expect(l.contains('𝄪') || l.contains('𝄫'), isFalse,
            reason: 'key $key: "$l" has a double accidental');
        expect(kSimpleNoteNames, contains(l), reason: 'key $key: "$l" is off-list');
      }
      // Every pitch appears exactly once — no name is used twice.
      expect(labels.toSet().length, 12, reason: 'key $key repeated a name');
    }
  });

  test('the same pitch reads the same in every key', () {
    // The point of the setting: a key cap does not change name when the
    // tonality changes. Without it, semitone 4 is E in C and F♭ in E♭.
    for (var semitone = 0; semitone < 12; semitone++) {
      final seen = <String>{};
      for (final key in kAllKeys) {
        seen.add(chromaticKeyboardNoteNames(key, simpleNames: true)[semitone]!);
      }
      expect(seen.length, 1,
          reason: 'semitone $semitone was spelled ${seen.toList()} across keys');
      expect(seen.single, simpleNoteName(semitone));
    }
  });

  test('keyboard caps carry no slash or double accidental either', () {
    for (final key in kAllKeys) {
      final names = chromaticKeyboardNoteNames(key, simpleNames: true);
      expect(names.length, 12);
      for (final n in names.values) {
        expect(n.contains('/'), isFalse);
        expect(n.contains('𝄪') || n.contains('𝄫'), isFalse);
      }
    }
  });

  test('answers are still matched by pitch, so nothing can be marked wrong', () {
    // Only the printed label changes. The value the trainer compares is
    // NoteItem.note, which must stay the generic name whatever the setting.
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      final plain = getChromaticButtons(scale, key);
      final simple = getChromaticButtons(scale, key, simpleNames: true);
      for (var i = 0; i < 12; i++) {
        expect(simple[i].note, plain[i].note,
            reason: 'key $key button $i changed its answer value');
      }
      // And the label really does name the same pitch it answers with.
      for (final b in simple) {
        expect(areEnharmonicEquivalent(b.label, b.note), isTrue,
            reason: 'key $key: label ${b.label} does not match note ${b.note}');
      }
    }
  });

  test('off by default, the old key-correct spelling is untouched', () {
    // E♭'s ♭2 is F♭ — the behaviour the setting exists to hide must survive
    // for everyone who leaves it off.
    expect(chromaticKeyboardNoteNames('E♭')[4], 'F♭');
    expect(getChromaticButtons(calculateMajorScale('C'), 'C')
        .any((b) => b.label.contains('/')), isTrue);
  });
}
