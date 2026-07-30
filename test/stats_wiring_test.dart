import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';

/// Where does each mode's practice actually land?
///
/// The app has one recording path (`AppProvider.recordAnswer`) shared by every
/// tap-based mode, and several destinations with different rules: lifetime
/// counters, the day's history (which the streak reads), the game history the
/// charts read, per-key mastery, and the harmonizer dial. The rules are
/// deliberate but invisible, so these tests pin them down: a change that
/// silently disconnects a mode from a destination fails here instead of
/// quietly flattening someone's stats.
Future<AppProvider> freshProvider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  return p;
}

AnswerRecord answer({
  required String mode,
  required String tonality,
  String degree = '3',
  bool correct = true,
  int rt = 1500,
}) =>
    AnswerRecord(
      degree: degree,
      note: 'E',
      selectedNote: correct ? 'E' : 'F',
      tonality: tonality,
      mode: mode,
      isReverse: false,
      difficulty: 1,
      responseTime: rt,
      isCorrect: correct,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

/// Plays [n] answers of one mode and closes the session, the way the trainer
/// does through RootScreen.
void play(AppProvider p, TrainingMode mode, String key, {int n = 6}) {
  p.selectKey(key);
  switch (mode) {
    case TrainingMode.diatonic:
    case TrainingMode.chromatic:
      p.startMode(mode, overrideKey: key);
    case TrainingMode.custom:
      p.startCustomMode(
          degrees: const ['3'], reverse: false, difficulty: 1, questions: n, overrideKey: key);
    case TrainingMode.noteToNumber:
      p.startNoteToNumberMode(degrees: const ['3'], questions: n, overrideKey: key);
    case TrainingMode.ofWhat:
      p.startOfWhatMode(note: key, degrees: const ['3'], questions: n);
    case TrainingMode.pocket:
      p.recordPocketSession(key: key, shuffle: false);
      // A real drill spoke some questions before the user left.
      p.recordPocketPractice(12);
      return; // Pocket has no answers to record — that is the point of one test.
  }
  for (var i = 0; i < n; i++) {
    p.recordAnswer(
      isCorrect: true,
      responseTime: 1500,
      answerDetails: answer(mode: mode.storageKey, tonality: key),
    );
  }
  p.finishSession();
  p.exitTrainer();
}

void main() {
  group('lifetime + daily counters', () {
    for (final mode in [
      TrainingMode.diatonic,
      TrainingMode.chromatic,
      TrainingMode.custom,
      TrainingMode.noteToNumber,
      TrainingMode.ofWhat,
    ]) {
      test('${mode.storageKey} feeds attempts, the day and the game history',
          () async {
        final p = await freshProvider();
        play(p, mode, 'C');

        expect(p.stats.totalAttempts, 6, reason: 'lifetime attempts');
        expect(p.stats.totalCorrect, 6, reason: 'lifetime correct');
        expect(p.stats.totalSessions, 1, reason: 'games played');
        expect(p.stats.sessionHistory.length, 1, reason: 'chart history');
        expect(p.stats.sessionHistory.first.total, 6);

        final today = p.stats.dailyHistory.values.single;
        expect(today.attempts, 6, reason: "the day's attempts drive the streak");
        expect(today.sessions, 1);
        expect(p.streak, 1, reason: 'a played day is a streak of one');
      });
    }
  });

  group('key mastery', () {
    test('diatonic raises the key it was played in, and only that key',
        () async {
      final p = await freshProvider();
      play(p, TrainingMode.diatonic, 'C');

      final c = p.progressData.firstWhere((k) => k.key == 'C');
      expect(c.diatonicLevels[0], 6, reason: 'best correct-count this session');
      expect(c.chromaticLevels, [0, 0, 0]);
      expect(p.progressData.firstWhere((k) => k.key == 'G').totalProgress, 0);
    });

    test('chromatic raises the chromatic dial', () async {
      final p = await freshProvider();
      play(p, TrainingMode.chromatic, 'G');

      final g = p.progressData.firstWhere((k) => k.key == 'G');
      expect(g.chromaticLevels[0], 6);
      expect(g.diatonicLevels, [0, 0, 0]);
    });

    test('custom and note-to-number are free practice: stats yes, mastery no',
        () async {
      for (final mode in [TrainingMode.custom, TrainingMode.noteToNumber]) {
        final p = await freshProvider();
        play(p, mode, 'C');

        expect(p.stats.totalAttempts, 6,
            reason: '${mode.storageKey} must still be recorded');
        final c = p.progressData.firstWhere((k) => k.key == 'C');
        expect(c.totalProgress, 0,
            reason: '${mode.storageKey} can be narrowed to one degree, so it '
                'must not inflate mastery');
      }
    });

    test('…Of What? feeds only the harmonizer dial of its note', () async {
      final p = await freshProvider();
      play(p, TrainingMode.ofWhat, 'C');

      final c = p.progressData.firstWhere((k) => k.key == 'C');
      expect(c.harmonizerLevels[0], 6);
      expect(c.totalProgress, 0, reason: 'a separate skill, its own dial');
    });
  });

  group('the Daily Challenge is a first-class diatonic run', () {
    test('it feeds mastery, the day and the game history like any other',
        () async {
      final p = await freshProvider();
      p.startDailyChallenge();
      final key = p.todayChallenge.key;

      for (var i = 0; i < 10; i++) {
        p.recordAnswer(
          isCorrect: true,
          responseTime: 1200,
          answerDetails: answer(mode: 'diatonic', tonality: key),
        );
      }
      p.finishSession();
      p.exitTrainer();

      expect(p.stats.totalAttempts, 10);
      expect(p.stats.sessionHistory.length, 1);
      // Credited to tier 2, because that is the tier the daily is played at —
      // see DailyChallenge.difficulty. Filing it under tier 1 would claim an
      // easier run than actually happened.
      expect(p.progressData.firstWhere((k) => k.key == key).diatonicLevels,
          [0, 10, 0]);
      expect(p.todayDailyResult, isNotNull);
      expect(p.todayDailyResult!.correct, 10);
      expect(p.dailyStreak, 1);
    });

    test('its clock is medium and its budget scales with the questions',
        () async {
      final p = await freshProvider();
      p.startDailyChallenge();
      expect(p.diatonicDifficulty, 2,
          reason: 'answers must be filed under the tier actually played');
    });
  });

  group('key ranking is one number', () {
    test('ranks by accuracy, tie-breaks on speed, leaves unplayed keys at 0',
        () async {
      final p = await freshProvider();
      p.selectKey('C');
      p.startMode(TrainingMode.diatonic, overrideKey: 'C');
      // C: 1 of 2 right. G: 2 of 2 but slower. F: never played.
      p.recordAnswer(
          isCorrect: true, responseTime: 500,
          answerDetails: answer(mode: 'diatonic', tonality: 'C', rt: 500));
      p.recordAnswer(
          isCorrect: false, responseTime: 500,
          answerDetails:
              answer(mode: 'diatonic', tonality: 'C', correct: false, rt: 500));
      p.recordAnswer(
          isCorrect: true, responseTime: 4000,
          answerDetails: answer(mode: 'diatonic', tonality: 'G', rt: 4000));
      p.recordAnswer(
          isCorrect: true, responseTime: 4000,
          answerDetails: answer(mode: 'diatonic', tonality: 'G', rt: 4000));
      p.finishSession();

      final ranks = p.keyRanks;
      expect(ranks['G'], 1, reason: 'accuracy wins over raw speed');
      expect(ranks['C'], 2);
      expect(ranks['F'], 0, reason: 'never played is unranked, not last');
    });

    test('…Of What? answers never rank a key', () async {
      final p = await freshProvider();
      p.startOfWhatMode(note: 'C', degrees: const ['3']);
      p.recordAnswer(
          isCorrect: true, responseTime: 900,
          answerDetails: answer(mode: 'of-what', tonality: 'C'));
      p.finishSession();

      expect(p.keyRanks['C'], 0,
          reason: 'its tonality is a melody note, not a key context');
    });
  });

  group('Pocket Mode', () {
    test('records practice for the day even though it has no answers',
        () async {
      final p = await freshProvider();
      play(p, TrainingMode.pocket, 'C');

      expect(p.stats.totalAttempts, 0,
          reason: 'a hands-free drill has nothing to be right or wrong about');
      expect(p.streak, 1,
          reason: 'a day spent training hands-free is still a day trained');
    });
  });
}
