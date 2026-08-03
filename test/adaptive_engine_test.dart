import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/utils/adaptive_engine.dart';

/// Does Adaptive Difficulty actually teach faster than asking at random?
///
/// The only way to answer that is to put a learner through both and compare.
/// A synthetic one will do, as long as it has the three properties that make
/// scheduling matter at all:
///
///   • **graded skill** — each degree has a latent strength that drives both
///     whether the answer is right and how long it takes;
///   • **learning** — being asked strengthens the degree, and a successful
///     retrieval strengthens it more than a corrected miss; and
///   • **forgetting** — strength decays while a degree goes unasked, which is
///     the whole reason spaced review exists. Without decay, a scheduler that
///     drills the single weakest item forever would look optimal.
///
/// The learner is not tuned to flatter either scheduler: same seeds, same
/// parameters, only the choice of question differs.
class SyntheticLearner {
  final List<String> degrees;
  final Random rng;
  final Map<String, double> skill;
  final double learnRate;
  final double decayPerQuestion;

  SyntheticLearner({
    required this.degrees,
    required this.rng,
    required Map<String, double> initialSkill,
    this.learnRate = 0.16,
    this.decayPerQuestion = 0.006,
  }) : skill = Map.of(initialSkill);

  double pCorrect(String deg) {
    final guess = 1.0 / degrees.length;
    return guess + (1 - guess) * skill[deg]!;
  }

  int responseTime(String deg) {
    final s = skill[deg]!;
    final base = 600 + 4200 * (1 - s);
    return (base * (0.8 + rng.nextDouble() * 0.4)).round();
  }

  AnswerRecord answer(String deg, int limitMs) {
    var correct = rng.nextDouble() < pCorrect(deg);
    var rt = responseTime(deg);
    // Running out of time is a miss, which is how the clock becomes a real
    // difficulty knob rather than decoration.
    if (rt > limitMs) {
      correct = false;
      rt = limitMs;
    }

    final gain = correct ? learnRate : learnRate * 0.55;
    skill[deg] = (skill[deg]! + gain * (1 - skill[deg]!)).clamp(0.0, 1.0);
    for (final other in degrees) {
      if (other == deg) continue;
      skill[other] = skill[other]! * (1 - decayPerQuestion);
    }

    return AnswerRecord(
      degree: deg, note: 'X', selectedNote: correct ? 'X' : 'Y',
      tonality: 'C', mode: 'diatonic', isReverse: false, difficulty: 1,
      responseTime: rt, isCorrect: correct, timestamp: 0,
    );
  }

  double get meanSkill =>
      degrees.map((d) => skill[d]!).reduce((a, b) => a + b) / degrees.length;
  double get weakestSkill => degrees.map((d) => skill[d]!).reduce(min);
}

typedef Scheduler = String Function(List<String> possible, String current,
    List<AnswerRecord> history, List<AnswerRecord> session, int limitMs);

class RunResult {
  final double meanSkill, weakestSkill, accuracy;
  final Map<String, int> exposures;

  /// Exposures over the opening stretch only. A scheduler that works stops
  /// favouring a degree once it improves, so a whole-run ratio understates the
  /// targeting: by the end there is nothing left to target.
  final Map<String, int> earlyExposures;

  RunResult(this.meanSkill, this.weakestSkill, this.accuracy, this.exposures,
      this.earlyExposures);

  double focusRatio(String weak, String strong) =>
      (exposures[weak] ?? 0) / max(1, exposures[strong] ?? 1);
  double earlyFocusRatio(String weak, String strong) =>
      (earlyExposures[weak] ?? 0) / max(1, earlyExposures[strong] ?? 1);
  double earlyShare(String deg) {
    final total = earlyExposures.values.fold<int>(0, (a, b) => a + b);
    return total == 0 ? 0 : (earlyExposures[deg] ?? 0) / total;
  }
}

/// Past answers consistent with [skill], as a returning player would have.
///
/// Cold start is the worst case for any scheduler — with no history every
/// degree looks identical and the first dozen questions are necessarily
/// uniform. Real users arrive with a record for the key, which is when
/// adaptive selection has something to work with.
List<AnswerRecord> priorHistory({
  required List<String> degrees,
  required Map<String, double> skill,
  required int count,
  required int seed,
}) {
  final rng = Random(seed);
  return List.generate(count, (i) {
    final d = degrees[rng.nextInt(degrees.length)];
    final s = skill[d]!;
    final guess = 1 / degrees.length;
    final correct = rng.nextDouble() < guess + (1 - guess) * s;
    return AnswerRecord(
      degree: d, note: 'X', selectedNote: correct ? 'X' : 'Y',
      tonality: 'C', mode: 'diatonic', isReverse: false, difficulty: 1,
      responseTime: ((600 + 4200 * (1 - s)) * (0.8 + rng.nextDouble() * 0.4))
          .round(),
      isCorrect: correct, timestamp: 0,
    );
  });
}

RunResult runScheduler({
  required Scheduler scheduler,
  required Map<String, double> initialSkill,
  required List<String> degrees,
  required int questions,
  required int seed,
  int nominalLimitMs = 6000,
  bool adaptiveClock = false,
  List<AnswerRecord> prior = const [],
}) {
  final rng = Random(seed);
  final learner =
      SyntheticLearner(degrees: degrees, rng: rng, initialSkill: initialSkill);
  final history = <AnswerRecord>[...prior];
  final session = <AnswerRecord>[];
  final exposures = {for (final d in degrees) d: 0};
  final early = {for (final d in degrees) d: 0};
  const earlyWindow = 35; // roughly one real session
  var current = '';
  var correct = 0;

  for (var i = 0; i < questions; i++) {
    final limit = adaptiveClock
        ? AdaptiveClock.limitFor(nominalMs: nominalLimitMs, recent: session)
        : nominalLimitMs;
    final deg = scheduler(degrees, current, history, session, limit);
    exposures[deg] = exposures[deg]! + 1;
    if (i < earlyWindow) early[deg] = early[deg]! + 1;
    final rec = learner.answer(deg, limit);
    if (rec.isCorrect) correct++;
    history.add(rec);
    session.add(rec);
    current = deg;
  }
  return RunResult(learner.meanSkill, learner.weakestSkill,
      correct / questions, exposures, early);
}

void main() {
  const diatonic = ['1', '2', '3', '4', '5', '6', '7'];

  // A plausible learner: tonic and fifth solid, seventh and fourth shaky.
  // This uneven shape is exactly what adaptive practice exists to fix.
  Map<String, double> unevenSkill() => {
        '1': 0.90, '2': 0.55, '3': 0.60, '4': 0.25,
        '5': 0.85, '6': 0.45, '7': 0.10,
      };

  Scheduler uniform(Random rng) => (possible, current, history, session, _) {
        final avail = possible.where((d) => d != current).toList();
        if (avail.isEmpty) avail.addAll(possible);
        return avail[rng.nextInt(avail.length)];
      };

  Scheduler adaptive(Random rng) {
    final engine = AdaptiveEngine(rng: rng);
    return (possible, current, history, session, limit) => engine.pick(
          possible: possible, currentDeg: current, history: history,
          session: session, timeLimitMs: limit,
        );
  }

  ({double mean, double weakest, double acc, double focus,
    double earlyFocus, double earlyShare}) average(
      Scheduler Function(Random) build,
      {int runs = 80, int questions = 120, bool clock = false,
       bool returning = false}) {
    var mean = 0.0, weakest = 0.0, acc = 0.0;
    var focus = 0.0, earlyFocus = 0.0, earlyShare = 0.0;
    for (var s = 0; s < runs; s++) {
      final r = runScheduler(
        scheduler: build(Random(1000 + s)),
        initialSkill: unevenSkill(),
        degrees: diatonic,
        questions: questions,
        seed: 2000 + s,
        adaptiveClock: clock,
        prior: returning
            ? priorHistory(
                degrees: diatonic, skill: unevenSkill(),
                count: 70, seed: 3000 + s)
            : const [],
      );
      mean += r.meanSkill;
      weakest += r.weakestSkill;
      acc += r.accuracy;
      focus += r.focusRatio('7', '1');
      earlyFocus += r.earlyFocusRatio('7', '1');
      earlyShare += r.earlyShare('7');
    }
    return (mean: mean / runs, weakest: weakest / runs, acc: acc / runs,
            focus: focus / runs, earlyFocus: earlyFocus / runs,
            earlyShare: earlyShare / runs);
  }

  test('practice lands on the degrees the learner cannot do', () {
    final uni = average(uniform, returning: true);
    final ada = average(adaptive, returning: true);
    final uniCold = average(uniform);
    final adaCold = average(adaptive);

    String line(String tag, dynamic r) =>
        '$tag: mean ${r.mean.toStringAsFixed(3)}  '
        'weakest ${r.weakest.toStringAsFixed(3)}  '
        'acc ${(r.acc * 100).toStringAsFixed(1)}%  '
        'focus ${r.focus.toStringAsFixed(2)}x  '
        'earlyFocus ${r.earlyFocus.toStringAsFixed(2)}x  '
        'earlyShare ${(r.earlyShare * 100).toStringAsFixed(0)}%';
    // ignore: avoid_print
    print('— returning player (has history for the key) —');
    // ignore: avoid_print
    print(line('uniform ', uni));
    // ignore: avoid_print
    print(line('adaptive', ada));
    // ignore: avoid_print
    print('— first ever session on the key (cold start) —');
    // ignore: avoid_print
    print(line('uniform ', uniCold));
    // ignore: avoid_print
    print(line('adaptive', adaCold));

    // The weakest degree is the whole point: what you cannot do gets the
    // practice. This is the number that must not regress.
    expect(ada.weakest, greaterThan(uni.weakest + 0.02),
        reason: 'adaptive must leave the worst degree meaningfully stronger');

    // The preference has to be visible in the opening session, while there is
    // still a gap to close. Measured against the baseline rather than against
    // a magic number, so the bar means something: the old engine reached
    // 1.23x here, which is why the feature felt like nothing.
    expect(ada.earlyFocus, greaterThan(uni.earlyFocus * 2.5),
        reason: 'early on, the weakest degree must be asked far more often '
            'than a mastered one — and far more than chance would');
    expect(ada.earlyShare, greaterThan(uni.earlyShare * 1.6),
        reason: 'and take a clearly outsized share of the opening session');
    // But not so outsized that practice stops being interleaved: blocked
    // drilling of a single item retains worse than mixed practice.
    expect(ada.earlyShare, lessThan(0.45),
        reason: 'practice must stay interleaved, not become a single-item drill');

    // Overall skill should not be paid for out of the weak degree's pocket.
    expect(ada.mean, greaterThanOrEqualTo(uni.mean - 0.01));
  });

  test('a mastered degree still comes back for review', () {
    // Everything mastered except one. Even so, the strong degrees must keep a
    // share — a scheduler that abandons them lets them rot.
    final engine = AdaptiveEngine(rng: Random(3));
    final history = <AnswerRecord>[];
    for (var i = 0; i < 90; i++) {
      final d = diatonic[i % diatonic.length];
      history.add(AnswerRecord(
        degree: d, note: 'X', selectedNote: 'X', tonality: 'C',
        mode: 'diatonic', isReverse: false, difficulty: 1,
        responseTime: d == '7' ? 5200 : 900,
        isCorrect: d != '7', timestamp: 0,
      ));
    }
    final counts = {for (final d in diatonic) d: 0};
    final session = <AnswerRecord>[];
    var current = '';
    for (var i = 0; i < 600; i++) {
      final d = engine.pick(
        possible: diatonic, currentDeg: current, history: history,
        session: session, timeLimitMs: 6000,
      );
      counts[d] = counts[d]! + 1;
      current = d;
    }
    // ignore: avoid_print
    print('review spread: $counts');
    expect(counts['7']!, greaterThan(counts['1']! * 2),
        reason: 'the failing degree must dominate');
    for (final d in diatonic) {
      expect(counts[d], greaterThan(0),
          reason: 'no degree should ever be abandoned entirely');
    }
  });

  test('strength counts speed, not just correctness', () {
    List<AnswerRecord> allCorrectAt(int ms) => List.generate(
        8,
        (_) => AnswerRecord(
              degree: '1', note: 'X', selectedNote: 'X', tonality: 'C',
              mode: 'diatonic', isReverse: false, difficulty: 1,
              responseTime: ms, isCorrect: true, timestamp: 0,
            ));

    final target = AdaptiveEngine.fluencyTargetMs(6000); // 2400ms
    final fast = AdaptiveEngine.strengthOf(allCorrectAt(1200), target);
    final slow = AdaptiveEngine.strengthOf(allCorrectAt(5200), target);

    // ignore: avoid_print
    print('strength: fast ${fast.toStringAsFixed(2)}  slow ${slow.toStringAsFixed(2)}');
    expect(fast, greaterThan(0.95));
    // Right every time but four seconds late is not mastery. The old engine
    // scored these two identically.
    expect(slow, lessThan(0.7));
  });

  group('the clock', () {
    List<AnswerRecord> answers(int n, double accuracy) => List.generate(
        n,
        (i) => AnswerRecord(
              degree: '1', note: 'X', selectedNote: 'X', tonality: 'C',
              mode: 'diatonic', isReverse: false, difficulty: 1,
              responseTime: 1000,
              isCorrect: i < (n * accuracy).round(), timestamp: 0,
            ));

    test('holds nominal until there is evidence', () {
      expect(AdaptiveClock.limitFor(nominalMs: 6000, recent: answers(4, 1.0)),
          6000);
    });

    test('tightens when the learner is cruising', () {
      final t = AdaptiveClock.limitFor(nominalMs: 6000, recent: answers(10, 1.0));
      expect(t, lessThan(6000));
      expect(t, greaterThanOrEqualTo(3600)); // never past the floor
    });

    test('loosens — and faster — when the learner is drowning', () {
      final l = AdaptiveClock.limitFor(nominalMs: 6000, recent: answers(10, 0.4));
      expect(l, greaterThan(6000));
      expect(l, lessThanOrEqualTo(9000));
    });

    test('leaves the productive band alone', () {
      expect(AdaptiveClock.limitFor(nominalMs: 6000, recent: answers(10, 0.8)),
          6000);
    });
  });
}
