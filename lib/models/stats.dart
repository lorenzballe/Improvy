class DayStats {
  final int attempts;
  final int correct;
  final int responseTime; // total ms
  final int sessions;

  DayStats({
    this.attempts = 0,
    this.correct = 0,
    this.responseTime = 0,
    this.sessions = 0,
  });

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'correct': correct,
        'responseTime': responseTime,
        'sessions': sessions,
      };

  factory DayStats.fromJson(Map<String, dynamic> json) => DayStats(
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        responseTime: (json['responseTime'] as num?)?.toInt() ?? 0,
        sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      );

  DayStats operator +(DayStats other) => DayStats(
        attempts: attempts + other.attempts,
        correct: correct + other.correct,
        responseTime: responseTime + other.responseTime,
        sessions: sessions + other.sessions,
      );
}

class AnswerRecord {
  final String degree;
  final String note;
  final String selectedNote;
  final String tonality;
  final String mode;
  final bool isReverse;
  final int difficulty;
  final int responseTime;
  final bool isCorrect;
  final int timestamp;

  AnswerRecord({
    required this.degree,
    required this.note,
    required this.selectedNote,
    required this.tonality,
    required this.mode,
    required this.isReverse,
    required this.difficulty,
    required this.responseTime,
    required this.isCorrect,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'note': note,
        'selectedNote': selectedNote,
        'tonality': tonality,
        'mode': mode,
        'isReverse': isReverse,
        'difficulty': difficulty,
        'responseTime': responseTime,
        'isCorrect': isCorrect,
        'timestamp': timestamp,
      };

  factory AnswerRecord.fromJson(Map<String, dynamic> json) => AnswerRecord(
        degree: json['degree'] ?? '',
        note: json['note'] ?? '',
        selectedNote: json['selectedNote'] ?? '',
        tonality: json['tonality'] ?? '',
        mode: json['mode'] ?? '',
        isReverse: json['isReverse'] ?? false,
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        responseTime: (json['responseTime'] as num?)?.toInt() ?? 0,
        isCorrect: json['isCorrect'] ?? false,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      );
}

class SessionRecord {
  final int timestamp;
  final int correct;
  final int total;
  final List<AnswerRecord> answers;

  SessionRecord({
    required this.timestamp,
    required this.correct,
    required this.total,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'correct': correct,
        'total': total,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        answers: (json['answers'] as List?)
                ?.map((a) => AnswerRecord.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AppStats {
  final int totalSessions;
  final int totalAttempts;
  final int totalCorrect;
  final int totalResponseTime;
  final Map<String, DayStats> dailyHistory;
  final List<SessionRecord> sessionHistory;
  final int currentSessionCorrect;
  final int currentSessionTotal;
  final List<AnswerRecord> currentSessionAnswers;

  AppStats({
    this.totalSessions = 0,
    this.totalAttempts = 0,
    this.totalCorrect = 0,
    this.totalResponseTime = 0,
    Map<String, DayStats>? dailyHistory,
    List<SessionRecord>? sessionHistory,
    this.currentSessionCorrect = 0,
    this.currentSessionTotal = 0,
    List<AnswerRecord>? currentSessionAnswers,
  })  : dailyHistory = dailyHistory ?? {},
        sessionHistory = sessionHistory ?? [],
        currentSessionAnswers = currentSessionAnswers ?? [];

  AppStats copyWith({
    int? totalSessions,
    int? totalAttempts,
    int? totalCorrect,
    int? totalResponseTime,
    Map<String, DayStats>? dailyHistory,
    List<SessionRecord>? sessionHistory,
    int? currentSessionCorrect,
    int? currentSessionTotal,
    List<AnswerRecord>? currentSessionAnswers,
  }) =>
      AppStats(
        totalSessions: totalSessions ?? this.totalSessions,
        totalAttempts: totalAttempts ?? this.totalAttempts,
        totalCorrect: totalCorrect ?? this.totalCorrect,
        totalResponseTime: totalResponseTime ?? this.totalResponseTime,
        dailyHistory: dailyHistory ?? this.dailyHistory,
        sessionHistory: sessionHistory ?? this.sessionHistory,
        currentSessionCorrect: currentSessionCorrect ?? this.currentSessionCorrect,
        currentSessionTotal: currentSessionTotal ?? this.currentSessionTotal,
        currentSessionAnswers: currentSessionAnswers ?? this.currentSessionAnswers,
      );

  Map<String, dynamic> toJson() => {
        'totalSessions': totalSessions,
        'totalAttempts': totalAttempts,
        'totalCorrect': totalCorrect,
        'totalResponseTime': totalResponseTime,
        'dailyHistory': dailyHistory.map((k, v) => MapEntry(k, v.toJson())),
        'sessionHistory': sessionHistory.map((s) => s.toJson()).toList(),
      };

  factory AppStats.fromJson(Map<String, dynamic> json) => AppStats(
        totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
        totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
        totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
        totalResponseTime: (json['totalResponseTime'] as num?)?.toInt() ?? 0,
        dailyHistory: (json['dailyHistory'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, DayStats.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
        sessionHistory: (json['sessionHistory'] as List?)
                ?.map((s) => SessionRecord.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
