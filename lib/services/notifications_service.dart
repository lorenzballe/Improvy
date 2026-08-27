import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsService {
  static final _instance = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Android setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _instance.initialize(settings);

    // Request notification permission
    await Permission.notification.request();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'improvy_channel',
      'Improvy Notifications',
      channelDescription: 'Notifications for Improvy',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Color.fromARGB(255, 59, 130, 246), // Blue
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _instance.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> showSessionCompleteNotification({
    required int correctAnswers,
    required int totalAnswers,
    required String keyName,
  }) async {
    final accuracy = ((correctAnswers / totalAnswers) * 100).toStringAsFixed(0);

    await showNotification(
      title: '🎉 Session Complete!',
      body: 'Great job! $accuracy% accuracy on $keyName',
      payload: 'session_complete',
    );
  }

  static Future<void> showStreakNotification(int streak) async {
    final fireEmoji = streak >= 7 ? '🔥' : '✨';

    await showNotification(
      title: '$fireEmoji $streak Day Streak!',
      body: 'Keep up the amazing practice!',
      payload: 'streak_milestone',
    );
  }

  static Future<void> showLevelUpNotification(String animalName) async {
    await showNotification(
      title: '🚀 Level Up!',
      body: 'You reached $animalName level!',
      payload: 'level_up',
    );
  }

  static Future<void> showMilestoneNotification(String milestone) async {
    await showNotification(
      title: '⭐ Milestone Unlocked!',
      body: milestone,
      payload: 'milestone',
    );
  }
}
