import 'dart:io';

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
