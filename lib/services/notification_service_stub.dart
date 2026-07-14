import 'reminder_plan.dart';

/// No-op implementation for platforms without flutter_local_notifications
/// (the web preview build). The Settings UI still shows and stores the
/// toggles; scheduling simply does nothing here.
class NotificationService {
  static Future<void> init() async {}
  static Future<bool> requestPermission() async => false;
  static Future<void> resync(ReminderPlan plan) async {}
}
