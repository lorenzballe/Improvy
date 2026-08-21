import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/services/voice_service.dart';
import 'package:improvy/utils/music_engine.dart';

/// "Simple note names" removes the spellings nobody writes — and only those.
///
/// F♭, C♭, E♯, B♯ and every double accidental go; the C♯ in A major stays C♯,
/// because it belongs to the key and reads perfectly well. The promise is easy
/// to break in both directions: a missed call site leaves B𝄫 on a key cap, and
/// an over-eager one renames notes that were never the problem.
void main() {
  test('only the awkward spellings are replaced', () {
    // Exactly the cases stated: the ones that go, and the ones that stay.
    expect(simplifySpelling('F♭'), 'E');
    expect(simplifySpelling('C♭'), 'B');
    expect(simplifySpelling('E♯'), 'F');
    expect(simplifySpelling('B♯'), 'C');
    expect(simplifySpelling('B𝄫'), 'A');
    expect(simplifySpelling('C𝄫'), 'B♭');
    expect(simplifySpelling('G𝄪'), 'A');

    // A spelling the key gives and a musician would write is left alone —
    // B♭ does not flip to A♯, and C♯ does not flip to D♭.
    for (final n in kPlainSpellings) {
      expect(simplifySpelling(n), n, reason: '$n should have been left alone');
    }
  });

  test('a note that belongs to the key keeps the key\'s own name', () {
    // The C♯ in A major is the third of the scale. Renaming it to D♭ would be
    // the setting doing harm rather than good.
    expect(chromaticKeyboardNoteNames('A', simpleNames: true)[1], 'C♯');
    expect(chromaticKeyboardNoteNames('E', simpleNames: true)[8], 'G♯');
    expect(chromaticKeyboardNoteNames('B♭', simpleNames: true)[10], 'B♭');
    // …while the awkward one in the same breath does change.
    expect(chromaticKeyboardNoteNames('E♭', simpleNames: true)[4], 'E');
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
        expect(kPlainSpellings, contains(l), reason: 'key $key: "$l" is off-list');
      }
      // Every pitch appears exactly once — no name is used twice.
      expect(labels.toSet().length, 12, reason: 'key $key repeated a name');
    }
  });

  test('every cap, in every key, is one of the seventeen', () {
    // A pitch may still read C♯ in one key and D♭ in another — both are names
    // a player writes, and the key decides which. What must never appear is a
    // double accidental or a white key wearing an accidental.
    for (var semitone = 0; semitone < 12; semitone++) {
      for (final key in kAllKeys) {
        final n = chromaticKeyboardNoteNames(key, simpleNames: true)[semitone]!;
        expect(kPlainSpellings, contains(n),
            reason: 'semitone $semitone in $key reads "$n"');
        expect(kNoteToSemitone[n], semitone,
            reason: '$n is not semitone $semitone');
      }
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
    for (final lang in VoiceLang.values) {
      for (final name in kPlainSpellings) {
        final clip = VoiceService.noteClip(name, lang);
        expect(clip, isNotNull, reason: '$name has no recording in ${lang.name}');
        final acc = name.substring(1).replaceAll('♭', 'b').replaceAll('♯', 's');
        expect(clip!.split('/').last, 'n_${name[0]}$acc',
            reason: '$name would be spoken as $clip');
      }
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
        final simple = simplifySpelling(proper);
        expect(areEnharmonicEquivalent(proper, simple), isTrue,
            reason: '$d of $key is $proper but simplifies to $simple');
        expect(kPlainSpellings, contains(simple),
            reason: '$d of $key simplifies to $simple, still not plain');
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
