// Cuts one long recording into the individual Pocket Mode clips.
//
// The clips are played back to back inside a single spoken question, so the
// thing that makes them sound right is not per-file polish — it is that they
// were all said into the same microphone, at the same distance, with the same
// voice, in the same minute. Recording one continuous take and slicing it here
// gets that for free; recording 57 separate files does not.
//
// Read the script (`dart tool/sync_voice_clips.dart --list`) into one take,
// leaving about a second of silence between words, then:
//
//   dart tool/split_voice_take.dart take.wav degrees --dry-run
//   dart tool/split_voice_take.dart take.wav degrees
//
// Groups: degrees (22), notes (23), spare (12), required (45), all (57).
// --dry-run first, always: it prints what each slice would be called and how
// long it is, so a bad cut is caught before it overwrites a good clip.
// ignore_for_file: avoid_print — this is a terminal tool; print is the output
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'voice_clips.dart';

/// Anything quieter than this counts as silence between words.
const _silenceDb = -42.0;

/// A gap must last this long to be a word boundary — shorter ones are the
/// pause inside "B  double  flat".
const _minGapMs = 450;

/// A slice this short is a breath or a click, not a word.
const _minWordMs = 120;

/// Kept either side of a word: enough not to clip a consonant, little enough
/// that the 110ms VoiceService gap still reads as one phrase.
const _padHeadMs = 30;
const _padTailMs = 70;

void main(List<String> args) {
  final flags = args.where((a) => a.startsWith('--')).toSet();
  final rest = args.where((a) => !a.startsWith('--')).toList();
  final dryRun = flags.contains('--dry-run');

  if (rest.length != 2 || !groups.containsKey(rest[1])) {
    stderr.writeln('usage: dart tool/split_voice_take.dart <take.wav> '
        '<${groups.keys.join('|')}> [--dry-run] [--force]');
    exit(2);
  }
  final take = File(rest[0]);
  if (!take.existsSync()) {
    stderr.writeln('no such file: ${rest[0]}');
    exit(2);
  }
  final expected = groups[rest[1]]!;

  final wav = readWav(take);
  if (wav == null) {
    stderr.writeln('${rest[0]} is not a 16-bit PCM wav — export it as one');
    exit(2);
  }
  if (wav.channels != 1) {
    print('note: take is ${wav.channels}-channel; slices are written mono '
        '(first channel only)');
  }

  final words = _findWords(wav);
  print('${rest[0]}: ${wav.ms}ms at ${wav.sampleRate}Hz — '
      'found ${words.length} words, expected ${expected.length}');

  if (words.length != expected.length) {
    stderr.writeln('\nThe count does not match, so nothing was written.');
    stderr.writeln('Usually one of two things:');
    stderr.writeln('  too many — a breath or a lip noise passed the gate, or '
        'a word was said twice');
    stderr.writeln('  too few  — two words ran together, or a word was '
        'skipped');
    _dump(words, expected, wav.sampleRate);
    exit(1);
  }

  final out = Directory(voiceDir);
  if (!out.existsSync()) {
    stderr.writeln('no $voiceDir — run this from the project root');
    exit(2);
  }
  if (!dryRun && !flags.contains('--force')) {
    final clash = expected
        .where((c) => File('$voiceDir/${c.file}').existsSync())
        .toList();
    if (clash.isNotEmpty) {
      stderr.writeln('\n${clash.length} of these already exist. Re-run with '
          '--force to replace them (git has the old ones).');
      exit(1);
    }
  }

  _dump(words, expected, wav.sampleRate);
  if (dryRun) {
    print('\n--dry-run: nothing written.');
    return;
  }

  final padHead = _padHeadMs * wav.sampleRate ~/ 1000;
  final padTail = _padTailMs * wav.sampleRate ~/ 1000;
  for (var i = 0; i < expected.length; i++) {
    final from = math.max(0, words[i].start - padHead);
    final to = math.min(wav.frames, words[i].end + padTail);
    final mono = Int16List(to - from);
    for (var j = 0; j < mono.length; j++) {
      mono[j] = wav.samples[(from + j) * wav.channels];
    }
    writeWav(File('$voiceDir/${expected[i].file}'), mono, wav.sampleRate);
  }
  print('\nwrote ${expected.length} clips to $voiceDir');
  print('now run: dart tool/sync_voice_clips.dart '
      '&& flutter test test/pocket_voice_test.dart');
}

void _dump(List<_Word> words, List<Clip> expected, int rate) {
  print('');
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final name = i < expected.length ? expected[i].file : '(extra)';
    final say = i < expected.length ? '"${expected[i].say}"' : '';
    final ms = ((w.end - w.start) * 1000 / rate).round();
    final at = (w.start * 1000 / rate / 1000).toStringAsFixed(1);
    final flag = ms < 200 ? '  <- very short' : '';
    print('${(i + 1).toString().padLeft(3)}. ${at.padLeft(6)}s  '
        '${ms.toString().padLeft(5)}ms  ${name.padRight(12)} $say$flag');
  }
  if (expected.length > words.length) {
    print('\nnot reached: '
        '${expected.sublist(words.length).map((c) => c.say).join(', ')}');
  }
}

class _Word {
  _Word(this.start, this.end);
  final int start; // in frames
  final int end;
}

/// Frame ranges that hold speech, found by RMS over 10ms windows.
List<_Word> _findWords(Wav wav) {
  const windowMs = 10;
  final win = wav.sampleRate * windowMs ~/ 1000;
  final gate = math.pow(10, _silenceDb / 20) * 32768;

  final loud = <bool>[];
  for (var f = 0; f + win <= wav.frames; f += win) {
    var sum = 0.0;
    for (var i = 0; i < win; i++) {
      final s = wav.samples[(f + i) * wav.channels].toDouble();
      sum += s * s;
    }
    loud.add(math.sqrt(sum / win) > gate);
  }

  final minGap = _minGapMs ~/ windowMs;
  final words = <_Word>[];
  var i = 0;
  while (i < loud.length) {
    if (!loud[i]) {
      i++;
      continue;
    }
    final start = i;
    var end = i;
    var quiet = 0;
    while (i < loud.length && quiet < minGap) {
      if (loud[i]) {
        end = i;
        quiet = 0;
      } else {
        quiet++;
      }
      i++;
    }
    final frames = (end + 1 - start) * win;
    if (frames * 1000 / wav.sampleRate >= _minWordMs) {
      words.add(_Word(start * win, (end + 1) * win));
    }
  }
  return words;
}
