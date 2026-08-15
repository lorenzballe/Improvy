// Keeps VoiceService's clip table honest against the .wav files on disk.
//
// Pocket Mode paces itself from `_ms` — it waits exactly as long as a clip
// lasts before saying the next word. Re-record a clip and that number is stale,
// so the voice either talks over itself or leaves a hole. This regenerates the
// table from the files, and reports which spellings are still missing.
//
//   dart tool/sync_voice_clips.dart            # rewrite the table
//   dart tool/sync_voice_clips.dart --check    # report only, touch nothing
//   dart tool/sync_voice_clips.dart --list     # print the recording script
//
// Runs on plain Dart — no Flutter, no packages.
// ignore_for_file: avoid_print — this is a terminal tool; print is the output
import 'dart:io';

import 'voice_clips.dart';

void main(List<String> args) {
  if (args.contains('--list')) {
    _printScript();
    return;
  }
  final check = args.contains('--check');

  final dir = Directory(voiceDir);
  if (!dir.existsSync()) {
    stderr.writeln('no $voiceDir — run this from the project root');
    exit(2);
  }

  final found = <String, int>{};
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.wav')) continue;
    final id = f.uri.pathSegments.last.replaceAll('.wav', '');
    final wav = readWav(f);
    if (wav == null) {
      stderr.writeln('! $id.wav is not 16-bit PCM wav — re-export it');
      exit(2);
    }
    found[id] = wav.ms;
  }

  final missing = required.where((c) => !found.containsKey(c.id)).toList();
  final missingSpare = spareClips.where((c) => !found.containsKey(c.id));
  final known = everything.map((c) => c.id).toSet();
  final extra = found.keys.where((k) => !known.contains(k)).toList()..sort();

  print('clips on disk: ${found.length}');
  print('required: ${required.length}'
      '${missing.isEmpty ? ' — all present' : ''}');
  if (missing.isNotEmpty) {
    print('  MISSING: ${missing.map((c) => c.file).join(', ')}');
  }
  if (missingSpare.isNotEmpty) {
    print('optional double accidentals not recorded: '
        '${missingSpare.map((c) => c.say).join(', ')}');
  }
  if (extra.isNotEmpty) print('unused files: ${extra.join(', ')}');

  // Clips this short are almost always a bad trim, not a short word.
  for (final e in found.entries) {
    if (e.value < 150) print('! ${e.key} is only ${e.value}ms — trimmed short?');
  }

  if (check) exit(missing.isEmpty ? 0 : 1);

  final src = File('lib/services/voice_service.dart');
  final text = src.readAsStringSync();
  const head = '  static const _ms = <String, int>{';
  final start = text.indexOf(head);
  if (start < 0) {
    stderr.writeln('could not find the _ms table in voice_service.dart');
    exit(2);
  }
  final end = text.indexOf('\n  };', start);
  final rewritten =
      text.replaceRange(start, end, '$head\n${_format(found)}'.trimRight());
  if (rewritten == text) {
    print('_ms already matches the files — nothing to write');
    return;
  }
  src.writeAsStringSync(rewritten);
  print('rewrote _ms with ${found.length} entries');
}

void _printScript() {
  final present = Directory(voiceDir).existsSync()
      ? Directory(voiceDir)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.wav', ''))
          .toSet()
      : <String>{};
  void section(String title, List<Clip> clips) {
    print('\n$title (${clips.length})');
    for (var i = 0; i < clips.length; i++) {
      final c = clips[i];
      final mark = present.contains(c.id) ? ' ' : '*';
      print('$mark ${(i + 1).toString().padLeft(2)}. '
          '${c.file.padRight(12)} "${c.say}"');
    }
  }

  section('DEGREES', degreeClips);
  section('NOTES — needed today', noteClips);
  section('NOTES — spare, nothing asks for these yet', spareClips);
  print('\n* = not on disk. Read each line, pause ~1s, keep going.');
}

/// The table as it is written in the source: sorted, wrapped near 78 columns.
String _format(Map<String, int> ms) {
  final keys = ms.keys.toList()..sort();
  final out = StringBuffer();
  var line = '   ';
  for (final k in keys) {
    final piece = " '$k': ${ms[k]},";
    if (line.length + piece.length > 78) {
      out.writeln(line);
      line = '   ';
    }
    line += piece;
  }
  if (line.trim().isNotEmpty) out.writeln(line);
  return out.toString();
}
