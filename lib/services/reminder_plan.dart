/// A ready-to-fire notification: a title and body, both already personalized
/// (and, where relevant, question-shaped) by AppProvider — the scheduler stays
/// a pure "when to fire what" engine and does no content logic itself.
typedef ReminderMessage = (String title, String body);

/// Everything the notification scheduler needs to (re)build the pending local
/// notifications. Computed by AppProvider from live stats/settings and handed
/// to NotificationService.resync() — a plain DTO so the scheduler stays
/// platform-only and the provider stays plugin-free.
class ReminderPlan {
  /// Daily practice reminder on/off + its wall-clock time (user-controlled).
  final bool dailyOn;
  final int hour;
  final int minute;

  /// Comeback nudges (3 and 7 days after the last game, then silence).
  final bool comebackOn;

  /// True when at least one answer was recorded today — today's daily reminder
  /// is skipped so the app never nags someone who already practised.
  final bool playedToday;

  /// Timestamp (ms) of the most recent game; null before the first game — no
  /// comeback reminders are scheduled for someone who never started.
  final int? lastPlayedMs;

  /// Current daily streak length (0 = none). Framed into the streak-save nudge.
  final int streak;

  /// Rotating pool of daily messages — mostly degree-recall quiz questions
  /// ("What's the 3rd of A major?"), plus level nudges, weak-spot targets and a
  /// couple of evergreens. The scheduler spreads them across the upcoming daily
  /// slots so consecutive days differ.
  final List<ReminderMessage> dailyMessages;

  /// Overrides TODAY's slot when a streak is at risk (played recently but not
  /// yet today) — the highest-impact retention nudge. Null when there is no
  /// streak worth protecting.
  final ReminderMessage? streakSaveMessage;

  const ReminderPlan({
    required this.dailyOn,
    required this.hour,
    required this.minute,
    required this.comebackOn,
    required this.playedToday,
    required this.lastPlayedMs,
    required this.streak,
    required this.dailyMessages,
    required this.streakSaveMessage,
  });
}
