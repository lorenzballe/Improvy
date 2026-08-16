import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/utils/music_engine.dart';

/// The daily is the one run everybody plays against the same questions, so its
/// shape has to hold: same challenge from the same date on any device, every
/// question answerable in whichever direction the day drew, and a clock that
/// stays tied to the question count.
void main() {
  /// Every challenge in a year — enough to see all three directions against
  /// every key and note they can be built on.
  Iterable<DailyChallenge> aYear() sync* {
    for (var d = 0; d < 365; d++) {
      yield DailyChallenge.forDate(DateTime(2026, 1, 1).add(Duration(days: d)));
    }
  }

  test('the whole world gets the same challenge for a given day', () {
    final a = DailyChallenge.forDate(DateTime(2026, 8, 12));
    final b = DailyChallenge.forDate(DateTime(2026, 8, 12));
    expect(a.key, b.key);
    expect(a.degrees, b.degrees);
    expect(a.mode, b.mode);
    // A different day must actually differ, or the seed is not doing its job.
    final other = DailyChallenge.forDate(DateTime(2026, 8, 13));
    expect(other.degrees, isNot(a.degrees));
  });

  test('all three directions come up, and none dominates', () {
    final counts = <TrainingMode, int>{};
    for (final c in aYear()) {
      counts[c.mode] = (counts[c.mode] ?? 0) + 1;
    }
    expect(counts.keys, unorderedEquals(DailyChallenge.modes),
        reason: 'every direction must actually be drawn: $counts');
    // A third each, give or take. A seed that leaned hard on one direction
    // would quietly make the daily the old single-mode challenge again.
    for (final n in counts.values) {
      expect(n, greaterThan(70), reason: 'lopsided draw: $counts');
    }
  });

  test('every question is answerable, whichever direction the day drew', () {
    // The board is built from the mode, so a question the board cannot express
    // is one the player simply cannot answer. Checked across a full year.
    for (final c in aYear()) {
      switch (c.mode) {
        case TrainingMode.ofWhat:
          // Answers are the twelve plain roots, and the root has to exist:
          // a degree that would need a double-accidental root is not a chord.
          for (final deg in c.degrees) {
            final root = rootFromNoteAndDegree(c.key, deg);
            expect(root, isNotNull,
                reason: '${c.dateKey}: ${c.key} as $deg has no clean root');
            expect(DailyChallenge.ofWhatNotes.any((n) => areEnharmonicEquivalent(n, root!)),
                isTrue,
                reason: '${c.dateKey}: root $root is not one of the buttons');
          }
        case TrainingMode.noteToNumber:
          // The answer IS the degree, so it has to be one the reverse board
          // shows — and the note it is asked by must be spellable.
          for (final deg in c.degrees) {
            expect(kChromaticDegreesSplit, contains(deg),
                reason: '${c.dateKey}: $deg is not on the reverse board');
            final shown = getNoteFromChromaticDegree(deg, calculateMajorScale(c.key), c.key);
            expect(shown, isNotEmpty,
                reason: '${c.dateKey}: $deg of ${c.key} has no note to show');
          }
        default:
          final scale = calculateMajorScale(c.key);
          final board = getChromaticButtons(scale, c.key).map((b) => b.note).toSet();
          for (final deg in c.degrees) {
            final answer = getNoteFromChromaticDegree(deg, scale, c.key);
            expect(board.any((n) => areEnharmonicEquivalent(n, answer)), isTrue,
                reason: '${c.dateKey}, key ${c.key}: degree $deg answers '
                    '$answer, which is not on the board $board');
          }
      }
    }
  });

  test('every challenge is the full length, with no back-to-back repeat', () {
    for (final c in aYear()) {
      expect(c.degrees.length, DailyChallenge.questionCount,
          reason: '${c.dateKey} (${c.mode}) is short');
      for (var i = 1; i < c.degrees.length; i++) {
        expect(c.degrees[i], isNot(c.degrees[i - 1]),
            reason: '${c.dateKey} repeated ${c.degrees[i]} back to back');
      }
    }
  });

  test('the opening run covers the pool before anything repeats', () {
    for (final c in aYear()) {
      // However big the direction's pool is, the first pass through it must be
      // all distinct — nobody should meet the same degree twice while another
      // is still unasked.
      final pass = c.degrees.take(c.degrees.toSet().length).toList();
      expect(pass.toSet().length, pass.length,
          reason: '${c.dateKey} (${c.mode}) repeated inside its first pass');
    }
  });

  test('the clock follows the question count instead of drifting from it', () {
    for (final c in aYear()) {
      expect(c.totalTimeMs, DailyChallenge.questionCount * c.msPerQuestion);
      // The daily should be harder than an ordinary Virtuoso question (3.2s)
      // in the two directions that compare to one.
      if (c.mode != TrainingMode.ofWhat) {
        expect(c.msPerQuestion, lessThan(3200));
        expect(c.totalTimeMs, 42000);
        expect(c.rule, '15 questions · 42 seconds');
      } else {
        // …Of What? is a two-step question and gets room for it — but not so
        // much room that it stops being a challenge.
        expect(c.msPerQuestion, inInclusiveRange(3200, 4500));
      }
    }
  });

  test('a chromatic day runs a chromatic session on the twelve-note board',
      () async {
    final p = await _provider();
    // Seeded to a day whose direction is chromatic, so the assertions below
    // are about the wiring and not about which day happened to be picked.
    final c = _firstDayWith(TrainingMode.chromatic);
    p.startDailyChallenge(challenge: c);

    expect(p.activeMode, TrainingMode.chromatic);
    expect(p.isReverse, isFalse);
    expect(p.fixedNote, isNull);
    expect(p.selectedKey, c.key);
    expect(p.chromaticDifficulty, DailyChallenge.difficulty);
    expect(p.activeDailyDegrees.length, DailyChallenge.questionCount);
  });

  test('a Note to Number day runs in reverse, on the split degree board',
      () async {
    final p = await _provider();
    final c = _firstDayWith(TrainingMode.noteToNumber);
    p.startDailyChallenge(challenge: c);

    expect(p.activeMode, TrainingMode.noteToNumber);
    // Without this the trainer shows notes as answers to a note question.
    expect(p.isReverse, isTrue);
    expect(p.selectedKey, c.key);
    expect(p.customDegrees, kChromaticDegreesSplit);
  });

  test('an …Of What? day runs on its note, with no key in play', () async {
    final p = await _provider();
    final c = _firstDayWith(TrainingMode.ofWhat);
    p.startDailyChallenge(challenge: c);

    expect(p.activeMode, TrainingMode.ofWhat);
    expect(p.fixedNote, c.key);
    // The mode has no tonality; leaving a key selected sends the home tab back
    // into that key's detail screen on exit.
    expect(p.selectedKey, isNull);
    expect(p.customDegrees, c.degrees);
    // Longer clock for the longer question.
    expect(p.activeDailyTotalTimeMs, greaterThan(42000));
  });

  test('the share line names the direction, and never invents a tonality', () {
    final ofWhat = DailyResult(
      dateKey: '2026-03-04', key: 'E♭', answers: const [true, false],
      timeMs: 12000, completed: true, timestamp: 0, mode: TrainingMode.ofWhat,
    );
    expect(buildDailyShareText(ofWhat, 1), contains('E♭ …of what?'));
    expect(buildDailyShareText(ofWhat, 1), isNot(contains('major')));

    final reverse = DailyResult(
      dateKey: '2026-03-05', key: 'E♭', answers: const [true],
      timeMs: 9000, completed: true, timestamp: 0,
      mode: TrainingMode.noteToNumber,
    );
    expect(buildDailyShareText(reverse, 1), contains('note→number'));
  });

  test('a result saved before the daily rotated reads back as chromatic', () {
    final old = DailyResult.fromJson({
      'dateKey': '2026-01-01', 'key': 'G', 'answers': [true, true],
      'timeMs': 8000, 'completed': true, 'timestamp': 0,
    });
    expect(old.mode, TrainingMode.chromatic);
    expect(buildDailyShareText(old, 1), contains('Key of G major'));
  });
}

Future<AppProvider> _provider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  return p;
}

/// The first challenge of 2026 that runs in [mode] — so a test about wiring
/// does not depend on what today happens to be.
DailyChallenge _firstDayWith(TrainingMode mode) {
  for (var d = 0; d < 365; d++) {
    final c = DailyChallenge.forDate(DateTime(2026, 1, 1).add(Duration(days: d)));
    if (c.mode == mode) return c;
  }
  throw StateError('no day in 2026 runs $mode');
}
