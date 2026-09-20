import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show MethodChannel;

/// Where this install came from, asked of the Android host.
///
/// Play Billing refuses to sell through an app it does not recognise and says
/// only `purchaseNotAllowedError`: no dialog, no reason, no detail in the
/// exception. That single code covers an install that never came from the Play
/// Store, a Google account that cannot pay, and a product that is not live —
/// three different problems with three different fixes, and from inside the
/// failure they look identical.
///
/// The install source settles the first of the three, so we attach it to the
/// failure event instead of guessing from the outside. It says nothing about
/// the person: only which app installed ours, and whether the Play Store is
/// present. iOS has no equivalent and needs none — the App Store is the only
/// way an app gets there.
abstract final class StoreDiagnostics {
  static const _channel = MethodChannel('improvy/store_diagnostics');

  static Map<String, Object?>? _cached;

  /// Never throws and never blocks a purchase: a diagnostic that can break the
  /// thing it is diagnosing is worse than no diagnostic. An empty map means
  /// "could not tell", which the dashboard reads as an absence rather than as
  /// a wrong answer.
  static Future<Map<String, Object?>> describe() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const {};
    }
    // The install source cannot change while the app is running, so one call
    // per session is enough.
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final raw = await _channel
          .invokeMapMethod<String, Object?>('describe')
          // A purchase failure is already a bad moment; waiting on a host that
          // is not answering would turn it into a frozen button.
          .timeout(const Duration(seconds: 2));
      return _cached = raw == null ? const {} : Map.unmodifiable(raw);
    } catch (_) {
      return _cached = const {};
    }
  }
}
