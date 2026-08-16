import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioSessionChannel: FlutterMethodChannel?
  private let audio = BackgroundAudio()

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

  /// Owns the audio session and the keep-alive tone for Pocket Mode.
  ///
  /// Three methods, all called by KeepAliveAudio:
  ///   activate    - claim playback and start the tone
  ///   deactivate  - stop the tone and hand the output back
  ///   status      - what the session actually looks like right now, for when
  ///                 this does not work and nobody can see why
  ///
  /// Held for the life of the app on purpose: a channel that only exists as a
  /// local goes quiet if it is ever released, which looks exactly like the bug
  /// this exists to fix.
  private func registerAudioSession(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "ImprovyAudioSession") else { return }
    let channel = FlutterMethodChannel(
      name: "improvy/audio_session", binaryMessenger: registrar.messenger())
    audioSessionChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "activate":
        do {
          try self.audio.start()
          result(self.audio.status())
        } catch {
          result(
            FlutterError(
              code: "audio_session", message: error.localizedDescription,
              details: self.audio.status()))
        }
      case "deactivate":
        self.audio.stop()
        result(nil)
      case "status":
        result(self.audio.status())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// Keeps Pocket Mode running with the screen locked.
///
/// `UIBackgroundModes: audio` does not mean "keep my app running". It means the
/// system will not suspend the app *while audio is actually reaching the
/// output through an active session it considers primary*. Pocket Mode is
/// mostly silence — the seconds you spend working the answer out — so without
/// something filling those gaps the app is suspended in exactly them, every
/// timer stops, and the drill dies where it stands.
///
/// This used to be done from Dart, through the audio plugin, and it did not
/// hold. Two reasons, both fixed here:
///
///  1. The plugin never claims the session. It sets the category but calls
///     `setActive(true)` from exactly one place — its sound-finished handler —
///     and never on the path that starts a sound. An implicitly active session
///     is honoured while the screen is on and dropped the moment it locks.
///
///  2. The tone had a hole in it. The plugin loops by waiting for the file to
///     end, seeking back and starting again, which is an async round trip
///     through Dart with real silence in the middle of it. `AVAudioPlayer` with
///     `numberOfLoops = -1` loops inside the audio engine instead: no callback,
///     no seek, no gap for the system to notice.
///
/// The tone itself is generated here rather than read from an asset — one less
/// thing that can fail quietly on a device — and is a dither of ±1 LSB, which
/// is 90 dB below full scale. Inaudible, but not digital zero: the Dart side
/// was playing a ±1 file at volume 0.01, which rounds to nothing at all.
final class BackgroundAudio {
  private var player: AVAudioPlayer?
  private var observing = false

  func start() throws {
    let session = AVAudioSession.sharedInstance()
    // Best-effort, deliberately: the category is the nicety and the activation
    // is the fix. A device that dislikes this exact combination must not be
    // able to skip the setActive below — that would leave the session
    // implicitly active again, which is the whole bug.
    try? session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetoothA2DP])
    try session.setActive(true)

    if player == nil {
      player = try AVAudioPlayer(data: BackgroundAudio.tone())
      player?.numberOfLoops = -1
      player?.volume = 1.0 // the file is already 90 dB down; do not scale it away
      player?.prepareToPlay()
    }
    player?.play()
    observeInterruptions()
  }

  func stop() {
    player?.stop()
    player = nil
    // .notifyOthersOnDeactivation so whatever was playing before can resume.
    try? AVAudioSession.sharedInstance().setActive(
      false, options: .notifyOthersOnDeactivation)
  }

  /// A phone call, Siri or an alarm tears the session down, and nothing puts it
  /// back on its own — the app would then be suspended at the next silent gap
  /// and never return. Reclaim it when the interruption ends.
  private func observeInterruptions() {
    guard !observing else { return }
    observing = true
    NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance(), queue: .main
    ) { [weak self] note in
      guard
        let self, self.player != nil,
        let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
        AVAudioSession.InterruptionType(rawValue: raw) == .ended
      else { return }
      try? AVAudioSession.sharedInstance().setActive(true)
      self.player?.play()
    }
  }

  /// What the session actually is, so a report can say more than "it stopped".
  func status() -> [String: Any] {
    let s = AVAudioSession.sharedInstance()
    return [
      "category": s.category.rawValue,
      "mode": s.mode.rawValue,
      "options": Int(s.categoryOptions.rawValue),
      "playing": player?.isPlaying ?? false,
      "otherAudioPlaying": s.isOtherAudioPlaying,
      "outputs": s.currentRoute.outputs.map { $0.portType.rawValue },
      "backgroundModes":
        (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]) ?? [],
    ]
  }

  /// One second of mono 16-bit PCM at ±1 LSB, as a WAV in memory.
  private static func tone() -> Data {
    let rate = 44100, seconds = 1
    let frames = rate * seconds
    var d = Data(capacity: 44 + frames * 2)
    func str(_ s: String) { d.append(contentsOf: Array(s.utf8)) }
    func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }
    func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { d.append(contentsOf: $0) } }

    str("RIFF"); u32(UInt32(36 + frames * 2)); str("WAVE")
    str("fmt "); u32(16); u16(1); u16(1)
    u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
    str("data"); u32(UInt32(frames * 2))
    for i in 0..<frames {
      u16(UInt16(bitPattern: i % 2 == 0 ? Int16(1) : Int16(-1)))
    }
    return d
  }
}
