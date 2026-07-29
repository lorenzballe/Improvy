import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_info.dart';
import 'analytics_service.dart';

/// Asks for a store rating — but only at a moment the user is demonstrably
/// happy, and rarely.
///
/// The OS shows its own native sheet (`SKStoreReviewController` on iOS, In-App
/// Review on Android): the user rates without leaving the app, and we are never
/// told whether the sheet actually appeared — iOS silently swallows the request
/// after ~3 prompts a year. That one-way door is the whole design constraint:
/// a request spent on a bad moment is simply gone, so every call goes through
/// [_isGoodMoment] first.
///
/// Deliberately NOT done: a home-made "Do you like Improvy? Yes/No" pre-prompt
/// that routes only the happy users to the store. It filters reviews, breaks
/// App Store Review 1.1.7, and is a rejection risk.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _lastAskedKey = 'review_last_asked_ms';
  static const _askCountKey = 'review_ask_count';
  static const _sessionsKey = 'review_sessions_seen';

  /// A paywall closed without a purchase is the emotional opposite of a good
  /// moment; asking for stars in its wake is how apps collect one-star
  /// reviews. Set on dismissal, honoured for this long.
  static const Duration _frictionCooldown = Duration(minutes: 10);
  DateTime? _lastFriction;

  /// Never ask a newcomer: three finished sessions is the floor for having
  /// seen enough of the app to have an opinion worth a star rating.
  static const _minSessions = 3;

  /// iOS caps prompts at ~3/year on its own; we stay well inside that so a
  /// request is never wasted on a user who already saw one recently.
  static const Duration _minGap = Duration(days: 120);

  /// After this many asks, stop. Someone who ignored three prompts is telling
  /// us something.
  static const _maxAsks = 3;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Counts a finished session. Cheap, called from the provider on every
  /// session end — the prompt itself is gated separately.
  Future<void> recordSession() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionsKey, (prefs.getInt(_sessionsKey) ?? 0) + 1);
    } catch (_) {
      // A missing counter only means we ask a little later. Never worth a crash.
    }
  }

  /// Marks "the user just hit something unpleasant" — a paywall dismissed
  /// without buying, a failed purchase. Suppresses the prompt for a while.
  void noteFrictionMoment() => _lastFriction = DateTime.now();

  /// Requests the native rating sheet if this is a good moment.
  ///
  /// [trigger] is for analytics only ('level_up', 'daily_perfect', …) — it
  /// tells us later which peak converts, so the rules can be tuned on data
  /// instead of taste.
  Future<void> maybeAsk({required String trigger}) async {
    // The plugin has no web implementation; calling there throws.
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_isGoodMoment(prefs)) return;
      if (!await _inAppReview.isAvailable()) return;

      // Record BEFORE requesting: if the call throws halfway we must not
      // retry on the next level-up and burn the user's patience.
      await prefs.setInt(_lastAskedKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_askCountKey, (prefs.getInt(_askCountKey) ?? 0) + 1);
      AnalyticsService.instance.capture('review_prompt_requested', {'trigger': trigger});

      await _inAppReview.requestReview();
    } catch (e) {
      // Store unreachable, sandbox build, unsupported device — all fine.
      if (kDebugMode) debugPrint('[ReviewService] request skipped: $e');
    }
  }

  /// True when "Rate Improvy" can actually go somewhere: Android resolves the
  /// listing from the package name, iOS needs [kAppStoreId] to be filled in.
  bool get canOpenStoreListing =>
      !kIsWeb && (defaultTargetPlatform != TargetPlatform.iOS || kAppStoreId.isNotEmpty);

  /// Opens the store page for a deliberate, user-initiated rating (the
  /// Settings row) — not the native sheet, which is reserved for peaks.
  Future<void> openStoreListing() async {
    if (!canOpenStoreListing) return;
    AnalyticsService.instance.capture('review_store_opened');
    try {
      await _inAppReview.openStoreListing(appStoreId: kAppStoreId);
    } catch (e) {
      if (kDebugMode) debugPrint('[ReviewService] openStoreListing failed: $e');
    }
  }

  bool _isGoodMoment(SharedPreferences prefs) {
    if (_lastFriction != null &&
        DateTime.now().difference(_lastFriction!) < _frictionCooldown) {
      return false;
    }
    if ((prefs.getInt(_sessionsKey) ?? 0) < _minSessions) return false;
    if ((prefs.getInt(_askCountKey) ?? 0) >= _maxAsks) return false;
    final last = prefs.getInt(_lastAskedKey);
    if (last != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) < _minGap) {
      return false;
    }
    return true;
  }
}
