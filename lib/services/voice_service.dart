import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Speaks Pocket Mode with the app owner's own recorded voice.
///
/// Every degree and note is a short clip in `assets/audio/voice/`, played back
/// to back — "flat three" then the key, then the answer note. Clip lengths are
/// known ahead of time ([phraseMs]), so the session loop can pace itself
/// exactly instead of estimating how long a sentence takes to say.
///
/// Every spelling the mode can present is recorded, double flats included, so
/// a question is always heard in the spelling it was asked in. [_fallback] only
/// covers spellings the trainer could grow into later.
class VoiceService {
  final AudioPlayer _player = AudioPlayer(playerId: 'pocket_voice');
  bool _ready = false;
  int _gen = 0; // bumped by stop(), so a queued sequence abandons itself

  /// Exact length of each clip, in ms — generated from the .wav files. Wrong
  /// numbers here are not a rounding error: the session loop waits exactly this
  /// long before moving on, so a stale entry either talks over itself or leaves
  /// dead air. Regenerate whenever a clip is re-recorded.
  static const _ms = <String, int>{
    'd_1': 344, 'd_2': 312, 'd_3': 455, 'd_4': 435, 'd_5': 482, 'd_6': 580,
    'd_7': 502, 'd_9': 460, 'd_11': 503, 'd_13': 700, 'd_b2': 725,
    'd_b3': 849, 'd_b5': 692, 'd_b6': 858, 'd_b7': 744, 'd_b9': 784,
    'd_s2': 768, 'd_s4': 791,
    'd_s5': 788, 'd_s9': 808, 'd_b13': 1117, 'd_s11': 822, 'n_A': 384,
    'n_Ab': 604, 'n_As': 793, 'n_B': 374, 'n_Bb': 629, 'n_Bbb': 958,
    'n_Bs': 759, 'n_C': 484, 'n_Cb': 744, 'n_Cs': 709, 'n_D': 384,
    'n_Db': 599, 'n_Ds': 734, 'n_E': 344, 'n_Eb': 589, 'n_Ebb': 963,
    'n_Es': 813, 'n_F': 409, 'n_Fb': 749, 'n_Fs': 609, 'n_G': 414,
    'n_Gb': 579, 'n_Gs': 624,
  };

  /// Every spelling Pocket Mode can say is recorded, so nothing falls back to
  /// an enharmonic twin. Kept as the safety net for a spelling added to the
  /// trainer before its clip is: same pitch, named the other way, rather than
  /// a silent question.
  ///
  /// Note that both halves of a slash degree are real questions here:
  /// `chromaticDegreeNames('♯4/♭5')` yields ♯4, ♭5 *and* ♯11, and Pocket Mode
  /// picks one at random. So ♭5 and ♯2 need their own clips — dropping them and
  /// leaning on this map would show "♭5" while saying "sharp four".
  static const _fallback = <String, String>{
    'n_Cbb': 'n_Bb', 'n_Fbb': 'n_Eb', 'n_Ass': 'n_B', 'n_Css': 'n_D',
    'n_Dss': 'n_E', 'n_Fss': 'n_G', 'n_Gss': 'n_A',
  };

  /// Gap between two clips in one phrase — enough to hear them as separate
  /// words, short enough that "flat three · C" still reads as one question.
  static const gapMs = 110;

  /// Clip id for a degree as Pocket Mode presents it ('♭3', '♯11', '9', …).
  static String? degreeClip(String degree) {
    final d = degree.split('/').first.trim();
    final acc = d.startsWith('♭') ? 'b' : d.startsWith('♯') ? 's' : '';
    final id = 'd_$acc${d.replaceAll('♭', '').replaceAll('♯', '')}';
    return _resolve(id);
  }

  /// Clip id for a note name ('E♭', 'C♯', 'B𝄫', …).
  static String? noteClip(String note) {
    final n = note.split('/').first.trim();
    if (n.isEmpty) return null;
    final acc = n
        .substring(1)
        .replaceAll('𝄫', 'bb')
        .replaceAll('𝄪', 'ss')
        .replaceAll('♭', 'b')
        .replaceAll('♯', 's');
    return _resolve('n_${n[0]}$acc');
  }

  static String? _resolve(String id) {
    if (_ms.containsKey(id)) return id;
    final alt = _fallback[id];
    if (alt != null && _ms.containsKey(alt)) return alt;
    assert(() {
      debugPrint('[VoiceService] no clip for "$id" — nothing will be spoken');
      return true;
    }());
    return null;
  }

  /// How long [clips] take to speak, including the gaps between them.
  static int phraseMs(List<String?> clips) {
    final real = clips.whereType<String>().toList();
    if (real.isEmpty) return 0;
    return real.fold(0, (a, c) => a + (_ms[c] ?? 0)) + gapMs * (real.length - 1);
  }

  Future<void> warmUp() async {
    if (_ready || kIsWeb) return;
    try {
      // Loading the player once up front keeps the first question from being
      // late by however long the platform takes to spin a decoder up.
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      _ready = true;
    } catch (_) {}
  }

  /// Says the clips one after another. Returns immediately — the caller paces
  /// itself with [phraseMs], the same way it did with the speech engine.
  Future<void> say(List<String?> clips) async {
    if (kIsWeb) return;
    final real = clips.whereType<String>().toList();
    if (real.isEmpty) return;
    final gen = ++_gen;
    for (var i = 0; i < real.length; i++) {
      if (gen != _gen) return;
      try {
        await _player.play(AssetSource('audio/voice/${real[i]}.wav'));
      } catch (_) {
        return;
      }
      final last = i == real.length - 1;
      await Future<void>.delayed(
          Duration(milliseconds: (_ms[real[i]] ?? 0) + (last ? 0 : gapMs)));
    }
  }

  Future<void> stop() async {
    _gen++;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _gen++;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
