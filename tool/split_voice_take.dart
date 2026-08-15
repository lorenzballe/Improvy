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
  final ms = <int>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final name = i < expected.length ? expected[i].file : '(extra)';
    final say = i < expected.length ? '"${expected[i].say}"' : '';
    final len = ((w.end - w.start) * 1000 / rate).round();
    ms.add(len);
    final at = (w.start * 1000 / rate / 1000).toStringAsFixed(1);
    final flag = len < 200 ? '  <- very short' : '';
    print('${(i + 1).toString().padLeft(3)}. ${at.padLeft(6)}s  '
        '${len.toString().padLeft(5)}ms  ${name.padRight(12)} $say$flag');
  }
  if (expected.length > words.length) {
    print('\nnot reached: '
        '${expected.sublist(words.length).map((c) => c.say).join(', ')}');
    return;
  }
  _alignment(ms, expected);
}

/// Says whether the names actually landed on the right words.
///
/// A count that matches is not proof of a good split — say "flat two" as two
/// separate words and one extra boundary appears while a real gap elsewhere
/// closes, and every name after that point is on the wrong sound. Nothing here
/// can listen, but it can measure: in a take read in order, "B double flat"
/// is a longer recording than "B", so duration and word count move together.
/// Slide the names by one and that agreement inverts — on the current
/// recordings, correct scores 0.90 and off-by-one scores below zero.
void _alignment(List<int> ms, List<Clip> expected) {
  final weight = expected.map((c) => c.weight.toDouble()).toList();
  final len = ms.map((m) => m.toDouble()).toList();
  final r = _pearson(weight, len);
  print('\nalignment check: r = ${r.toStringAsFixed(2)}');
  if (r > 0.7) {
    print('  the names track the recording — the split reads as correct');
  } else if (r > 0.4) {
    print('  WEAK. Read the table above: bare letters ("C", "four") should be');
    print('  the shortest rows, "B double flat" among the longest.');
  } else {
    print('  BAD — the names are almost certainly on the wrong words.');
    print('  Most likely a word was skipped, doubled, or split in two.');
  }

  // Point at the individual rows that disagree most, which is usually where
  // the slip happened.
  final scale = len.reduce((a, b) => a + b) / weight.reduce((a, b) => a + b);
  final off = <String>[];
  for (var i = 0; i < ms.length; i++) {
    final want = weight[i] * scale;
    if ((len[i] - want).abs() > want * 0.55) {
      off.add('  ${i + 1}. "${expected[i].say}" is ${ms[i]}ms, '
          'expected around ${want.round()}ms');
    }
  }
  if (off.isNotEmpty) {
    print('\nrows that do not fit:\n${off.join('\n')}');
  }
}

double _pearson(List<double> a, List<double> b) {
  if (a.length < 3) return 1;
  final ma = a.reduce((x, y) => x + y) / a.length;
  final mb = b.reduce((x, y) => x + y) / b.length;
  var cov = 0.0, va = 0.0, vb = 0.0;
  for (var i = 0; i < a.length; i++) {
    cov += (a[i] - ma) * (b[i] - mb);
    va += (a[i] - ma) * (a[i] - ma);
    vb += (b[i] - mb) * (b[i] - mb);
  }
  if (va == 0 || vb == 0) return 0;
  return cov / math.sqrt(va * vb);
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
