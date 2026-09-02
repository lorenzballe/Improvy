// Generates the twelve answer tones Pocket-free modes play on a correct tap.
//
//   dart run tool/gen_tones.dart
//
// One file per pitch class, C4 to B4, 260 ms. A sine with a touch of second
// harmonic so it reads as a note rather than a beep, a 6 ms attack so it does
// not click, and a long release so it does not chop. Peak-normalised to the
// same 29162 the voice clips sit at, so the two never fight for level.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'voice_clips.dart' show writeWav;

const sampleRate = 44100;
const ms = 260;
const names = ['C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B'];

void main() {
  final dir = Directory('assets/audio/tones')..createSync(recursive: true);
  final n = sampleRate * ms ~/ 1000;
  for (var semi = 0; semi < 12; semi++) {
    // C4 = 261.63 Hz, equal temperament up from there.
    final hz = 261.6256 * math.pow(2, semi / 12);
    final out = Int16List(n);
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final attack = math.min(1.0, i / (sampleRate * 0.006));
      final release = math.exp(-t * 9);
      final env = attack * release;
      final v = math.sin(2 * math.pi * hz * t) * 0.85 +
          math.sin(2 * math.pi * hz * 2 * t) * 0.15;
      out[i] = (v * env * 29162).round().clamp(-32768, 32767);
    }
    writeWav(File('${dir.path}/${names[semi]}.wav'), out, sampleRate);
  }
  stdout.writeln('wrote 12 tones to ${dir.path}');
}
