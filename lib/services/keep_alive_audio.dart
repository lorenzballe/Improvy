import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Put the shared audio session into a category that survives the screen
  /// locking, and that the ring/silent switch does not mute.
  ///
  /// Called once from `main()`, before anything creates a player. It used to
  /// run only when Pocket Mode started playing, which left every player made
  /// before that — including the voice player warmed up in initState — on
  /// whatever category the plugin defaults to. An `ambient` default is silent
  /// with the ring switch off and never plays in the background, so the whole
  /// mode could come out mute on a device that happened to be on silent.
  static Future<void> configureSession() async {
    if (kIsWeb) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            // No mixWithOthers. It reads as a courtesy — share the output with
            // whatever else is playing — but what it actually declares is that
            // this audio is secondary, and the system does not keep a locked
            // phone awake for secondary audio. A call-and-response drill over
            // someone's music was never usable anyway.
            // A2DP only: allowBluetooth is the hands-free profile and is valid
            // for the recording categories, not for playback. Passing it here
            // risks the whole setCategory being rejected, which would leave
            // the session on whatever the plugin defaults to.
            options: {AVAudioSessionOptions.allowBluetoothA2DP},
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
    } catch (_) {
      // A refused session must not stop the app launching; playback simply
      // falls back to whatever the platform gives us.
    }
  }

  /// iOS only: claim or release the playback session explicitly.
  ///
  /// audioplayers sets the session's category but only ever calls
  /// `setActive(true)` from its sound-finished handler, never from the one that
  /// starts a sound. An implicitly active session is honoured while the screen
  /// is on and dropped when it locks — which is why the voice used to stop the
  /// instant the phone locked in a release build, while a debugged build (which
  /// iOS never suspends) looked fine. [AppDelegate] answers this channel.
  static Future<void> _session(String method) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await const MethodChannel('improvy/audio_session').invokeMethod<void>(method);
    } catch (_) {
      // An older build without the native side, or a session the system
      // refuses: playback still works, it just won't survive the lock.
    }
  }

  Future<void> start() async {
    // Web tabs get throttled by the browser, not by an audio session — the
    // trick doesn't apply there and would only cost an extra decoder.
    if (kIsWeb || _running) return;
    _running = true;
    try {
      if (!_configured) {
        // Belt and braces: main() has already done this, but a session can be
        // reset by an interruption, and re-asserting it is cheap.
        await configureSession();
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
      // Claim the output before the first sound, not after one finishes.
      await _session('activate');
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
    await _session('deactivate');
  }

  Future<void> dispose() async {
    _running = false;
    try {
      await _watch?.cancel();
      await _player.dispose();
    } catch (_) {}
  }
}
