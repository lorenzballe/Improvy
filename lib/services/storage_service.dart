import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge.dart';
import '../models/key_progress.dart';
import '../models/stats.dart';

class StorageService {
  static const _progressKey = 'musical_journey_progress';
  static const _dailyResultsKey = 'daily_challenge_results';
  static const _dailyStartedKey = 'daily_challenge_started_date';
  static const _statsKey = 'musical_journey_stats';
  static const _lastSessionKey = 'musical_journey_last_session';
  static const _adaptiveDiffKey = 'musical_journey_adaptive_difficulty';
  static const _tutorialKey = 'musical_journey_tutorial_completed';
  static const _isProKey = 'isPro';
  static const _notationKey = 'musical_journey_notation';
  static const _simpleNotesKey = 'musical_journey_simple_notes';
  static const _answerSoundKey = 'musical_journey_answer_sound';
  static const _keyboardFromTonicKey = 'musical_journey_keyboard_from_tonic';
  static const _pendingKey = 'musical_journey_pending_session';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Progress
  List<KeyProgress> loadProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return _defaultProgress();
    try {
      final list = jsonDecode(raw) as List;
      final saved = list.map((e) => KeyProgress.fromJson(e as Map<String, dynamic>)).toList();
      return kDefaultKeyOrder.map((key) {
        final found = saved.firstWhere((k) => k.key == key, orElse: () => KeyProgress(key: key));
        return found;
      }).toList();
    } catch (_) {
      return _defaultProgress();
    }
  }

  List<KeyProgress> _defaultProgress() {
    return kDefaultKeyOrder.map((k) => KeyProgress(key: k)).toList();
  }

  Future<void> saveProgress(List<KeyProgress> progress) async {
    await _prefs.setString(_progressKey, jsonEncode(progress.map((p) => p.toJson()).toList()));
  }

  // Stats
  AppStats loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return AppStats();
    try {
      return AppStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppStats();
    }
  }

  Future<void> saveStats(AppStats stats) async {
    await _prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  // Lightweight per-answer snapshot — lifetime counters + dailyHistory + the
  // in-progress session, but NOT the heavy sessionHistory list. Written after
  // every answer so an OS-kill mid-game loses nothing; cheap because it omits
  // the (up to 300-game) history that made a full saveStats janky per tap.
  Future<void> savePending(AppStats s) async {
    await _prefs.setString(_pendingKey, jsonEncode({
      'totalSessions': s.totalSessions,
      'totalAttempts': s.totalAttempts,
      'totalCorrect': s.totalCorrect,
      'totalResponseTime': s.totalResponseTime,
      'dailyHistory': s.dailyHistory.map((k, v) => MapEntry(k, v.toJson())),
      'currentSessionCorrect': s.currentSessionCorrect,
      'currentSessionTotal': s.currentSessionTotal,
      'currentSessionAnswers': s.currentSessionAnswers.map((a) => a.toJson()).toList(),
    }));
  }

  Map<String, dynamic>? loadPending() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> removePending() => _prefs.remove(_pendingKey);

  // Last session
  Map<String, dynamic>? loadLastSession() {
    final raw = _prefs.getString(_lastSessionKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastSession(Map<String, dynamic> session) async {
    await _prefs.setString(_lastSessionKey, jsonEncode(session));
  }

  Future<void> removeLastSession() async {
    await _prefs.remove(_lastSessionKey);
  }

  // Daily Challenge — one result per date key, kept forever (a year of play is
  // a few tens of KB; the calendar and the streak both read from it).
  Map<String, DailyResult> loadDailyResults() {
    final raw = _prefs.getString(_dailyResultsKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, DailyResult.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDailyResults(Map<String, DailyResult> results) async {
    await _prefs.setString(
        _dailyResultsKey, jsonEncode(results.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // Set the moment a daily run starts, cleared when its result lands. If the
  // app is killed mid-run, launch finds it and burns the attempt from the
  // pending answers — force-quitting must not grant a second try.
  String? loadDailyAttemptStarted() => _prefs.getString(_dailyStartedKey);
  Future<void> saveDailyAttemptStarted(String dateKey) =>
      _prefs.setString(_dailyStartedKey, dateKey);
  Future<void> removeDailyAttemptStarted() => _prefs.remove(_dailyStartedKey);

  // Settings
  bool loadAdaptiveDifficulty() => _prefs.getBool(_adaptiveDiffKey) ?? false;
  Future<void> saveAdaptiveDifficulty(bool v) => _prefs.setBool(_adaptiveDiffKey, v);

  bool loadTutorialCompleted() => _prefs.getBool(_tutorialKey) ?? false;
  Future<void> saveTutorialCompleted(bool v) => _prefs.setBool(_tutorialKey, v);

  bool loadIsPro() => _prefs.getBool(_isProKey) ?? false;
  Future<void> saveIsPro(bool v) => _prefs.setBool(_isProKey, v);

  /// Null when the user has never chosen: the provider then picks by
  /// language on first run.
  String? loadNotationOrNull() => _prefs.getString(_notationKey);
  String loadNotation() => _prefs.getString(_notationKey) ?? 'CDE';
  Future<void> saveNotation(String v) => _prefs.setString(_notationKey, v);

  bool loadSimpleNotes() => _prefs.getBool(_simpleNotesKey) ?? false;
  Future<void> saveSimpleNotes(bool v) => _prefs.setBool(_simpleNotesKey, v);

  /// On by default: the note is the lesson, and nobody should have to find a
  /// switch to get it. The switch exists for practising somewhere quiet.
  bool loadAnswerSound() => _prefs.getBool(_answerSoundKey) ?? true;
  Future<void> saveAnswerSound(bool v) => _prefs.setBool(_answerSoundKey, v);

  bool loadKeyboardFromTonic() => _prefs.getBool(_keyboardFromTonicKey) ?? false;
  Future<void> saveKeyboardFromTonic(bool v) => _prefs.setBool(_keyboardFromTonicKey, v);

  // Notifications — whether the OS permission prompt (via our priming sheet)
  // was already shown, plus the user's reminder preferences (default ON).
  /// Version whose What's New sheet the user has already read. Null on a device
  /// that has never run a build carrying this key — which is both a fresh
  /// install and an upgrade from an older build, so the caller distinguishes
  /// the two by whether there is any history (see AppProvider.initReleaseNotes).
  String? loadLastSeenVersion() => _prefs.getString('last_seen_version');
  Future<void> saveLastSeenVersion(String v) => _prefs.setString('last_seen_version', v);

  bool loadNotifPermAsked() => _prefs.getBool('notif_perm_asked') ?? false;
  Future<void> saveNotifPermAsked(bool v) => _prefs.setBool('notif_perm_asked', v);

  bool loadNotifDailyOn() => _prefs.getBool('notif_daily_on') ?? true;
  Future<void> saveNotifDailyOn(bool v) => _prefs.setBool('notif_daily_on', v);

  bool loadNotifComebackOn() => _prefs.getBool('notif_comeback_on') ?? true;
  Future<void> saveNotifComebackOn(bool v) => _prefs.setBool('notif_comeback_on', v);

  int loadNotifHour() => _prefs.getInt('notif_hour') ?? 19;
  int loadNotifMinute() => _prefs.getInt('notif_minute') ?? 0;
  Future<void> saveNotifTime(int h, int m) async {
    await _prefs.setInt('notif_hour', h);
    await _prefs.setInt('notif_minute', m);
  }

  // ── Backup ─────────────────────────────────────────────────────────────────
  //
  // Every key this service owns, by name. The export is the raw preference
  // values, not the models: it survives a model gaining a field, and it
  // cannot lose anything the app has not yet learned to read.
  static const _backupKeys = [
    _progressKey, _dailyResultsKey, _dailyStartedKey, _statsKey,
    _lastSessionKey, _adaptiveDiffKey, _tutorialKey, _notationKey,
    _simpleNotesKey, _answerSoundKey, _keyboardFromTonicKey,
    'last_seen_version', 'notif_perm_asked', 'notif_daily_on',
    'notif_comeback_on', 'notif_hour', 'notif_minute',
  ];

  /// Increment when the export shape changes in a way an older app could not
  /// read. Readers refuse a newer major rather than guess.
  static const backupFormat = 1;

  /// The whole of a player's progress and settings as one JSON document.
  /// Pro status is deliberately NOT included: it belongs to the store account,
  /// not the file, and is restored by "Restore purchases".
  String exportJson() {
    final data = <String, Object?>{};
    for (final k in _backupKeys) {
      final v = _prefs.get(k);
      if (v != null) data[k] = v;
    }
    return jsonEncode({
      'app': 'improvy',
      'format': backupFormat,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
  }

  /// Replaces the stored progress and settings with [json]. Throws
  /// [FormatException] on anything that is not an Improvy backup, and
  /// writes nothing in that case — a bad file must not half-restore.
  Future<void> importJson(String json) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const FormatException('not a JSON file');
    }
    if (decoded is! Map || decoded['app'] != 'improvy') {
      throw const FormatException('not an Improvy backup');
    }
    final format = decoded['format'];
    if (format is! int || format > backupFormat) {
      throw const FormatException('made by a newer version of Improvy');
    }
    final data = decoded['data'];
    if (data is! Map) throw const FormatException('backup has no data');

    // Validate every value before touching a single key.
    for (final k in _backupKeys) {
      final v = data[k];
      if (v == null) continue;
      if (v is! String && v is! bool && v is! int) {
        throw FormatException('unexpected value for $k');
      }
    }
    for (final k in _backupKeys) {
      final v = data[k];
      if (v == null) {
        await _prefs.remove(k);
      } else if (v is String) {
        await _prefs.setString(k, v);
      } else if (v is bool) {
        await _prefs.setBool(k, v);
      } else if (v is int) {
        await _prefs.setInt(k, v);
      }
    }
  }

  Future<void> resetAll() async {
    await _prefs.remove(_progressKey);
    await _prefs.remove(_statsKey);
    await _prefs.remove(_lastSessionKey);
    await _prefs.remove(_adaptiveDiffKey);
    await _prefs.remove(_tutorialKey);
    await _prefs.remove(_pendingKey);
    await _prefs.remove(_dailyResultsKey);
    await _prefs.remove(_dailyStartedKey);
  }
}
