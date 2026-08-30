import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/key_progress.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/daily_challenge.dart';
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
  String? selected,
}) =>
    AnswerRecord(
      degree: degree,
      note: 'E',
      selectedNote: selected ?? (correct ? 'E' : 'F'),
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
      expect(p.progressData.firstWhere((k) => k.key == 'G').normalProgress, 0);
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
        expect(c.normalProgress, 0,
            reason: '${mode.storageKey} can be narrowed to one degree, so it '
                'must not inflate mastery');
      }
    });

    test('…Of What? feeds only the harmonizer dial of its note', () async {
      final p = await freshProvider();
      play(p, TrainingMode.ofWhat, 'C');

      final c = p.progressData.firstWhere((k) => k.key == 'C');
      expect(c.harmonizerLevels[0], 6);
      expect(c.normalProgress, 0, reason: 'a separate skill, its own dial');
    });
  });

  group('the Daily Challenge is a first-class run', () {
    // A chromatic run dated today. The daily now rotates through three
    // directions, so reading whichever one today happens to draw would make
    // these pass or fail depending on the date they are run — while a past
    // date would file the result under a day that is not "today", which is
    // what the streak and todayDailyResult are asking about.
    DailyChallenge chromaticToday(AppProvider p) {
      for (var d = 0; d < 365; d++) {
        final c = DailyChallenge.forDate(DateTime(2026, 1, 1).add(Duration(days: d)));
        if (c.mode != TrainingMode.chromatic) continue;
        return DailyChallenge(
          dateKey: p.todayChallenge.dateKey,
          key: c.key,
          degrees: c.degrees,
          mode: c.mode,
        );
      }
      throw StateError('no chromatic day in 2026');
    }

    test('it feeds mastery, the day and the game history like any other',
        () async {
      final p = await freshProvider();
      final c = chromaticToday(p);
      p.startDailyChallenge(challenge: c);
      final key = c.key;

      const played = DailyChallenge.questionCount;
      for (var i = 0; i < played; i++) {
        p.recordAnswer(
          isCorrect: true,
          responseTime: 1200,
          answerDetails: answer(mode: 'chromatic', tonality: key),
        );
      }
      p.finishSession();
      p.exitTrainer();

      expect(p.stats.totalAttempts, played);
      expect(p.stats.sessionHistory.length, 1);
      // Chromatic, because the daily asks chromatic degrees and so runs as a
      // chromatic session — crediting the diatonic dial would claim progress
      // on a mode that was never played. Tier 2, because that is the tier the
      // daily is played at (DailyChallenge.difficulty).
      expect(p.progressData.firstWhere((k) => k.key == key).chromaticLevels,
          [0, played, 0]);
      expect(p.progressData.firstWhere((k) => k.key == key).diatonicLevels,
          [0, 0, 0],
          reason: 'a chromatic run must not move the diatonic dial');
      expect(p.todayDailyResult, isNotNull);
      expect(p.todayDailyResult!.correct, played);
      expect(p.dailyStreak, 1);
    });

    test('its clock is medium and its budget scales with the questions',
        () async {
      final p = await freshProvider();
      final c = chromaticToday(p);
      p.startDailyChallenge(challenge: c);
      expect(p.chromaticDifficulty, DailyChallenge.difficulty,
          reason: 'answers must be filed under the tier actually played');
      expect(p.activeDailyTotalTimeMs,
          DailyChallenge.questionCount * c.msPerQuestion);
    });
  });

  group('key ranking is one number', () {
    test('ranks by instant recall — right AND quick, not right eventually',
        () async {
      final p = await freshProvider();
      p.selectKey('C');
      p.startMode(TrainingMode.diatonic, overrideKey: 'C');
      // C: 1 of 2 right, but that one came back inside the Master clock.
      // G: 2 of 2 right at four seconds — accurate, and nowhere near fluent.
      // F: never played.
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
      expect(ranks['C'], 1,
          reason: 'a key you half-know instantly beats one you always work '
              'out — the ranking is about improvising, not about being right');
      expect(ranks['G'], 2);
      expect(ranks['F'], 0, reason: 'never played is unranked, not last');
    });

    test('a correct answer past the Master clock does not count as fluency',
        () async {
      final p = await freshProvider();
      p.selectKey('C');
      p.startMode(TrainingMode.diatonic, overrideKey: 'C');
      p.recordAnswer(
          isCorrect: true, responseTime: kInstantMs + 1,
          answerDetails:
              answer(mode: 'diatonic', tonality: 'C', rt: kInstantMs + 1));
      p.recordAnswer(
          isCorrect: true, responseTime: kInstantMs,
          answerDetails:
              answer(mode: 'diatonic', tonality: 'G', rt: kInstantMs));
      p.finishSession();

      expect(p.keyRanks['G'], 1);
      expect(p.keyRanks['C'], 2);
    });

    test('a timed-out question is never fluency, however it is stored',
        () async {
      final p = await freshProvider();
      p.selectKey('C');
      p.startMode(TrainingMode.diatonic, overrideKey: 'C');
      // An empty selection is how a timeout is recorded; its responseTime is
      // the tier's limit, not the player's speed.
      p.recordAnswer(
          isCorrect: false, responseTime: 400,
          answerDetails: answer(
              mode: 'diatonic', tonality: 'C', correct: false, rt: 400,
              selected: ''));
      p.finishSession();
      expect(p.keyRanks['C'], 1, reason: 'played, so ranked — but at zero');
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

  _whichModesFeedWhichCard();

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

/// Which family reaches which card. Each of the four is now a deliberate
/// choice, and a change that quietly re-pools them fails here.
void _whichModesFeedWhichCard() {
  group('the cards read the modes they are about', () {
    test('the Degree Accuracy bars take both directions, not the harmonizer',
        () async {
      // The card is about a DEGREE. Asking the note for a degree and the
      // degree for a note are the same fact from either side; asking which
      // key a note belongs to is a different question with a different answer
      // type, and pooling it would put two of them in one bar.
      final p = await freshProvider();
      play(p, TrainingMode.diatonic, 'C');
      play(p, TrainingMode.noteToNumber, 'C');
      play(p, TrainingMode.ofWhat, 'C');

      var counted = 0;
      for (final s in p.stats.sessionHistory) {
        for (final a in s.answers) {
          if (a.mode != 'of-what') counted++;
        }
      }
      expect(counted, 12, reason: 'two families of six, harmonizer excluded');
    });

    test('the response-time chart leaves the harmonizer out', () async {
      // Searching twelve keys is slower than placing one note, for reasons
      // that say nothing about how well this key is known.
      final p = await freshProvider();
      play(p, TrainingMode.ofWhat, 'C');
      final inKey = p.stats.sessionHistory
          .expand((s) => s.answers)
          .where((a) => a.tonality == 'C' && a.mode != 'of-what');
      expect(inKey, isEmpty);
    });
  });
}
