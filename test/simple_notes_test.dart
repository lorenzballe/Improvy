import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/services/voice_service.dart';
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

  test('Pocket Mode can say every simplified name out loud', () {
    // The setting promises one spelling per pitch *everywhere*, and Pocket
    // Mode is the one surface that also has to pronounce it: simplifying the
    // screen but leaving the voice on the key-correct name would have someone
    // reading "E" while hearing "F flat". Every one of the twelve has its own
    // recording, so the promise can actually be kept out loud.
    for (final name in kSimpleNoteNames) {
      final clip = VoiceService.noteClip(name);
      expect(clip, isNotNull, reason: '$name has no recording');
      final acc = name.substring(1).replaceAll('♭', 'b').replaceAll('♯', 's');
      expect(clip, 'n_${name[0]}$acc',
          reason: '$name would be spoken as $clip');
    }
  });

  test('simplifying never changes which pitch the answer is', () {
    // The one thing the setting must not do is make an answer wrong. Every
    // key-correct spelling the trainer can produce has to simplify to the same
    // pitch it already was — F♭ to E, E𝄫 to D, and never to something else.
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      for (final d in kChromaticDegreesSplit) {
        final proper = getNoteFromChromaticDegree(d, scale, key);
        final semitone = kNoteToSemitone[proper.split('/').first.trim()]!;
        final simple = simpleNoteName(semitone);
        expect(areEnharmonicEquivalent(proper, simple), isTrue,
            reason: '$d of $key is $proper but simplifies to $simple');
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
