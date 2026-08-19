import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'analytics_service.dart';

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

  static const _channel = MethodChannel('improvy/audio_session');

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// What the last attempt to claim the session produced, for [describe].
  static Object? _lastSessionResult;

  /// On iOS the whole keep-alive lives natively — see BackgroundAudio in
  /// AppDelegate.swift for why. The plugin never claims the session, and its
  /// looping leaves a real hole in the output every time the file ends, which
  /// is exactly the moment the system decides nothing is playing.
  static Future<Object?> _session(String method) async {
    if (!_isIOS) return null;
    try {
      final r = await _channel.invokeMethod<Object?>(method);
      _lastSessionResult = r;
      return r;
    } catch (e) {
      // Recorded rather than swallowed. This failing silently is how the bug
      // survived two attempts at fixing it: the app looked identical whether
      // the native side answered or was not there at all — and on someone
      // else's phone there is no console to read.
      _lastSessionResult = 'FAILED $method: $e';
      debugPrint('[KeepAliveAudio] $_lastSessionResult');
      AnalyticsService.instance
          .error(Ev.audioSessionFailed, e, {'method': method});
      return null;
    }
  }

  /// A line describing the real audio session, for the Settings diagnostic.
  /// Empty off iOS, where none of this applies.
  static Future<String> describe() async {
    if (!_isIOS) return 'not iOS — nothing to report';
    final r = await _session('status') ?? _lastSessionResult;
    if (r == null) return 'no answer from the native side';
    if (r is! Map) return '$r';
    return 'category ${r["category"]} · mode ${r["mode"]}\n'
        'tone playing: ${r["playing"]}\n'
        'background modes: ${(r["backgroundModes"] as List?)?.join(", ")}\n'
        'output: ${(r["outputs"] as List?)?.join(", ")}';
  }

  Future<void> start() async {
    // Web tabs get throttled by the browser, not by an audio session — the
    // trick doesn't apply there and would only cost an extra decoder.
    if (kIsWeb || _running) return;
    _running = true;

    // iOS: claim the session and start the gapless tone, both natively.
    if (_isIOS) {
      await _session('activate');
      return;
    }

    // Android keeps the plugin-side loop: a wake lock plus a looping asset is
    // what holds a backgrounded player there, and none of the iOS session
    // machinery applies.
    try {
      if (!_configured) {
        await configureSession();
        await _player.setReleaseMode(ReleaseMode.loop);
        // A phone call or an alarm interrupts playback, and nothing restarts it
        // on its own — the loop would stop and never come back.
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
      // Full volume, not 0.01. The file is a ±1 LSB dither — 90 dB below full
      // scale and inaudible — so scaling it by a hundredth rounded it to
      // literal digital zero, which is not a signal at all.
      await _player.setVolume(1.0);
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
    if (_isIOS) {
      await _session('deactivate');
      return;
    }
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
