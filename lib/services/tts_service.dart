import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around [FlutterTts] for Pocket Mode.
///
/// On iOS it configures a *playback* audio session so speech keeps going with
/// the screen locked or the app backgrounded (paired with the `audio`
/// UIBackgroundMode in Info.plist). `duckOthers` lowers any music the user is
/// already playing instead of stopping it. Web and Android use their platform
/// speech engines; deep-background reliability there is best-effort.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    // speak() must resolve only when the utterance finishes, so the Pocket
    // loop can await it and time the pause that follows.
    await _tts.awaitSpeakCompletion(true);
    if (!kIsWeb) {
      try {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.duckOthers,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
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

  /// Speaks [text] and resolves when the utterance has finished. Errors are
  /// swallowed, and a hard timeout guarantees the caller is never left hanging
  /// if the engine never reports completion (e.g. a device with no voice), so
  /// the Pocket loop always keeps moving. 8s comfortably outlasts any of the
  /// short phrases Pocket Mode speaks.
  Future<void> speak(String text) async {
    try {
      await _ensureReady();
      await _tts.speak(text).timeout(const Duration(seconds: 8), onTimeout: () => null);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
