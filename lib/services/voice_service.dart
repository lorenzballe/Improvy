import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Speaks Pocket Mode with the app owner's own recorded voice.
///
/// Every degree and note is a short clip in `assets/audio/voice/`, played back
/// to back — "flat three" then the key, then the answer note. Clip lengths are
/// known ahead of time ([phraseMs]), so the session loop can pace itself
/// exactly instead of estimating how long a sentence takes to say.
///
/// A few spellings were never recorded. Rather than fall silent, they resolve
/// to their enharmonic twin ([_fallback]) — the same pitch, named the other
/// way. Drop the missing file into the folder, add it to [_ms], and the
/// fallback stops being used.
class VoiceService {
  final AudioPlayer _player = AudioPlayer(playerId: 'pocket_voice');
  bool _ready = false;
  int _gen = 0; // bumped by stop(), so a queued sequence abandons itself

  /// Exact length of each clip, in ms — generated from the .wav files.
  static const _ms = <String, int>{
    'd_1': 419, 'd_11': 574, 'd_13': 714, 'd_2': 374, 'd_3': 449, 'd_4': 414,
    'd_5': 519, 'd_6': 659, 'd_7': 574, 'd_9': 549, 'd_b13': 1006,
    'd_b2': 788, 'd_b3': 783, 'd_b6': 953, 'd_b7': 888, 'd_b9': 788,
    'd_s11': 893, 'd_s4': 878, 'd_s5': 873, 'd_s9': 913, 'n_A': 384,
    'n_Ab': 604, 'n_B': 374, 'n_Bb': 629, 'n_C': 484, 'n_Cs': 709, 'n_D': 384,
    'n_Db': 599, 'n_E': 344, 'n_Eb': 589, 'n_F': 409, 'n_Fb': 749,
    'n_Fs': 609, 'n_G': 414, 'n_Gb': 579, 'n_Gs': 624,
  };

  /// Spellings with no recording of their own → the clip that says the same
  /// pitch. ♭5 and ♯2 borrow the other name of the very same degree; the notes
  /// borrow their enharmonic equivalent.
  static const _fallback = <String, String>{
    'd_b5': 'd_s4', 'd_s2': 'd_b3',
    'n_As': 'n_Bb', 'n_Bs': 'n_C', 'n_Cb': 'n_B',
    'n_Ds': 'n_Eb', 'n_Es': 'n_F',
    'n_Bbb': 'n_A', 'n_Ebb': 'n_D',
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
