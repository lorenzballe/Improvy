import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/services/voice_service.dart';
import 'package:improvy/utils/music_engine.dart';

/// Pocket Mode is audio-only: a spelling with no clip is a question the user
/// simply never hears. These walk the whole vocabulary the mode can produce —
/// every degree name it may present, and every answer note across all 12 keys —
/// in **both** recorded languages, and check each one can be spoken.
void main() {
  // Pocket Mode's setup offers the 15 split degrees, so ♭3 and ♯2 can be
  // trained apart. That widens what the mode can reach: with the collapsed
  // list it only ever spelled 23 notes, and splitting takes it to 27.
  const pool = kChromaticDegreesSplit;

  /// Clips the Italian voice does not have, and so borrows from English.
  ///
  /// Empty, and it must stay that way: every word Pocket Mode can say is
  /// recorded in both languages. While a name is in here an Italian session
  /// hears that one word in English — the test below fails the moment one
  /// appears, which is the only way anyone would notice.
  const italianGaps = <String>{};

  Set<String> filesIn(String lang) => Directory('assets/audio/voice/$lang')
      .listSync()
      .whereType<File>()
      .map((f) => '$lang/${f.uri.pathSegments.last.replaceAll('.wav', '')}')
      .toSet();

  final files = {
    for (final l in VoiceLang.values) l: filesIn(l.name),
  };
  final allFiles = files.values.expand((s) => s).toSet();

  for (final lang in VoiceLang.values) {
    final name = lang.name.toUpperCase();

    test('$name · every presented degree can be spoken', () {
      final missing = <String>[];
      for (final d in pool) {
        for (final n in chromaticDegreeNames(d)) {
          final clip = VoiceService.degreeClip(n, lang);
          if (clip == null || !allFiles.contains(clip)) missing.add(n);
        }
      }
      expect(missing, isEmpty, reason: 'degrees with no playable clip: $missing');
    });

    test('$name · every answer note can be spoken, in all 12 keys', () {
      final missing = <String>{};
      for (final key in kAllKeys) {
        final scale = calculateMajorScale(key);
        for (final d in pool) {
          final note = getNoteFromChromaticDegree(d, scale, key);
          for (final spelling in note.split('/').map((e) => e.trim())) {
            if (spelling.isEmpty) continue;
            final clip = VoiceService.noteClip(spelling, lang);
            if (clip == null || !allFiles.contains(clip)) {
              missing.add('$spelling (in $key)');
            }
          }
        }
      }
      expect(missing, isEmpty, reason: 'notes with no playable clip: $missing');
    });

    test('$name · the simplified spellings can be spoken too', () {
      // With "Simple Note Names" on, Pocket says what simplifySpelling gives,
      // not the key-correct spelling — a different set of words, and one the
      // rest of this file never looked at. A name with no clip there is a
      // question silently thrown away for everyone who has the setting on.
      final missing = <String>{};
      for (final key in kAllKeys) {
        final scale = calculateMajorScale(key);
        for (final d in pool) {
          final note = simplifySpelling(getNoteFromChromaticDegree(d, scale, key));
          for (final spelling in note.split('/').map((e) => e.trim())) {
            if (spelling.isEmpty) continue;
            final clip = VoiceService.noteClip(spelling, lang);
            if (clip == null || !allFiles.contains(clip)) {
              missing.add('$spelling (simple, in $key)');
            }
          }
        }
      }
      expect(missing, isEmpty, reason: 'notes with no playable clip: $missing');
    });

    test('$name · every key can be named', () {
      for (final key in kAllKeys) {
        final clip = VoiceService.noteClip(key, lang);
        expect(clip, isNotNull, reason: 'no clip for key $key');
        expect(allFiles, contains(clip), reason: 'clip $clip missing for $key');
      }
    });

    test('$name · nothing is ever spoken under another name', () {
      // The rule the ♭5 bug broke: a clip may stand in for another *language*,
      // never for another *name*. Whatever comes back, the part after the
      // language folder has to be this spelling's own id.
      String id(String s) => 'd_${s.startsWith('♭') ? 'b' : s.startsWith('♯') ? 's' : ''}'
          '${s.replaceAll('♭', '').replaceAll('♯', '')}';
      for (final d in pool) {
        for (final n in chromaticDegreeNames(d)) {
          final clip = VoiceService.degreeClip(n, lang)!;
          expect(clip.split('/').last, id(n),
              reason: '$n would be spoken as $clip');
        }
      }
      for (final key in kAllKeys) {
        final scale = calculateMajorScale(key);
        for (final d in pool) {
          final note = getNoteFromChromaticDegree(d, scale, key).split('/').first.trim();
          final acc = note.substring(1)
              .replaceAll('𝄫', 'bb').replaceAll('𝄪', 'ss')
              .replaceAll('♭', 'b').replaceAll('♯', 's');
          expect(VoiceService.noteClip(note, lang)!.split('/').last,
              'n_${note[0]}$acc',
              reason: '$d of $key is $note but would be spoken as something else');
        }
      }
    });

    test('$name · every clip is as long as the service thinks it is', () {
      // The session loop waits exactly the stored length before moving on, so a
      // table that has drifted from the recordings does not throw — it talks
      // over itself or leaves dead air.
      final wrong = <String>[];
      for (final id in files[lang]!) {
        final actual = _wavMs(File('assets/audio/voice/$id.wav'));
        final stored = VoiceService.phraseMs([id]);
        if ((actual - stored).abs() > 1) {
          wrong.add('$id: file ${actual}ms, table ${stored}ms');
        }
      }
      expect(wrong, isEmpty, reason: 'clip lengths out of date:\n${wrong.join('\n')}');
    });
  }

  test('the Italian voice speaks Italian wherever it has been recorded', () {
    // Guards the fallback from quietly widening: anything not in [italianGaps]
    // must come out of the Italian folder, and every gap must still be real.
    final borrowed = <String>{};
    for (final d in pool) {
      for (final n in chromaticDegreeNames(d)) {
        final clip = VoiceService.degreeClip(n, VoiceLang.it)!;
        if (!clip.startsWith('it/')) borrowed.add(clip.split('/').last);
      }
    }
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      for (final d in pool) {
        final spelled = getNoteFromChromaticDegree(d, scale, key);
        // Both spellings the mode can say: key-correct, and simplified for
        // anyone who has asked never to see a double accidental.
        for (final note in {spelled, simplifySpelling(spelled)}) {
          final clip = VoiceService.noteClip(note, VoiceLang.it)!;
          if (!clip.startsWith('it/')) borrowed.add(clip.split('/').last);
        }
      }
    }
    expect(borrowed, italianGaps,
        reason: 'Italian borrowing from English changed. Missing recordings: '
            '$borrowed, expected exactly $italianGaps');
  });

  test('the note-naming setting picks the voice', () {
    expect(VoiceLang.forNotation('CDE'), VoiceLang.en);
    expect(VoiceLang.forNotation('DoReMi'), VoiceLang.it);
  });

  test('a phrase is as long as its clips plus the gaps between them', () {
    final degree = VoiceService.degreeClip('♭3', VoiceLang.en);
    final note = VoiceService.noteClip('C', VoiceLang.en);
    expect(VoiceService.phraseMs([degree]), greaterThan(0));
    expect(
      VoiceService.phraseMs([degree, note]),
      VoiceService.phraseMs([degree]) + VoiceService.phraseMs([note]) + VoiceService.gapMs,
    );
    // A missing clip must not add silence to the pacing.
    expect(VoiceService.phraseMs([null]), 0);
  });
}

/// Duration of a PCM .wav, straight from its header — walks the RIFF chunks
/// rather than assuming a 44-byte one, since the recordings carry extra chunks.
int _wavMs(File f) {
  final b = f.readAsBytesSync();
  final d = ByteData.sublistView(b);
  var pos = 12; // past "RIFF"<size>"WAVE"
  int rate = 0, channels = 0, bits = 0, dataBytes = 0;
  while (pos + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(pos, pos + 4));
    final size = d.getUint32(pos + 4, Endian.little);
    if (id == 'fmt ') {
      channels = d.getUint16(pos + 10, Endian.little);
      rate = d.getUint32(pos + 12, Endian.little);
      bits = d.getUint16(pos + 22, Endian.little);
    } else if (id == 'data') {
      dataBytes = size;
      break;
    }
    pos += 8 + size + (size.isOdd ? 1 : 0); // chunks are word-aligned
  }
  final frames = dataBytes ~/ (channels * (bits ~/ 8));
  return (frames * 1000 / rate).round();
}
