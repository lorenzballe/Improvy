import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/key_progress.dart';
import '../models/stats.dart';

class StorageService {
  static const _progressKey = 'musical_journey_progress';
  static const _statsKey = 'musical_journey_stats';
  static const _lastSessionKey = 'musical_journey_last_session';
  static const _adaptiveDiffKey = 'musical_journey_adaptive_difficulty';
  static const _tutorialKey = 'musical_journey_tutorial_completed';
  static const _isProKey = 'isPro';
  static const _notationKey = 'musical_journey_notation';

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

  // Settings
  bool loadAdaptiveDifficulty() => _prefs.getBool(_adaptiveDiffKey) ?? false;
  Future<void> saveAdaptiveDifficulty(bool v) => _prefs.setBool(_adaptiveDiffKey, v);

  bool loadTutorialCompleted() => _prefs.getBool(_tutorialKey) ?? false;
  Future<void> saveTutorialCompleted(bool v) => _prefs.setBool(_tutorialKey, v);

  bool loadIsPro() => _prefs.getBool(_isProKey) ?? false;
  Future<void> saveIsPro(bool v) => _prefs.setBool(_isProKey, v);

  String loadNotation() => _prefs.getString(_notationKey) ?? 'CDE';
  Future<void> saveNotation(String v) => _prefs.setString(_notationKey, v);

  Future<void> resetAll() async {
    await _prefs.remove(_progressKey);
    await _prefs.remove(_statsKey);
    await _prefs.remove(_lastSessionKey);
    await _prefs.remove(_adaptiveDiffKey);
    await _prefs.remove(_tutorialKey);
  }
}
