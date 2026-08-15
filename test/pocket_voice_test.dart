import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/services/voice_service.dart';
import 'package:improvy/utils/music_engine.dart';

/// Pocket Mode is audio-only: a spelling with no clip is a question the user
/// simply never hears. These walk the whole vocabulary the mode can produce —
/// every degree name it may present, and every answer note across all 12 keys —
/// and check each one resolves to a clip that exists on disk.
void main() {
  // Pocket Mode's setup offers the 15 split degrees, so ♭3 and ♯2 can be
  // trained apart. That widens what the mode can reach: with the collapsed
  // list it only ever spelled 23 notes, and splitting takes it to 27.
  const pool = kChromaticDegreesSplit;

  /// The four spellings splitting the degrees reaches that have no recording,
  /// so the tests below assert what the mode actually asks rather than failing
  /// on questions it deliberately never puts. Pocket Mode redraws on these.
  ///
  ///   A𝄫  the ♭5 of D♭        C𝄪  the ♯2 of B and of F♯
  ///   F𝄪  the ♯2 of E and B   G𝄪  the ♯2 of F♯
  ///
  /// Record those four and this set empties out on its own.
  const unrecorded = {'A𝄫', 'C𝄪', 'F𝄪', 'G𝄪'};

  final files = Directory('assets/audio/voice')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last.replaceAll('.wav', ''))
      .toSet();

  test('every presented degree has a clip on disk', () {
    final missing = <String>[];
    for (final d in pool) {
      for (final name in chromaticDegreeNames(d)) {
        final clip = VoiceService.degreeClip(name);
        if (clip == null || !files.contains(clip)) missing.add(name);
      }
    }
    expect(missing, isEmpty, reason: 'degrees with no playable clip: $missing');
  });

  test('every answer note has a clip on disk, in all 12 keys', () {
    final missing = <String>{};
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      for (final d in pool) {
        final note = getNoteFromChromaticDegree(d, scale, key);
        for (final spelling in note.split('/').map((e) => e.trim())) {
          if (spelling.isEmpty || unrecorded.contains(spelling)) continue;
          final clip = VoiceService.noteClip(spelling);
          if (clip == null || !files.contains(clip)) missing.add('$spelling (in $key)');
        }
      }
    }
    expect(missing, isEmpty, reason: 'notes with no playable clip: $missing');
  });

  test('a note is never spoken under another note\'s name', () {
    // The rule the ♭5 bug broke, applied to notes. Splitting the degrees makes
    // the trainer reach C𝄪, F𝄪 and G𝄪, which the old fallback map turned into
    // "D", "G" and "A" — the screen showing one note while the voice says
    // another. Resolving to *a* clip is not enough; it has to be its own.
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      for (final d in pool) {
        final note = getNoteFromChromaticDegree(d, scale, key).split('/').first.trim();
        final clip = VoiceService.noteClip(note);
        if (clip == null) continue; // never asked — see _drawQuestion
        final acc = note.substring(1)
            .replaceAll('𝄫', 'bb').replaceAll('𝄪', 'ss')
            .replaceAll('♭', 'b').replaceAll('♯', 's');
        expect(clip, 'n_${note[0]}$acc',
            reason: '$d of $key is $note but would be spoken as $clip');
      }
    }
  });

  test('an unrecorded spelling is silent, never renamed', () {
    // Silence, so the mode redraws — or, once it is recorded, its own clip.
    // What it must never be is somebody else's: that is a question asked in a
    // name that is not the one on screen. Written to survive the recordings
    // arriving, so adding them turns this green rather than red.
    for (final spelling in unrecorded) {
      final acc = spelling.substring(1)
          .replaceAll('𝄫', 'bb').replaceAll('𝄪', 'ss')
          .replaceAll('♭', 'b').replaceAll('♯', 's');
      expect(VoiceService.noteClip(spelling), anyOf(isNull, 'n_${spelling[0]}$acc'),
          reason: '$spelling must be silent or its own clip, never a twin');
    }
  });

  test('every key can be named', () {
    for (final key in kAllKeys) {
      final clip = VoiceService.noteClip(key);
      expect(clip, isNotNull, reason: 'no clip for key $key');
      expect(files, contains(clip), reason: 'clip $clip missing for key $key');
    }
  });

  test('every presented degree is spoken as itself, never as its twin', () {
    // The one that bites: chromaticDegreeNames('♯4/♭5') yields ♯4, ♭5 AND ♯11,
    // and Pocket Mode picks one at random — so both halves of a slash degree
    // are real questions. Drop ♭5's clip and the fallback quietly makes the
    // screen read "♭5" while the voice says "sharp four". Checking the clip
    // merely *resolves* misses that; it has to be the degree's own.
    final borrowed = <String>[];
    for (final d in pool) {
      for (final name in chromaticDegreeNames(d)) {
        final own = 'd_${name.startsWith('♭') ? 'b' : name.startsWith('♯') ? 's' : ''}'
            '${name.replaceAll('♭', '').replaceAll('♯', '')}';
        if (VoiceService.degreeClip(name) != own || !files.contains(own)) {
          borrowed.add('$name -> ${VoiceService.degreeClip(name)}');
        }
      }
    }
    expect(borrowed, isEmpty,
        reason: 'degrees not spoken as themselves: ${borrowed.join(', ')}');
  });

  test('rarer note spellings are spoken as themselves, not as their twin', () {
    final notes = {'A♯': 'B♭', 'B♯': 'C', 'C♭': 'B', 'D♯': 'E♭', 'E♯': 'F', 'B𝄫': 'A', 'E𝄫': 'D'};
    notes.forEach((spelling, twin) {
      final clip = VoiceService.noteClip(spelling);
      expect(clip, isNotNull, reason: 'no clip for $spelling');
      expect(files, contains(clip), reason: 'clip $clip missing on disk');
      expect(clip, isNot(VoiceService.noteClip(twin)),
          reason: '$spelling still borrows $twin');
    });
  });

  test('a phrase is as long as its clips plus the gaps between them', () {
    final degree = VoiceService.degreeClip('♭3');
    final note = VoiceService.noteClip('C');
    expect(VoiceService.phraseMs([degree]), greaterThan(0));
    expect(
      VoiceService.phraseMs([degree, note]),
      VoiceService.phraseMs([degree]) + VoiceService.phraseMs([note]) + VoiceService.gapMs,
    );
    // A missing clip must not add silence to the pacing.
    expect(VoiceService.phraseMs([null]), 0);
  });

  test('every clip is as long as the service thinks it is', () {
    // The session loop waits exactly the stored length before moving on, so a
    // table that has drifted from the recordings does not throw — it talks over
    // itself or leaves dead air. Re-record a clip without regenerating the
    // table and this is what catches it.
    final wrong = <String>[];
    for (final id in files) {
      final actual = _wavMs(File('assets/audio/voice/$id.wav'));
      final stored = VoiceService.phraseMs([id]);
      // A whole millisecond of slack: the table is rounded, nothing more.
      if ((actual - stored).abs() > 1) {
        wrong.add('$id: file ${actual}ms, table ${stored}ms');
      }
    }
    expect(wrong, isEmpty, reason: 'clip lengths out of date:\n${wrong.join('\n')}');
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
