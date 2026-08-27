import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local (device-side) notifications: session results, streaks, milestones.
///
/// Everything here is best-effort. A platform with no notifications support, a
/// user who declined the permission, or an OEM that blocks the channel must
/// never take the app down — every entry point swallows its failure and logs
/// it in debug only.
class NotificationsService {
  NotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// False until [init] has succeeded; [_show] is a no-op before that.
  static bool _ready = false;

  /// Fixed ids per kind, so a new notification of the same kind REPLACES the
  /// previous one instead of stacking. Nobody wants six "session complete"
  /// rows in their shade.
  static const int _idSession = 1;
  static const int _idStreak = 2;
  static const int _idLevelUp = 3;
  static const int _idMilestone = 4;

  static Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Darwin requests alert/badge/sound during initialize by default.
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings: settings);
      _ready = true;
      await _requestPermission();
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationsService] init failed: $e');
    }
  }

  /// Android 13+ needs POST_NOTIFICATIONS granted at runtime (the permission
  /// itself is declared by the plugin's manifest). iOS is already covered by
  /// the Darwin initialization settings above.
  static Future<void> _requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'improvy_general',
        'Improvy',
        channelDescription: 'Session results, streaks and milestones',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFF3B82F6),
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationsService] show failed: $e');
    }
  }

  static Future<void> showSessionCompleteNotification({
    required int correctAnswers,
    required int totalAnswers,
    required String keyName,
  }) async {
    if (totalAnswers <= 0) return;
    final accuracy = (correctAnswers / totalAnswers * 100).round();
    await _show(
      id: _idSession,
      title: '🎉 Session complete!',
      body: 'Great job — $accuracy% accuracy in $keyName',
      payload: 'session_complete',
    );
  }

  static Future<void> showStreakNotification(int streak) async {
    await _show(
      id: _idStreak,
      title: '${streak >= 7 ? '🔥' : '✨'} $streak day streak!',
      body: 'Keep up the practice.',
      payload: 'streak_milestone',
    );
  }

  static Future<void> showLevelUpNotification(String animalName) async {
    await _show(
      id: _idLevelUp,
      title: '🚀 Level up!',
      body: 'You reached $animalName level.',
      payload: 'level_up',
    );
  }

  static Future<void> showMilestoneNotification(String milestone) async {
    await _show(
      id: _idMilestone,
      title: '⭐ Milestone unlocked!',
      body: milestone,
      payload: 'milestone',
    );
  }
}
