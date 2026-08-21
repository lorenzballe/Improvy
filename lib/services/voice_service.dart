import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Which recording set speaks. Follows the app's note-naming setting: C-D-E is
/// read in English, Do-Re-Mi in Italian — the names on screen and the names in
/// your ear have to be the same words.
enum VoiceLang {
  en,
  it;

  /// 'CDE' | 'DoReMi', the value AppProvider.notation holds.
  static VoiceLang forNotation(String notation) =>
      notation == 'DoReMi' ? VoiceLang.it : VoiceLang.en;
}

/// Speaks Pocket Mode with recorded human voices.
///
/// Every degree and note is a short clip under `assets/audio/voice/<lang>/`,
/// played back to back — "flat three" then the key, then the answer note. Clip
/// lengths are known ahead of time ([phraseMs]), so the session loop can pace
/// itself exactly instead of estimating how long a sentence takes to say.
///
/// A clip id carries its language: `en/n_C`, `it/d_1`. That is what lets one
/// phrase mix folders when it has to — see [_resolve] — without the player or
/// the pacing needing to know anything about it.
class VoiceService {
  VoiceService(this.lang);

  final VoiceLang lang;
  final AudioPlayer _player = AudioPlayer(playerId: 'pocket_voice');
  bool _ready = false;
  int _gen = 0; // bumped by stop(), so a queued sequence abandons itself

  /// Exact length of each clip, in ms — generated from the .wav files. Wrong
  /// numbers here are not a rounding error: the session loop waits exactly this
  /// long before moving on, so a stale entry either talks over itself or leaves
  /// dead air. Regenerate whenever a clip is re-recorded.
  static const _ms = <String, int>{
    'en/d_1': 344, 'en/d_11': 503, 'en/d_13': 700, 'en/d_2': 312,
    'en/d_3': 455, 'en/d_4': 435, 'en/d_5': 482, 'en/d_6': 580, 'en/d_7': 502,
    'en/d_9': 460, 'en/d_b13': 1117, 'en/d_b2': 725, 'en/d_b3': 849,
    'en/d_b5': 692, 'en/d_b6': 858, 'en/d_b7': 744, 'en/d_b9': 784,
    'en/d_s11': 822, 'en/d_s2': 768, 'en/d_s4': 791, 'en/d_s5': 788,
    'en/d_s9': 808, 'en/n_A': 316, 'en/n_Ab': 496, 'en/n_Abb': 676,
    'en/n_As': 524, 'en/n_B': 290, 'en/n_Bb': 579, 'en/n_Bbb': 703,
    'en/n_Bs': 636, 'en/n_C': 441, 'en/n_Cb': 588, 'en/n_Cs': 633,
    'en/n_Css': 919, 'en/n_D': 431, 'en/n_Db': 554, 'en/n_Ds': 573,
    'en/n_E': 269, 'en/n_Eb': 487, 'en/n_Ebb': 701, 'en/n_Es': 473,
    'en/n_F': 398, 'en/n_Fb': 732, 'en/n_Fs': 637, 'en/n_Fss': 780,
    'en/n_G': 388, 'en/n_Gb': 616, 'en/n_Gs': 726, 'en/n_Gss': 959,
    'it/d_1': 372, 'it/d_11': 585, 'it/d_13': 594, 'it/d_2': 428,
    'it/d_3': 288, 'it/d_4': 516, 'it/d_5': 534, 'it/d_7': 560, 'it/d_9': 524,
    'it/d_b13': 986, 'it/d_b2': 793, 'it/d_b3': 680, 'it/d_b5': 951,
    'it/d_b6': 757, 'it/d_b7': 893, 'it/d_b9': 834, 'it/d_s11': 927,
    'it/d_s2': 803, 'it/d_s4': 885, 'it/d_s5': 864, 'it/d_s9': 843,
    'it/n_A': 289, 'it/n_Ab': 694, 'it/n_Abb': 932, 'it/n_As': 731,
    'it/n_B': 297, 'it/n_Bb': 733, 'it/n_Bbb': 931, 'it/n_Bs': 737,
    'it/n_C': 318, 'it/n_Cb': 586, 'it/n_Cs': 703, 'it/n_Css': 1011,
    'it/n_D': 259, 'it/n_Ds': 734, 'it/n_E': 283, 'it/n_Eb': 648,
    'it/n_Ebb': 938, 'it/n_Es': 782, 'it/n_F': 352, 'it/n_Fb': 726,
    'it/n_Fs': 732, 'it/n_Fss': 975, 'it/n_G': 448, 'it/n_Gb': 712,
    'it/n_Gs': 802, 'it/n_Gss': 1068,
  };

  /// Gap between two clips in one phrase — enough to hear them as separate
  /// words, short enough that "flat three · C" still reads as one question.
  static const gapMs = 110;

  /// Clip id for a degree as Pocket Mode presents it ('♭3', '♯11', '9', …).
  static String? degreeClip(String degree, VoiceLang lang) {
    final d = degree.split('/').first.trim();
    final acc = d.startsWith('♭') ? 'b' : d.startsWith('♯') ? 's' : '';
    return _resolve('d_$acc${d.replaceAll('♭', '').replaceAll('♯', '')}', lang);
  }

  /// Clip id for a note name ('E♭', 'C♯', 'B𝄫', …).
  static String? noteClip(String note, VoiceLang lang) {
    final n = note.split('/').first.trim();
    if (n.isEmpty) return null;
    final acc = n
        .substring(1)
        .replaceAll('𝄫', 'bb')
        .replaceAll('𝄪', 'ss')
        .replaceAll('♭', 'b')
        .replaceAll('♯', 's');
    return _resolve('n_${n[0]}$acc', lang);
  }

  /// Finds the clip, falling back across languages but never across names.
  ///
  /// The rule this must not break is the one the ♭5 bug taught: a clip may
  /// never stand in for a *different* spelling — the screen showing ♭5 while
  /// the voice says "sharp four" teaches the wrong name. Falling back to
  /// English is a different thing: same name, said in the other language. It
  /// is a blemish, not a lie, and it beats dropping a whole degree out of
  /// Italian training because one recording has not arrived. Every such gap is
  /// listed in VOICE_RECORDING.md and should end at zero.
  static String? _resolve(String base, VoiceLang lang) {
    final own = '${lang.name}/$base';
    if (_ms.containsKey(own)) return own;
    const fallback = 'en';
    if (lang.name != fallback && _ms.containsKey('$fallback/$base')) {
      assert(() {
        debugPrint('[VoiceService] "$base" not recorded in ${lang.name} — '
            'saying it in $fallback');
        return true;
      }());
      return '$fallback/$base';
    }
    assert(() {
      debugPrint('[VoiceService] no clip for "$base" — nothing will be spoken');
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

  /// Says the clips one after another, completing when the last one has had
  /// its full length to play.
  ///
  /// Await it. Callers used to fire this and run a parallel timer of
  /// [phraseMs], started from the call — but the audio only begins once the
  /// platform has loaded the clip, so the timer ran ahead of the sound by
  /// however long that took. Every clip shares one player, so the next phrase
  /// replaced the source and cut the previous one off mid-word.
  Future<void> say(List<String?> clips) async {
    if (kIsWeb) return;
    final real = clips.whereType<String>().toList();
    if (real.isEmpty) return;
    final gen = ++_gen;
    for (var i = 0; i < real.length; i++) {
      if (gen != _gen) return;
      // One retry. A refused play used to abandon the whole phrase in silence,
      // which on the answer is heard as the app simply not saying the note —
      // and a decoder that is briefly busy is exactly the kind of thing that
      // happens once in a long session rather than never.
      var started = false;
      for (var attempt = 0; attempt < 2 && !started; attempt++) {
        try {
          await _player.play(AssetSource('audio/voice/${real[i]}.wav'));
          started = true;
        } catch (_) {
          if (gen != _gen) return;
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      }
      if (!started) return;
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
