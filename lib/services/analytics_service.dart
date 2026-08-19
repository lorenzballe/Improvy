import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Every event name the app sends, in one place.
///
/// Named `object_verb` and written here rather than inline, so a typo cannot
/// silently create a second event that looks like the first one in the
/// dashboard — the failure mode that quietly ruins a funnel. Anything not in
/// this list is not sent.
abstract final class Ev {
  // ── First run ──
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingCompleted = 'onboarding_completed';
  /// The activation moment: one finished game. Fired once, ever.
  static const firstSessionCompleted = 'first_session_completed';

  // ── Training ──
  static const setupOpened = 'setup_opened';
  static const sessionStarted = 'session_started';
  static const sessionFinished = 'session_finished';
  static const sessionAbandoned = 'session_abandoned';
  static const perfectSession = 'perfect_session';
  static const levelUp = 'level_up';

  // ── Daily challenge ──
  static const dailyStarted = 'daily_challenge_started';
  static const dailyFinished = 'daily_challenge_finished';
  static const dailyShared = 'daily_challenge_shared';
  static const streakMilestone = 'streak_milestone';

  // ── Pocket Mode ──
  static const pocketStarted = 'pocket_session_started';
  static const pocketFinished = 'pocket_session_finished';
  static const pocketBackgrounded = 'pocket_backgrounded';

  // ── Free Mode ──
  static const freeModeOpened = 'free_mode_opened';
  static const freeModeFinished = 'free_mode_finished';

  // ── Discovery ──
  static const keyStatsOpened = 'key_stats_opened';
  static const widgetTapped = 'widget_tapped';
  static const whatsNewOpened = 'whats_new_opened';
  static const instagramOpened = 'instagram_opened';

  // ── Money ──
  /// The one free users fire most: what they wanted and could not have.
  static const lockedFeatureTapped = 'locked_feature_tapped';
  static const paywallShown = 'paywall_shown';
  static const paywallDismissed = 'paywall_dismissed';
  static const purchaseStarted = 'pro_purchase_start';
  static const purchaseSucceeded = 'pro_purchase_success';
  static const purchaseCancelled = 'pro_purchase_cancelled';
  static const purchaseFailed = 'pro_purchase_error';
  static const purchaseNoOffering = 'pro_purchase_no_offering';
  static const restore = 'pro_restore';

  // ── Settings & notifications ──
  static const settingChanged = 'setting_changed';
  static const notifPermissionAsked = 'notification_permission_asked';
  static const notifPermissionResult = 'notification_permission_result';

  // ── Reviews ──
  static const reviewPrompted = 'review_prompt_requested';
  static const reviewStoreOpened = 'review_store_opened';

  // ── Health: things that failed where the user could not see it ──
  static const startupStepFailed = 'startup_step_failed';
  static const audioSessionFailed = 'audio_session_failed';
  static const questionUnspeakable = 'question_unspeakable';
}

/// Analytics wrapper backed by PostHog (EU cloud).
///
/// Three things beyond plain event capture, because without them the events
/// answer almost nothing:
///
///  * **Person profiles.** The SDK defaults to `identifiedOnly`, and an app
///    with no login never identifies anyone — so every person property was
///    being dropped and retention could not be measured at all. Set to
///    `always`: an anonymous device is still a person worth counting.
///  * **Super properties.** `is_pro` and `level` ride on every event, so any
///    chart can be split by them without joining anything.
///  * **Person properties.** Pushed after each session, so cohorts like
///    "played 10+ games, still free" are one filter rather than a query.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _apiKey = 'phc_xWTwCXAdzGvKo9Qp4cfNoDwbrLssrnGFJVZQhQmxcrHP';
  static const String _host = 'https://eu.i.posthog.com';

  bool _enabled = false;

  Future<void> init() async {
    try {
      final config = PostHogConfig(_apiKey)
        ..host = _host
        ..debug = kDebugMode
        ..flushAt = kDebugMode ? 1 : 20
        // Person profiles for everyone. Nobody signs in, so `identifiedOnly`
        // means nobody is ever a person: no retention curve, no cohorts, and
        // every person property silently discarded.
        ..personProfiles = PostHogPersonProfiles.always
        // Installs, updates, opens and backgrounds, for free and more
        // reliably than the single manual event this replaces.
        ..captureApplicationLifecycleEvents = true
        // Crashes and unhandled errors as $exception events. A one-person app
        // has no other way to learn that a device is failing.
        ..errorTrackingConfig.captureFlutterErrors = true
        ..errorTrackingConfig.capturePlatformDispatcherErrors = true;
      await Posthog().setup(config);
      _enabled = true;
      if (kDebugMode) debugPrint('[PostHog] ✓ initialised');
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHog] init failed: $e');
    }
  }

  /// Enable or disable event collection at runtime (e.g. after consent).
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
    //
    // PostHog's server-side GeoIP is deliberately left ON: it derives a coarse
    // city/region from the request IP so we can see roughly where users are.
    // This is declared as "Coarse Location — Analytics only, not linked, not
    // tracking" in the privacy manifest and the App Store Connect label, and
    // in the site privacy policy. It is the ONLY source of location — the app
    // requests no location permission.
    try {
      final clean = <String, Object>{};
      properties?.forEach((k, v) {
        if (v != null) clean[k] = v;
      });
      Posthog().capture(eventName: event, properties: clean);
    } catch (e) {
      if (kDebugMode) debugPrint('[PostHog] capture failed: $e');
    }
  }

  /// A screen view. Uses PostHog's own `$screen`, so the built-in screen
  /// reports work instead of a custom event nothing knows how to read.
  void screen(String name, [Map<String, Object?>? properties]) {
    if (!_enabled) return;
    try {
      final clean = <String, Object>{};
      properties?.forEach((k, v) {
        if (v != null) clean[k] = v;
      });
      Posthog().screen(screenName: name, properties: clean);
    } catch (_) {}
  }

  /// Properties carried by every subsequent event, so any chart can be split
  /// by them without a join. Kept deliberately short — a super property is
  /// paid for on every single event.
  Future<void> setSuperProperties({required bool isPro, required int level}) async {
    if (!_enabled) return;
    try {
      await Posthog().register('is_pro', isPro);
      await Posthog().register('level', level);
    } catch (_) {}
  }

  /// Who this person is now, and who they were the first time. `setOnce`
  /// values are never overwritten, which is what makes "first seen" usable as
  /// a cohort boundary.
  Future<void> setPerson(
    Map<String, Object?> properties, {
    Map<String, Object?>? once,
  }) async {
    if (!_enabled) return;
    try {
      Map<String, Object>? clean(Map<String, Object?>? m) {
        if (m == null) return null;
        final out = <String, Object>{};
        m.forEach((k, v) {
          if (v != null) out[k] = v;
        });
        return out.isEmpty ? null : out;
      }

      await Posthog().setPersonProperties(
        userPropertiesToSet: clean(properties),
        userPropertiesToSetOnce: clean(once),
      );
    } catch (_) {}
  }

  /// The last locked door a free user pushed on, waiting to be claimed by the
  /// paywall that opens next.
  String? _lastLocked;

  /// A free user tapped something they cannot have. The single most useful
  /// event this app sends: it is the only one that says what people actually
  /// want, rather than what they settle for.
  void lockedFeature(String feature) {
    _lastLocked = feature;
    capture(Ev.lockedFeatureTapped, {'feature': feature});
  }

  /// Reads and clears the pending lock, so a paywall opened later by some
  /// other route cannot inherit a stale attribution.
  String? takeLockedFeature() {
    final f = _lastLocked;
    _lastLocked = null;
    return f;
  }

  /// A remote switch, decided in PostHog rather than in a release.
  ///
  /// The one thing a professional app does that this one could not: change the
  /// paywall wording, the daily's difficulty or the onboarding order for half
  /// the users and read which half converts — without shipping a build and
  /// waiting a week for review. Already in the SDK; nothing to install.
  ///
  /// Returns [fallback] when the flag is unknown or the network is not there,
  /// so a flag that never loads is simply the behaviour that ships today.
  Future<bool> flag(String key, {bool fallback = false}) async {
    if (!_enabled) return fallback;
    try {
      return await Posthog().isFeatureEnabled(key);
    } catch (_) {
      return fallback;
    }
  }

  /// The variant of a multi-way experiment ('control', 'b', …), or null.
  Future<String?> variant(String key) async {
    if (!_enabled) return null;
    try {
      final v = await Posthog().getFeatureFlag(key);
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// An error the user never sees. These are the ones worth knowing about:
  /// a device where audio, storage or the store quietly does not work looks
  /// exactly like a device where the user simply stopped playing.
  void error(String event, Object err, [Map<String, Object?>? properties]) {
    capture(event, {...?properties, 'error': err.toString()});
  }
}
