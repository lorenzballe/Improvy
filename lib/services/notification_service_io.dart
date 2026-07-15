import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_plan.dart';

/// Real (Android/iOS) implementation. Everything is a one-shot notification:
/// the whole pending set is wiped and rebuilt by [resync] on every app open,
/// session end and settings change, so content is always computed from the
/// freshest stats and a reminder silently disappears once it's obsolete
/// (e.g. today's nudge after the user has already practised).
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Practice reminders',
      channelDescription: 'Daily practice and comeback reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Permission is asked explicitly at a meaningful moment (after the
      // first finished game), never as a cold-start popup.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    _ready = await _plugin.initialize(settings) ?? false;
  }

  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  // Generic daily texts, rotated by date so consecutive days differ.
  static const _daily = [
    '5 minutes a day and every key becomes home. Ready?',
    'Do you know the ♭3 of E without thinking? Prove it.',
    'Fast thinking beats slow theory. Quick session?',
    'Every degree, every key, instantly. Keep building it.',
  ];

  static Future<void> resync(ReminderPlan plan) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final now = DateTime.now();

    if (plan.dailyOn) {
      // The next 7 daily slots as one-shots (re-armed on every resync). Fixed
      // instants instead of a repeating rule: content can differ per day and
      // no exact-alarm permission is needed.
      for (var d = 0; d < 7; d++) {
        final when = DateTime(now.year, now.month, now.day + d, plan.hour, plan.minute);
        if (!when.isAfter(now)) continue; // today's slot already behind us
        if (d == 0 && plan.playedToday) continue; // already practised today
        final seed = when.day + when.month;
        final useWeak = plan.weakSpotBody != null && seed.isEven;
        await _schedule(
          100 + d,
          useWeak ? 'Target practice 🎯' : 'Improvy',
          useWeak ? plan.weakSpotBody! : _daily[seed % _daily.length],
          when,
        );
      }
    }

    if (plan.comebackOn && plan.lastPlayedMs != null) {
      // Two nudges after the last game — 3 and 7 days — then silence forever.
      // "Forever" needs no bookkeeping: only these two are ever scheduled,
      // and any new game moves the anchor.
      final last = DateTime.fromMillisecondsSinceEpoch(plan.lastPlayedMs!);
      const comebacks = [
        (200, 3, 'Scale degrees fade fast when you stop. Your keys miss you.'),
        (201, 7, 'A week away — your instant recall needs a warm-up. Come back?'),
      ];
      for (final (id, days, body) in comebacks) {
        final when = DateTime(last.year, last.month, last.day + days, 19, 0);
        if (when.isAfter(now)) await _schedule(id, 'Improvy', body, when);
      }
    }
  }

  static Future<void> _schedule(int id, String title, String body, DateTime when) {
    // The local DateTime already pins the absolute instant; expressing it in
    // UTC avoids needing the device's IANA zone name. Slots are at most 7
    // days out and re-armed on every app open, so a DST switch can shift a
    // far slot by one hour at worst — acceptable for a practice nudge.
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.UTC),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
