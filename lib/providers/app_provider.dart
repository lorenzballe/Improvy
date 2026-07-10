import 'package:flutter/foundation.dart';
import '../models/key_progress.dart';
import '../models/stats.dart';
import '../models/training_mode.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../constants/levels.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage;

  AppProvider(this._storage);

  // State
  List<KeyProgress> progressData = [];
  AppStats stats = AppStats();
  bool isPro = false;
  bool adaptiveDifficulty = false;
  bool tutorialCompleted = false;
  String notation = 'CDE'; // 'CDE' or 'DoReMi'
  // When true, the in-game piano keyboard starts from the current key's tonic
  // (or the white key just below it, if the tonic is a black key) instead of
  // always running C→C.
  bool keyboardFromTonic = false;

  String? selectedKey;
  // True while a single-key analytics sub-screen (inside Stats) is open, so the
  // root can hide the bottom nav and disable tab-swiping there.
  bool viewingKeyStats = false;
  TrainingMode? activeMode;
  int diatonicDifficulty = 1;
  int chromaticDifficulty = 1;

  Map<String, dynamic>? lastSession;

  // Setup mode state
  String setupMode = 'none'; // 'none', 'custom', 'note-to-number'
  List<String>? customDegrees;
  bool? isReverse;
  int? customDifficulty;
  int? customQuestions;

  Future<void> init() async {
    progressData = _storage.loadProgress();
    stats = _storage.loadStats();
    isPro = _storage.loadIsPro();
    adaptiveDifficulty = _storage.loadAdaptiveDifficulty();
    tutorialCompleted = _storage.loadTutorialCompleted();
    notation = _storage.loadNotation();
    keyboardFromTonic = _storage.loadKeyboardFromTonic();
    lastSession = _storage.loadLastSession();
    notifyListeners();
  }

  // Computed
  double get totalProgress {
    if (progressData.isEmpty) return 0;
    final total = progressData.fold<int>(0, (acc, k) => acc + k.totalProgress);
    return total / progressData.length;
  }

  AnimalLevel get animalLevel => getAnimalLevel(totalProgress);

  int get streak {
    final history = stats.dailyHistory;
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    final todayHasData = (history[today]?.attempts ?? 0) > 0;
    final yesterdayHasData = (history[yesterday]?.attempts ?? 0) > 0;

    if (!todayHasData && !yesterdayHasData) return 0;

    var count = 0;
    var checkDate = DateTime.now();
    if (!todayHasData) checkDate = checkDate.subtract(const Duration(days: 1));

    while (true) {
      final key = _dateKey(checkDate);
      if ((history[key]?.attempts ?? 0) > 0) {
        count++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }

  int get overallAccuracy {
    // Last 30 games (sessionHistory is newest-first), not last 30 days —
    // the whole stats screen is game-based.
    final recent = stats.sessionHistory.take(30).toList();
    final total = recent.fold<int>(0, (acc, s) => acc + s.total);
    final correct = recent.fold<int>(0, (acc, s) => acc + s.correct);
    if (total == 0) return 0;
    return (correct / total * 100).round();
  }

  int get averageResponseTime {
    if (stats.totalAttempts == 0) return 0;
    return (stats.totalResponseTime / stats.totalAttempts).round();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Actions
  void deselectKey() {
    selectedKey = null;
    notifyListeners();
  }

  void selectKey(String key) {
    selectedKey = key;
    activeMode = null;
    setupMode = 'none';

    final keyData = progressData.firstWhere((k) => k.key == key, orElse: () => KeyProgress(key: key));
    final dLevels = keyData.diatonicLevels;
    diatonicDifficulty = dLevels[0] < 27 ? 1 : dLevels[1] < 37 ? 2 : 3;

    final cLevels = keyData.chromaticLevels;
    chromaticDifficulty = cLevels[0] < 27 ? 1 : cLevels[1] < 37 ? 2 : 3;

    notifyListeners();
  }

  void startMode(TrainingMode mode, {String? overrideKey}) {
    final keyToUse = overrideKey ?? selectedKey;
    if (keyToUse == null) return;

    if (overrideKey != null) selectedKey = overrideKey;

    final diff = mode == TrainingMode.diatonic ? diatonicDifficulty : chromaticDifficulty;
    lastSession = {
      'key': keyToUse,
      'mode': mode.storageKey,
      'difficulty': diff,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _storage.saveLastSession(lastSession!);

    AnalyticsService.instance.capture('session_started', {
      'mode': mode.storageKey,
      'key': keyToUse,
      'difficulty': diff,
    });

    activeMode = mode;
    notifyListeners();
  }

  void startCustomMode({
    required List<String> degrees,
    required bool reverse,
    required int difficulty,
    required int questions,
    String? overrideKey,
  }) {
    if (overrideKey != null) selectedKey = overrideKey;
    if (selectedKey == null) return;
    customDegrees = degrees;
    isReverse = reverse;
    customDifficulty = difficulty;
    customQuestions = questions;
    lastSession = {
      'key': selectedKey,
      'mode': TrainingMode.custom.storageKey,
      'difficulty': difficulty,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _storage.saveLastSession(lastSession!);
    AnalyticsService.instance.capture('session_started', {
      'mode': TrainingMode.custom.storageKey,
      'key': selectedKey,
      'difficulty': difficulty,
      'reverse': reverse,
      'degrees': degrees.length,
    });
    activeMode = TrainingMode.custom;
    notifyListeners();
  }

  void startNoteToNumberMode({
    required List<String> degrees,
    int questions = 30,
    int difficulty = 1,
    String? overrideKey,
  }) {
    if (overrideKey != null) selectedKey = overrideKey;
    if (selectedKey == null) return;
    customDegrees = degrees;
    isReverse = true;
    customDifficulty = difficulty;
    customQuestions = questions;
    lastSession = {
      'key': selectedKey,
      'mode': TrainingMode.noteToNumber.storageKey,
      'difficulty': difficulty,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _storage.saveLastSession(lastSession!);
    AnalyticsService.instance.capture('session_started', {
      'mode': TrainingMode.noteToNumber.storageKey,
      'key': selectedKey,
      'difficulty': difficulty,
      'degrees': degrees.length,
    });
    activeMode = TrainingMode.noteToNumber;
    notifyListeners();
  }

  void exitTrainer() {
    _flushCurrentSession();
    activeMode = null;
    customDegrees = null;
    isReverse = null;
    customDifficulty = null;
    customQuestions = null;
    notifyListeners();
  }

  void _flushCurrentSession() {
    if (stats.currentSessionTotal == 0) return;
    final newSession = SessionRecord(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      correct: stats.currentSessionCorrect,
      total: stats.currentSessionTotal,
      answers: List.from(stats.currentSessionAnswers),
    );
    final newHistory = [newSession, ...stats.sessionHistory].take(300).toList();
    stats = stats.copyWith(
      sessionHistory: newHistory,
      currentSessionCorrect: 0,
      currentSessionTotal: 0,
      currentSessionAnswers: [],
    );
    _storage.saveStats(stats);
  }

  void recordAnswer({
    required bool isCorrect,
    required int responseTime,
    required AnswerRecord answerDetails,
  }) {
    final today = _dateKey(DateTime.now());
    final todayStats = stats.dailyHistory[today] ?? DayStats();
    final newDailyHistory = Map<String, DayStats>.from(stats.dailyHistory);
    newDailyHistory[today] = DayStats(
      attempts: todayStats.attempts + 1,
      correct: todayStats.correct + (isCorrect ? 1 : 0),
      responseTime: todayStats.responseTime + responseTime,
      sessions: todayStats.sessions,
    );

    stats = stats.copyWith(
      totalAttempts: stats.totalAttempts + 1,
      totalCorrect: stats.totalCorrect + (isCorrect ? 1 : 0),
      totalResponseTime: stats.totalResponseTime + responseTime,
      dailyHistory: newDailyHistory,
      currentSessionCorrect: stats.currentSessionCorrect + (isCorrect ? 1 : 0),
      currentSessionTotal: stats.currentSessionTotal + 1,
      currentSessionAnswers: [...stats.currentSessionAnswers, answerDetails],
    );

    // Update progress
    if (selectedKey != null && activeMode != null) {
      final mode = activeMode!;
      final diff = mode == TrainingMode.diatonic ? diatonicDifficulty : (customDifficulty ?? chromaticDifficulty);
      final currentCorrect = stats.currentSessionCorrect;

      progressData = progressData.map((item) {
        if (item.key != selectedKey) return item;

        final isD = mode == TrainingMode.diatonic;
        final levels = isD ? List<int>.from(item.diatonicLevels) : List<int>.from(item.chromaticLevels);
        final maxForLevel = diff == 1 ? 30 : diff == 2 ? 40 : 50;
        // Level = best correct-count reached this session, capped at the max.
        // (The old `clamp(level, currentCorrect)` threw whenever currentCorrect
        // was below the saved level — i.e. on the first answer of any key that
        // already had progress — which froze the game on question one.)
        final best = currentCorrect > levels[diff - 1] ? currentCorrect : levels[diff - 1];
        levels[diff - 1] = best > maxForLevel ? maxForLevel : best;

        return isD
            ? item.copyWith(diatonicLevels: levels)
            : item.copyWith(chromaticLevels: levels);
      }).toList();

      _storage.saveProgress(progressData);
      lastSession = {
        'key': selectedKey,
        'mode': mode.storageKey,
        'difficulty': diff,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _storage.saveLastSession(lastSession!);
    }

    _storage.saveStats(stats);
    notifyListeners();
  }

  void finishSession() {
    final today = _dateKey(DateTime.now());
    final todayStats = stats.dailyHistory[today] ?? DayStats();
    final newDailyHistory = Map<String, DayStats>.from(stats.dailyHistory);
    newDailyHistory[today] = DayStats(
      attempts: todayStats.attempts,
      correct: todayStats.correct,
      responseTime: todayStats.responseTime,
      sessions: todayStats.sessions + 1,
    );

    final newSession = SessionRecord(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      correct: stats.currentSessionCorrect,
      total: stats.currentSessionTotal,
      answers: List.from(stats.currentSessionAnswers),
    );
    final newHistory = [newSession, ...stats.sessionHistory].take(300).toList();

    stats = stats.copyWith(
      totalSessions: stats.totalSessions + 1,
      dailyHistory: newDailyHistory,
      sessionHistory: newHistory,
      currentSessionCorrect: 0,
      currentSessionTotal: 0,
      currentSessionAnswers: [],
    );
    _storage.saveStats(stats);
    notifyListeners();
  }

  void setIsPro(bool value) {
    isPro = value;
    _storage.saveIsPro(value);
    if (!value) {
      adaptiveDifficulty = false;
      _storage.saveAdaptiveDifficulty(false);
    }
    notifyListeners();
  }

  void setViewingKeyStats(bool value) {
    if (viewingKeyStats == value) return;
    viewingKeyStats = value;
    notifyListeners();
  }

  void setAdaptiveDifficulty(bool value) {
    adaptiveDifficulty = value;
    _storage.saveAdaptiveDifficulty(value);
    AnalyticsService.instance.capture('setting_changed', {'setting': 'adaptive_difficulty', 'value': value});
    notifyListeners();
  }

  void setNotation(String value) {
    notation = value;
    _storage.saveNotation(value);
    AnalyticsService.instance.capture('setting_changed', {'setting': 'notation', 'value': value});
    notifyListeners();
  }

  void setKeyboardFromTonic(bool value) {
    keyboardFromTonic = value;
    _storage.saveKeyboardFromTonic(value);
    AnalyticsService.instance.capture('setting_changed', {'setting': 'keyboard_from_tonic', 'value': value});
    notifyListeners();
  }

  void completeTutorial() {
    tutorialCompleted = true;
    _storage.saveTutorialCompleted(true);
    notifyListeners();
  }

  void setDiatonicDifficulty(int v) {
    diatonicDifficulty = v;
    notifyListeners();
  }

  void setChromaticDifficulty(int v) {
    chromaticDifficulty = v;
    notifyListeners();
  }

  void resetAll() {
    _storage.resetAll();
    progressData = _storage.loadProgress();
    stats = AppStats();
    lastSession = null;
    adaptiveDifficulty = false;
    tutorialCompleted = false;
    notifyListeners();
  }

  void showTutorialAgain() {
    tutorialCompleted = false;
    _storage.saveTutorialCompleted(false);
    notifyListeners();
  }

  // Debug helpers
  void debugMaxProgress() {
    progressData = progressData.map((k) => k.copyWith(
      diatonicLevels: [30, 40, 50],
      chromaticLevels: [30, 40, 50],
    )).toList();
    _storage.saveProgress(progressData);
    notifyListeners();
  }

  void debugNextAnimalLevel() {
    // Cycle Snail → Turtle → Penguin → Rabbit → Fox → Horse → Falcon → Cheetah
    // → back to Snail, advancing exactly one animal per tap. Each target sits
    // safely inside its level band so rounding never lands on the wrong animal.
    const targets = <int, double>{
      2: 15, 3: 28, 4: 40, 5: 53, 6: 65, 7: 78, 8: 90,
    };
    final current = animalLevel.level; // 1..8
    final next = current >= 8 ? 1 : current + 1;
    _setAllKeysToPercent(next == 1 ? 0 : targets[next]!);
  }

  // Sets every key's levels so each key — and therefore the overall average —
  // reaches the given total-progress percentage. Used by the debug level button.
  void _setAllKeysToPercent(double percent) {
    final targetPoints = (percent / 100 * 240).round(); // out of 240 per key
    const caps = [30, 40, 50, 30, 40, 50]; // diatonic l1,l2,l3 + chromatic l1,l2,l3
    final filled = List<int>.filled(6, 0);
    var rem = targetPoints;
    for (var i = 0; i < 6 && rem > 0; i++) {
      final add = rem < caps[i] ? rem : caps[i];
      filled[i] = add;
      rem -= add;
    }
    progressData = progressData
        .map((k) => k.copyWith(
              diatonicLevels: [filled[0], filled[1], filled[2]],
              chromaticLevels: [filled[3], filled[4], filled[5]],
            ))
        .toList();
    _storage.saveProgress(progressData);
    notifyListeners();
  }
}
