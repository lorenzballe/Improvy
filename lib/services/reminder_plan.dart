/// Everything the notification scheduler needs to (re)build the pending
/// local notifications. Computed by AppProvider from live stats/settings and
/// handed to NotificationService.resync() — a plain DTO so the scheduler
/// stays platform-only and the provider stays plugin-free.
class ReminderPlan {
  /// Daily practice reminder on/off + its wall-clock time.
  final bool dailyOn;
  final int hour;
  final int minute;

  /// Comeback nudges (3 and 7 days after the last game, then silence).
  final bool comebackOn;

  /// True when at least one answer was recorded today — today's daily
  /// reminder is skipped so the app never nags someone who already practised.
  final bool playedToday;

  /// Timestamp (ms) of the most recent game; null before the first game —
  /// no comeback reminders are scheduled for someone who never started.
  final int? lastPlayedMs;

  /// Ready-made "weak spot" message derived from Common Confusions data,
  /// or null when there is no recurring confusion to point at. When present
  /// it replaces the generic daily text on alternating days.
  final String? weakSpotBody;

  const ReminderPlan({
    required this.dailyOn,
    required this.hour,
    required this.minute,
    required this.comebackOn,
    required this.playedToday,
    required this.lastPlayedMs,
    required this.weakSpotBody,
  });
}
