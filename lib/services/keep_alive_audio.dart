import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Keeps a backgrounded Pocket Mode session alive on iOS.
///
/// `UIBackgroundModes: audio` does not mean "keep my app running". It means
/// iOS won't suspend the app *while audio is actually flowing to the output*.
/// An audio session that is merely active, with nothing playing, is not enough:
/// the app gets suspended, every Dart timer stops, and the loop freezes.
///
/// Pocket Mode is mostly silence — the seconds you spend working the answer out
/// in your head — so it was being suspended in exactly those gaps, right after
/// the first question. This plays an inaudible track on repeat for the whole
/// session, so the output pipeline never goes idle and the loop keeps its
/// timing with the screen locked. Speech mixes in on top of it.
class KeepAliveAudio {
  final AudioPlayer _player = AudioPlayer(playerId: 'pocket_keepalive');
  StreamSubscription<PlayerState>? _watch;
  bool _running = false;
  bool _configured = false;
  bool _restarting = false;

  Future<void> start() async {
    // Web tabs get throttled by the browser, not by an audio session — the
    // trick doesn't apply there and would only cost an extra decoder.
    if (kIsWeb || _running) return;
    _running = true;
    try {
      if (!_configured) {
        // Match the category flutter_tts sets, so neither one downgrades the
        // shared session to something that can't play in the background.
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.allowBluetooth,
                AVAudioSessionOptions.allowBluetoothA2DP,
              },
            ),
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.speech,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        );
        await _player.setReleaseMode(ReleaseMode.loop);
        // A phone call, Siri or an alarm interrupts playback, and nothing
        // restarts it on its own — the session would then be suspended at the
        // next silent gap and never come back. Pick it up again instead.
        _watch = _player.onPlayerStateChanged.listen((s) {
          if (!_running || _restarting) return;
          if (s == PlayerState.playing) return;
          _restarting = true;
          Future<void>.delayed(const Duration(seconds: 1), () async {
            _restarting = false;
            if (!_running) return;
            try {
              await _player.resume();
            } catch (_) {}
          });
        });
        _configured = true;
      }
      // Inaudible, but a real signal: the point is that the output keeps
      // running, not that anything is heard.
      await _player.setVolume(0.01);
      await _player.play(AssetSource('audio/silence.wav'));
    } catch (_) {
      // If the platform refuses the player, speech still works in the
      // foreground — the session just won't survive backgrounding.
      _running = false;
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _running = false;
    try {
      await _watch?.cancel();
      await _player.dispose();
    } catch (_) {}
  }
}
