import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] for Pocket Mode.
///
/// On iOS it configures a *playback* audio session that is held open for the
/// whole session, so speech keeps going with the screen locked or the app
/// backgrounded (paired with the `audio` UIBackgroundMode in Info.plist).
/// Web and Android use their platform speech engines; deep-background
/// reliability there is best-effort.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// Warms up the engine (audio session + voice) ahead of the first utterance,
  /// so the opening question isn't clipped while the platform initialises.
  Future<void> warmUp() => _ensureReady();

  Future<void> _ensureReady() async {
    if (_ready) return;
    // The Pocket loop paces itself with estimated durations, so speak() should
    // fire and return immediately rather than block until the utterance ends
    // (that "ended" event is unreliable on some web/TTS engines).
    await _tts.awaitSpeakCompletion(false);
    if (!kIsWeb) {
      try {
        await _tts.setSharedInstance(true);
        // Keep the session ACTIVE between utterances. Pocket Mode is mostly
        // silence — the seconds you spend answering in your head — and iOS only
        // keeps a backgrounded app alive while its audio session stays active.
        // The plugin tears the session down after every utterance when the
        // category carries `duckOthers` (and whenever autoStop is on), which
        // suspended the app mid-loop and killed the voice with the screen off.
        await _tts.autoStopSharedSession(false);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            // NB: no duckOthers — it makes the plugin deactivate the session.
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      } catch (_) {
        // Non-iOS platforms (or older engines) simply skip session tuning.
      }
    }
    try {
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // iOS treats ~0.5 as a natural pace; other platforms are close enough.
      await _tts.setSpeechRate(kIsWeb ? 0.95 : 0.48);
    } catch (_) {}
    _ready = true;
  }

  /// Fires [text] to the speech engine. Returns as soon as the utterance is
  /// queued (not when it finishes) — the caller times the pace itself. Errors
  /// are swallowed so a single failed utterance never breaks the Pocket loop.
  Future<void> speak(String text) async {
    try {
      await _ensureReady();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
