import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/key_progress.dart';
import '../models/stats.dart';
import '../models/training_mode.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../constants/levels.dart';
import '../constants/music_constants.dart';

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

  // Notification preferences (persisted; default ON). [notifHour]/[notifMinute]
  // are the daily reminder's wall-clock slot, user-chosen in Settings.
  bool notifDailyOn = true;
  bool notifComebackOn = true;
  int notifHour = 19;
  int notifMinute = 0;
  // True while the pre-permission priming sheet should be shown (set after the
  // first finished game). The UI reads it and asks the OS only if the user opts
  // in, so a "Don't Allow" never blindly burns the one-shot iOS permission.
  bool showNotifPrompt = false;

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
  // "…Of What?" mode: the fixed melody note held for the whole session (the
  // degree rotates and the root is the answer).
  String? fixedNote;

  Future<void> init() async {
    progressData = _storage.loadProgress();
    stats = _storage.loadStats();
    isPro = _storage.loadIsPro();
    adaptiveDifficulty = _storage.loadAdaptiveDifficulty();
    tutorialCompleted = _storage.loadTutorialCompleted();
    notation = _storage.loadNotation();
    keyboardFromTonic = _storage.loadKeyboardFromTonic();
    notifDailyOn = _storage.loadNotifDailyOn();
    notifComebackOn = _storage.loadNotifComebackOn();
    notifHour = _storage.loadNotifHour();
    notifMinute = _storage.loadNotifMinute();
    lastSession = _storage.loadLastSession();
    _recoverPendingSession();
    resyncNotifications();
    notifyListeners();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  // Rebuilds the pending local notifications from the freshest stats. Called
  // on launch and at session end, so reminders always reflect reality (e.g.
  // today's nudge vanishes after play). No user-facing settings by design:
  // daily reminder fixed at 19:00, comeback nudges always on — the OS
  // notification permission is the only switch.
  void resyncNotifications() {
    final today = _dateKey(DateTime.now());
    NotificationService.resync(ReminderPlan(
      dailyOn: notifDailyOn,
      hour: notifHour,
      minute: notifMinute,
      comebackOn: notifComebackOn,
      playedToday: (stats.dailyHistory[today]?.attempts ?? 0) > 0,
      lastPlayedMs: stats.sessionHistory.isNotEmpty ? stats.sessionHistory.first.timestamp : null,
      streak: streak,
      dailyMessages: _dailyMessages(),
      streakSaveMessage: _streakSaveMessage(),
    ));
  }

  void setNotifDailyOn(bool v) {
    notifDailyOn = v;
    _storage.saveNotifDailyOn(v);
    resyncNotifications();
    notifyListeners();
  }

  void setNotifComebackOn(bool v) {
    notifComebackOn = v;
    _storage.saveNotifComebackOn(v);
    resyncNotifications();
    notifyListeners();
  }

  void setNotifTime(int hour, int minute) {
    notifHour = hour;
    notifMinute = minute;
    _storage.saveNotifTime(hour, minute);
    resyncNotifications();
    notifyListeners();
  }

  /// Fire a sample question notification immediately (debug "test" button).
  void sendTestNotification() {
    final m = _dailyMessages();
    NotificationService.showTestNow(
        m.isNotEmpty ? m.first : ('Improvy 🎹', 'Time to practise?'));
  }

  static String _ordinal(int n) => n == 2 ? '2nd' : n == 3 ? '3rd' : '${n}th';

  // The rotating daily pool: mostly degree-recall quiz questions (the app's
  // essence — they make you open the app to check yourself), plus a targeted
  // weak-spot nudge, a level-progress nudge, and a couple of evergreens.
  List<ReminderMessage> _dailyMessages() {
    final rng = Random();
    final msgs = <ReminderMessage>[];

    final weak = _weakSpotMessage();
    if (weak != null) msgs.add(('Target practice 🎯', weak));

    for (var i = 0; i < 5; i++) {
      final key = kKeys[rng.nextInt(kKeys.length)];
      final deg = 2 + rng.nextInt(6); // 2..7 (the 1 is trivial)
      msgs.add(('Quick quiz 🎹', "What's the ${_ordinal(deg)} of $key major? Tap to check."));
    }

    final a = animalLevel;
    final p = totalProgress;
    const thresholds = [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0];
    double? toNext;
    for (final t in thresholds) {
      if (p < t) { toNext = t - p; break; }
    }
    msgs.add(toNext != null
        ? ('${a.name} ${a.emoji}', "You're ${toNext.toStringAsFixed(1)}% from levelling up. Close the gap?")
        : ('${a.name} ${a.emoji}', 'Maxed out — keep those reflexes razor-sharp.'));

    msgs.add(('Improvy 🎹', 'Every degree, every key, instantly. Got 3 minutes?'));
    msgs.add(('Ear training 🎧', 'Fast recall beats slow theory. Quick session?'));
    return msgs;
  }

  // Loss-framed nudge for TODAY only: fires when a streak of 2+ will break
  // tonight unless the user plays. Null otherwise (nothing to protect).
  ReminderMessage? _streakSaveMessage() {
    final today = _dateKey(DateTime.now());
    final playedToday = (stats.dailyHistory[today]?.attempts ?? 0) > 0;
    final s = streak;
    if (s >= 2 && !playedToday) {
      return ("Don't break your streak! 🔥",
          'Your $s-day streak ends tonight — 2 minutes to keep it alive.');
    }
    return null;
  }

  // The single most frequent recurring confusion of the last 30 games — the
  // same pairs Common Confusions shows — phrased as a nudge. Null when no
  // pair reaches 3 occurrences: a weak-spot notification must be sure of
  // itself or stay silent.
  String? _weakSpotMessage() {
    final counts = <String, int>{};
    for (final s in stats.sessionHistory.take(30)) {
      for (final a in s.answers) {
        if (a.isCorrect || a.selectedNote.isEmpty) continue;
        // "…Of What?" answers are about roots, not degrees inside a key —
        // their `tonality` is a fixed note, so they'd produce nonsense pairs.
        if (a.mode == 'of-what') continue;
        final asked = romanDegree(a.degree);
        final selSemi = kNoteToSemitone[a.selectedNote.split('/')[0].trim()];
        final rootSemi = kNoteToSemitone[a.tonality];
        if (asked.isEmpty || selSemi == null || rootSemi == null) continue;
        final played = kFlatRomanBySemitone[((selSemi - rootSemi) % 12 + 12) % 12];
        if (played == asked) continue;
        final key = '${a.tonality}|$asked|$played';
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    MapEntry<String, int>? top;
    for (final e in counts.entries) {
      if (e.value >= 3 && (top == null || e.value > top.value)) top = e;
    }
    if (top == null) return null;
    final parts = top.key.split('|');
    return 'You keep mixing up ${parts[1]} and ${parts[2]} in ${parts[0]} major. '
        '10 questions to nail it?';
  }

  // First finished game → show the priming sheet once. The OS permission dialog
  // is only fired if the user opts in there (acceptNotifPrompt), so a decline
  // never blindly burns the one-shot iOS permission.
  void _ensureNotifPermission() {
    if (_storage.loadNotifPermAsked()) return;
    showNotifPrompt = true;
    notifyListeners();
  }

  void acceptNotifPrompt() {
    showNotifPrompt = false;
    _storage.saveNotifPermAsked(true);
    NotificationService.requestPermission().then((_) => resyncNotifications());
    notifyListeners();
  }

  void dismissNotifPrompt() {
    showNotifPrompt = false;
    _storage.saveNotifPermAsked(true);
    notifyListeners();
  }

  // If the app was killed mid-game, a lightweight snapshot of the in-progress
  // session was persisted after every answer. Fold it back in on launch so
  // nothing is lost: sessionHistory is kept as loaded from disk, the fresher
  // volatile fields come from the snapshot, then the recovered session is
  // finalised with the same rule as a manual abandon.
  void _recoverPendingSession() {
    final p = _storage.loadPending();
    if (p == null) return;
    final answers = (p['currentSessionAnswers'] as List?)
            ?.map((a) => AnswerRecord.fromJson(a as Map<String, dynamic>))
            .toList() ??
        <AnswerRecord>[];
    if (answers.isEmpty) {
      _storage.removePending();
      return;
    }
    // Guard against the rare race where finishSession persisted the full stats
    // but the pending-clear didn't land before a kill: if this exact session
    // is already the newest in history, it was folded — just drop the snapshot.
    final newest = stats.sessionHistory.isNotEmpty ? stats.sessionHistory.first : null;
    final alreadyFolded = newest != null &&
        newest.answers.isNotEmpty &&
        newest.total == answers.length &&
        newest.answers.first.timestamp == answers.first.timestamp;
    if (alreadyFolded) {
      _storage.removePending();
      return;
    }
    final daily = (p['dailyHistory'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, DayStats.fromJson(v as Map<String, dynamic>)),
        ) ??
        stats.dailyHistory;
    stats = stats.copyWith(
      totalAttempts: (p['totalAttempts'] as num?)?.toInt() ?? stats.totalAttempts,
      totalCorrect: (p['totalCorrect'] as num?)?.toInt() ?? stats.totalCorrect,
      totalResponseTime: (p['totalResponseTime'] as num?)?.toInt() ?? stats.totalResponseTime,
      dailyHistory: daily,
      currentSessionCorrect: (p['currentSessionCorrect'] as num?)?.toInt() ?? 0,
      currentSessionTotal: (p['currentSessionTotal'] as num?)?.toInt() ?? 0,
      currentSessionAnswers: answers,
    );
    // Same rule as a manual abandon: >=5 answers becomes a counted game,
    // fewer is dropped from game history (its answers still live in the
    // lifetime + daily totals). Also persists the merge and clears the snapshot.
    _flushCurrentSession();
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

  // "…Of What?" — a fixed melody [note], the degree rotates each question, the
  // answer is the root. Not tied to a key; reuses customDegrees/customQuestions.
  void startOfWhatMode({
    required String note,
    required List<String> degrees,
    int questions = 30,
    int difficulty = 1,
  }) {
    fixedNote = note;
    customDegrees = degrees;
    isReverse = false;
    customDifficulty = difficulty;
    customQuestions = questions;
    lastSession = {
      'key': note,
      'mode': TrainingMode.ofWhat.storageKey,
      'difficulty': difficulty,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _storage.saveLastSession(lastSession!);
    AnalyticsService.instance.capture('session_started', {
      'mode': TrainingMode.ofWhat.storageKey,
      'note': note,
      'difficulty': difficulty,
      'degrees': degrees.length,
    });
    activeMode = TrainingMode.ofWhat;
    notifyListeners();
  }

  /// Pocket Mode runs outside the tap-game engine, but should still surface in
  /// "Pick Up Where You Left Off" — record it as the last session on start.
  void recordPocketSession({required String key, required bool shuffle}) {
    lastSession = {
      'key': shuffle ? '' : key,
      'mode': TrainingMode.pocket.storageKey,
      'pocketShuffle': shuffle,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _storage.saveLastSession(lastSession!);
    notifyListeners();
  }

  void exitTrainer() {
    _flushCurrentSession();
    activeMode = null;
    customDegrees = null;
    isReverse = null;
    customDifficulty = null;
    customQuestions = null;
    fixedNote = null;
    // Covers the abandoned-run path too (playedToday may have changed even
    // when the run was too short to count as a game).
    resyncNotifications();
    notifyListeners();
  }

  void _flushCurrentSession() {
    final answered = stats.currentSessionTotal;
    if (answered == 0) { _storage.removePending(); return; }
    // A run abandoned after just a few answers is not a game: recording it
    // would pollute the "last 30 games" charts while Total Sessions and Games
    // Played ignore it. Below 5 answers the run is dropped (its answers still
    // count toward lifetime practice totals); from 5 answers up an abandoned
    // run counts as a full game everywhere, exactly like a finished one.
    if (answered < 5) {
      stats = stats.copyWith(
        currentSessionCorrect: 0,
        currentSessionTotal: 0,
        currentSessionAnswers: [],
      );
      _storage.saveStats(stats);
      _storage.removePending();
      return;
    }
    finishSession();
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

    // Update key mastery — ONLY for the two standard modes. Custom and
    // Note→Number sessions can be narrowed to a hand-picked (even single)
    // degree, so counting them would let easy drills inflate a key's mastery;
    // they remain free practice: recorded in stats, invisible to progression.
    if (selectedKey != null &&
        (activeMode == TrainingMode.diatonic || activeMode == TrainingMode.chromatic)) {
      final mode = activeMode!;
      final diff = mode == TrainingMode.diatonic ? diatonicDifficulty : chromaticDifficulty;
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
    }

    // Persist a LIGHT snapshot every answer — lifetime counters, dailyHistory
    // and the in-progress session, but NOT the heavy sessionHistory list. So an
    // OS-kill mid-game loses nothing (init folds the snapshot back in), while
    // the multi-MB history is still serialised only once, at session end — the
    // per-tap jank the full save caused is gone.
    _storage.savePending(stats);
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
    // Full save (history included) happens once here, at session end; the
    // in-progress snapshot is now stale, so drop it.
    _storage.saveStats(stats);
    _storage.removePending();
    // First finished game = the moment of proven value — the right time to
    // ask for notification permission (never as a cold-start popup). But only
    // on a good score: primed right after a rough game (say two errors and a
    // quit), the answer would be a reflex "no". A bad first game doesn't burn
    // the prompt — the next good one asks instead.
    final accuracy = newSession.total > 0 ? newSession.correct / newSession.total : 0.0;
    if (accuracy >= 0.7) _ensureNotifPermission();
    resyncNotifications();
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
