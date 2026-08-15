import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAudioSession(engineBridge.pluginRegistry)
  }

  /// Owns the AVAudioSession for Pocket Mode, because the audio plugin does not.
  ///
  /// `UIBackgroundModes: audio` only earns the app background time while the
  /// system considers its session an active, primary playback session. The
  /// audioplayers plugin sets the *category* but calls `setActive(true)` in
  /// exactly one place — after a sound finishes — and never on the path that
  /// starts one. So the session is only ever implicitly active, which the
  /// system honours while the screen is on and drops the moment it locks.
  /// Attached to a debugger that is invisible, since iOS does not suspend a
  /// debugged app; in a release build the voice stops the instant you lock.
  ///
  /// Two methods, called by KeepAliveAudio around a session:
  ///   activate   - claim playback, explicitly, before the first sound
  ///   deactivate - hand the output back when the drill stops
  private func registerAudioSession(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "ImprovyAudioSession") else { return }
    let channel = FlutterMethodChannel(
      name: "improvy/audio_session", binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { call, result in
      let session = AVAudioSession.sharedInstance()
      do {
        switch call.method {
        case "activate":
          // .spokenAudio is the documented mode for speech content: it tells
          // the system this is talk, not music, so a car head unit treats it
          // as such. No .mixWithOthers — an app that declares its audio
          // mixable is telling the system it is secondary, and secondary
          // audio is not what keeps a locked phone awake.
          //
          // `try?`, deliberately: the category is the nice-to-have and the
          // activation is the fix. audioplayers has already put the session in
          // .playback, so a device that refuses this exact combination must
          // not be allowed to skip the setActive below — that would leave the
          // session implicit again, which is the whole bug.
          try? session.setCategory(
            .playback, mode: .spokenAudio, options: [.allowBluetoothA2DP])
          try session.setActive(true)
          result(true)
        case "deactivate":
          // Let whatever was playing before pick itself back up.
          try session.setActive(false, options: .notifyOthersOnDeactivation)
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(
          FlutterError(
            code: "audio_session", message: error.localizedDescription, details: nil))
      }
    }
  }
}
