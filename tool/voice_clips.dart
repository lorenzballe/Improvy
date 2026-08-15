// The single source of truth for Pocket Mode's recording script.
//
// Both tools in this folder read from here so the checklist, the file names
// and the split order can never drift apart.
import 'dart:io';
import 'dart:typed_data';

/// A clip: the file name stem, and the words to say into the microphone.
class Clip {
  const Clip(this.id, this.say);
  final String id;
  final String say;
  String get file => '$id.wav';

  /// Roughly how long this takes to say. Nothing here can hear the recording,
  /// so this is what tells a correct split from one that slid by a word: a
  /// take read in order has durations that track this, and a take with a word
  /// skipped does not. See `_alignment` in split_voice_take.
  ///
  /// Word count, not syllables — "flat two" carries a small pause between its
  /// two words that a two-syllable single word does not, and measuring the
  /// current recordings, word count predicts length far better (r = 0.90
  /// against 0.68) and so tells a good split from a bad one far more sharply.
  int get weight => say.split(' ').length;
}

/// Every degree Pocket Mode can present, in the order it is read for recording
/// (low to high, each natural preceded by its flat and followed by its sharp).
const degreeClips = <Clip>[
  Clip('d_1', 'one'),
  Clip('d_b2', 'flat two'),
  Clip('d_2', 'two'),
  Clip('d_s2', 'sharp two'),
  Clip('d_b3', 'flat three'),
  Clip('d_3', 'three'),
  Clip('d_4', 'four'),
  Clip('d_s4', 'sharp four'),
  Clip('d_b5', 'flat five'),
  Clip('d_5', 'five'),
  Clip('d_s5', 'sharp five'),
  Clip('d_b6', 'flat six'),
  Clip('d_6', 'six'),
  Clip('d_b7', 'flat seven'),
  Clip('d_7', 'seven'),
  Clip('d_b9', 'flat nine'),
  Clip('d_9', 'nine'),
  Clip('d_s9', 'sharp nine'),
  Clip('d_11', 'eleven'),
  Clip('d_s11', 'sharp eleven'),
  Clip('d_b13', 'flat thirteen'),
  Clip('d_13', 'thirteen'),
];

/// Answer notes the trainer can actually reach today, across all twelve keys.
/// E double flat is the flat two of D flat; B double flat is the flat two of
/// A flat and the flat six of D flat.
const noteClips = <Clip>[
  Clip('n_C', 'C'),
  Clip('n_Cb', 'C flat'),
  Clip('n_Cs', 'C sharp'),
  Clip('n_D', 'D'),
  Clip('n_Db', 'D flat'),
  Clip('n_Ds', 'D sharp'),
  Clip('n_E', 'E'),
  Clip('n_Eb', 'E flat'),
  Clip('n_Ebb', 'E double flat'),
  Clip('n_Es', 'E sharp'),
  Clip('n_F', 'F'),
  Clip('n_Fb', 'F flat'),
  Clip('n_Fs', 'F sharp'),
  Clip('n_G', 'G'),
  Clip('n_Gb', 'G flat'),
  Clip('n_Gs', 'G sharp'),
  Clip('n_A', 'A'),
  Clip('n_Ab', 'A flat'),
  Clip('n_As', 'A sharp'),
  Clip('n_B', 'B'),
  Clip('n_Bb', 'B flat'),
  Clip('n_Bbb', 'B double flat'),
  Clip('n_Bs', 'B sharp'),
];

/// The rest of the seven-letters-by-five-accidentals grid. Nothing asks for
/// these today; recording them while the microphone is already set up is the
/// only cheap moment to have them.
const spareClips = <Clip>[
  Clip('n_Cbb', 'C double flat'),
  Clip('n_Css', 'C double sharp'),
  Clip('n_Dbb', 'D double flat'),
  Clip('n_Dss', 'D double sharp'),
  Clip('n_Ess', 'E double sharp'),
  Clip('n_Fbb', 'F double flat'),
  Clip('n_Fss', 'F double sharp'),
  Clip('n_Gbb', 'G double flat'),
  Clip('n_Gss', 'G double sharp'),
  Clip('n_Abb', 'A double flat'),
  Clip('n_Ass', 'A double sharp'),
  Clip('n_Bss', 'B double sharp'),
];

/// Clips the app needs to never be silent: 45 files.
List<Clip> get required => [...degreeClips, ...noteClips];

/// Everything worth recording in one sitting: 57 files.
List<Clip> get everything => [...degreeClips, ...noteClips, ...spareClips];

/// Named groups, for `--list` and for the splitter's second argument.
final groups = <String, List<Clip>>{
  'degrees': degreeClips,
  'notes': noteClips,
  'spare': spareClips,
  'required': required,
  'all': everything,
};

const voiceDir = 'assets/audio/voice';

/// A parsed 16-bit PCM wav: the samples, and how fast to play them.
class Wav {
  Wav(this.samples, this.sampleRate, this.channels);
  final Int16List samples;
  final int sampleRate;
  final int channels;

  int get frames => samples.length ~/ channels;
  int get ms => (frames * 1000 / sampleRate).round();
}

/// Reads a RIFF/WAVE file. Returns null if it is not 16-bit PCM.
Wav? readWav(File f) {
  final b = f.readAsBytesSync();
  if (b.length < 12) return null;
  if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF') return null;
  if (String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') return null;
  final d = ByteData.sublistView(b);

  var rate = 0, channels = 0, bits = 0, format = 0;
  var pos = 12;
  while (pos + 8 <= b.length) {
    final id = String.fromCharCodes(b.sublist(pos, pos + 4));
    final size = d.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ' && body + 16 <= b.length) {
      format = d.getUint16(body, Endian.little);
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
      bits = d.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (rate == 0 || bits != 16 || (format != 1 && format != 0xFFFE)) {
        return null;
      }
      // The header can promise more than the file holds if a recorder was
      // killed mid-write; trust whichever is smaller.
      final len = size < b.length - body ? size : b.length - body;
      final pcm = Int16List(len ~/ 2);
      for (var i = 0; i < pcm.length; i++) {
        pcm[i] = d.getInt16(body + i * 2, Endian.little);
      }
      return Wav(pcm, rate, channels);
    }
    pos = body + size + (size.isOdd ? 1 : 0); // chunks are word-aligned
  }
  return null;
}

/// Writes mono 16-bit PCM.
void writeWav(File f, Int16List samples, int sampleRate) {
  final dataBytes = samples.length * 2;
  final out = ByteData(44 + dataBytes);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      out.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  out.setUint32(4, 36 + dataBytes, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little); // PCM
  out.setUint16(22, 1, Endian.little); // mono
  out.setUint32(24, sampleRate, Endian.little);
  out.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  out.setUint16(32, 2, Endian.little); // block align
  out.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  out.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    out.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  f.writeAsBytesSync(out.buffer.asUint8List());
}
