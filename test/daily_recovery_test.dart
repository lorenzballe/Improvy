import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';

/// Force-quitting the app in the middle of the daily must not be a free
/// retry. The run's start is flagged on disk and its answers are in the
/// per-answer snapshot; launch turns the two into today's result.
///
/// The filter that picked the run's answers out of the snapshot asked for
/// DIATONIC answers — a direction the daily has never run — so it matched
/// nothing, the flag was cleared, and the card offered the day again.
void main() {
  String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> answer(DailyChallenge c, int i, bool correct) => {
        'degree': c.degrees[i],
        'note': 'C',
        'selectedNote': correct ? 'C' : 'D',
        'tonality': c.key,
        'mode': c.mode.storageKey,
        'isReverse': c.mode.storageKey == 'note-to-number',
        'difficulty': DailyChallenge.difficulty,
        'responseTime': 1500,
        'isCorrect': correct,
        'timestamp': 1000 + i,
      };

  Future<AppProvider> launchAfterKill(DailyChallenge c, int answered, int right) async {
    SharedPreferences.setMockInitialValues({
      'daily_challenge_started_date': c.dateKey,
      'musical_journey_pending_session': jsonEncode({
        'totalAttempts': answered,
        'totalCorrect': right,
        'totalResponseTime': answered * 1500,
        'dailyHistory': <String, dynamic>{},
        'currentSessionCorrect': right,
        'currentSessionTotal': answered,
        'currentSessionAnswers': [
          for (var i = 0; i < answered; i++) answer(c, i, i < right),
        ],
      }),
    });
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    return provider;
  }

  test('a daily killed mid-run is burned with what was answered', () async {
    final today = DateTime.now();
    final c = DailyChallenge.forDate(today);
    final p = await launchAfterKill(c, 6, 4);

    final result = p.dailyResults[dateKey(today)];
    expect(result, isNotNull, reason: 'the attempt survived the kill');
    expect(result!.correct, 4);
    expect(result.total, DailyChallenge.questionCount,
        reason: 'unanswered questions are misses, the grid stays full width');
    expect(result.completed, isFalse);
    expect(result.mode, c.mode);
    expect(p.storage.loadDailyAttemptStarted(), isNull);
  });

  test('every direction the daily rotates through is recovered', () async {
    // Walk forward until each of the three directions has been drawn once.
    final seen = <String>{};
    var day = DateTime.now();
    var guard = 0;
    while (seen.length < DailyChallenge.modes.length && guard++ < 60) {
      final c = DailyChallenge.forDate(day);
      if (seen.add(c.mode.storageKey)) {
        final p = await launchAfterKill(c, 3, 3);
        expect(p.dailyResults[c.dateKey], isNotNull,
            reason: '${c.mode.storageKey} on ${c.dateKey} was not recovered');
        expect(p.dailyResults[c.dateKey]!.correct, 3);
      }
      day = day.add(const Duration(days: 1));
    }
    expect(seen.length, DailyChallenge.modes.length);
  });

  test('killed before the first answer, the attempt survives', () async {
    final c = DailyChallenge.forDate(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'daily_challenge_started_date': c.dateKey,
    });
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    expect(p.dailyResults[c.dateKey], isNull);
    expect(p.storage.loadDailyAttemptStarted(), isNull);
  });
}
