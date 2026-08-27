import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Analytics wrapper backed by PostHog (EU cloud).
///
/// Initialization is done entirely from Dart — no native auto-init.
/// In debug builds: events flush immediately and PostHog prints verbose logs.
/// In release builds: events are batched (flushAt = 20, every 30 s).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _apiKey = 'phc_xWTwCXAdzGvKo9Qp4cfNoDwbrLssrnGFJVZQhQmxcrHP';
  static const String _host   = 'https://eu.i.posthog.com';

  bool _enabled = false;

  Future<void> init() async {
    try {
      final config = PostHogConfig(_apiKey)
        ..host = _host
        ..debug = kDebugMode          // verbose logs in Flutter console (debug only)
        ..flushAt = kDebugMode ? 1 : 20  // immediate flush in debug → see events instantly
        ..captureApplicationLifecycleEvents = false; // we fire app_open manually
      await Posthog().setup(config);
      _enabled = true;
      if (kDebugMode) debugPrint('[PostHog] ✓ initialised — events will appear in Live Events');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHog] init failed: $e');
    }
  }

  /// Enable or disable event collection at runtime (e.g. after consent dialog).
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (enabled) {
      await Posthog().enable();
    } else {
      await Posthog().disable();
    }
  }

  void capture(String event, [Map<String, Object?>? properties]) {
    if (!_enabled) {
      if (kDebugMode) debugPrint('[PostHog] (disabled) $event');
      return;
    }
    if (kDebugMode) debugPrint('[PostHog] capture: $event ${properties ?? {}}');
    // Analytics must NEVER break app flow — swallow any SDK/channel error so a
    // failed capture can't stop e.g. the paywall from opening.
    try {
      Posthog().capture(eventName: event, properties: properties?.cast<String, Object>());
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHog] capture failed: $e');
    }
  }

  /// Attaches [value] to every event captured from now on (a PostHog "super
  /// property"), and persists it across launches.
  ///
  /// Used to carry FOREIGN ids — e.g. the RevenueCat customer id. PostHog and
  /// RevenueCat each generate their own anonymous id, so without a bridge like
  /// this there is no way to go from a user seen in analytics to their
  /// RevenueCat customer (to grant a promotional entitlement, say).
  Future<void> registerSuperProperty(String key, String value) async {
    if (!_enabled || value.isEmpty) return;
    try {
      await Posthog().register(key, value);
      if (kDebugMode) debugPrint('[PostHog] register: $key = $value');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHog] register failed: $e');
    }
  }

  void screen(String name) => capture('\$screen', {'name': name});
}
