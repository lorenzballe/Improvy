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
  // Pocket Mode's setup only ever offers the 12 collapsed chromatic degrees.
  const pool = kChromaticDegrees;

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
          if (spelling.isEmpty) continue;
          final clip = VoiceService.noteClip(spelling);
          if (clip == null || !files.contains(clip)) missing.add('$spelling (in $key)');
        }
      }
    }
    expect(missing, isEmpty, reason: 'notes with no playable clip: $missing');
  });

  test('every key can be named', () {
    for (final key in kAllKeys) {
      final clip = VoiceService.noteClip(key);
      expect(clip, isNotNull, reason: 'no clip for key $key');
      expect(files, contains(clip), reason: 'clip $clip missing for key $key');
    }
  });

  test('rarer spellings are spoken as themselves, not as their twin', () {
    // These were the last gaps in the recordings; each now has its own clip, so
    // a ♯2 question is heard as "sharp two" and not as "flat three".
    final own = {
      '♭5': VoiceService.degreeClip('♯4'),
      '♯2': VoiceService.degreeClip('♭3'),
    };
    own.forEach((spelling, twin) {
      expect(VoiceService.degreeClip(spelling), isNot(twin),
          reason: '$spelling still borrows its enharmonic twin');
    });

    final notes = {'A♯': 'B♭', 'B♯': 'C', 'C♭': 'B', 'D♯': 'E♭', 'E♯': 'F', 'B𝄫': 'A', 'E𝄫': 'D'};
    notes.forEach((spelling, twin) {
      final clip = VoiceService.noteClip(spelling);
      expect(clip, isNotNull, reason: 'no clip for $spelling');
      expect(files, contains(clip), reason: 'clip $clip missing on disk');
      expect(clip, isNot(VoiceService.noteClip(twin)),
          reason: '$spelling still borrows $twin');
    });
  });

  test('the declared clip lengths match the files they describe', () {
    // Pocket Mode waits `_ms` before saying the next word, so a re-recorded
    // clip whose entry was not regenerated makes the voice talk over itself or
    // leave a hole. `dart tool/sync_voice_clips.dart` rewrites the table.
    final wrong = <String>[];
    for (final id in files) {
      final actual = _wavMs(File('assets/audio/voice/$id.wav'));
      final declared = VoiceService.phraseMs([id]);
      if (actual == null) {
        wrong.add('$id is not a readable wav');
      } else if ((actual - declared).abs() > 1) {
        wrong.add('$id: file is ${actual}ms, table says ${declared}ms');
      }
    }
    expect(wrong, isEmpty,
        reason: 'run: dart tool/sync_voice_clips.dart\n${wrong.join('\n')}');
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
}

/// Length of a RIFF/WAVE file in ms, or null if it is not one.
int? _wavMs(File f) {
  final b = f.readAsBytesSync();
  if (b.length < 12 || String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
    return null;
  }
  final d = ByteData.sublistView(b);
  var byteRate = 0;
  var pos = 12;
  while (pos + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(pos, pos + 4));
    final size = d.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ' && body + 16 <= b.length) {
      byteRate = d.getUint32(body + 8, Endian.little);
    } else if (id == 'data') {
      if (byteRate == 0) return null;
      final bytes = size < b.length - body ? size : b.length - body;
      return (bytes * 1000 / byteRate).round();
    }
    pos = body + size + (size.isOdd ? 1 : 0); // chunks are word-aligned
  }
  return null;
}
