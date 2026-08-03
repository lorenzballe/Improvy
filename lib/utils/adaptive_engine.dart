import 'dart:math';

import '../models/stats.dart';
import 'music_engine.dart';

/// Adaptive practice: which degree to ask next, and how much time to allow.
///
/// The app's promise is instant recall of a degree in any key. That makes two
/// things true about practice, and both drive this file:
///
///   1. **Right-but-slow is not learned.** A four-second answer is useless
///      over a chord chart, so latency has to count towards mastery, not just
///      correctness.
///   2. **Practice belongs where it is weak.** Time spent re-asking a degree
///      you already own is time not spent on the one you don't.
///
/// Selection therefore scores every candidate on a single 0–1 scale — how much
/// asking it now would help — and samples proportionally. Everything that
/// modifies that score is *multiplicative*, so no secondary concern can
/// outweigh the primary one. (The previous version added a spaced-repetition
/// bonus of up to +40 onto a mastery weight that only spanned 10–60, and
/// damped repeats by ×0.45 exactly when focus was working: the two together
/// flattened a 5.4:1 intended preference into a measured 1.23:1. See
/// test/adaptive_engine_test.dart, which fails if that regresses.)
class AdaptiveEngine {
  final Random _rng;

  AdaptiveEngine({Random? rng}) : _rng = rng ?? Random();

  /// How many past answers for a degree still carry weight.
  static const _recentWindow = 12;

  /// Per-answer decay of that weight, newest first. 0.8 puts roughly half the
  /// evidence in the last three answers — fast enough to notice that
  /// something just clicked, slow enough not to swing on one lucky guess.
  static const _recencyDecay = 0.8;

  /// Fluency target as a fraction of the tier's own time limit. A degree
  /// answered inside this is "automatic"; at twice this it scores zero
  /// fluency. Tying it to the tier keeps Apprentice humane and Master strict.
  static const _fluencyFraction = 0.4;

  /// Floor on any degree's priority, so a mastered one still resurfaces.
  static const _priorityFloor = 0.045;

  /// Sharpening exponent: raises the contrast between weak and strong.
  ///
  /// Tuned against the simulation, not by taste. Too low and the weak degree
  /// gains only a couple of extra asks per session — invisible, which is what
  /// the old engine suffered from. Too high and the session collapses into
  /// drilling one item, which retains worse than interleaved practice.
  static const _sharpen = 2.9;

  /// True when a recorded answer's degree is (one spelling of) [candidate].
  ///
  /// Forward-chromatic candidates keep the slash form ('♭3/♯2') while answers
  /// record the single spelling actually asked ('♭3', '♯2' — or the upper
  /// structure name '♯9'), so the match must try every spelling.
  static bool isSameDegree(String recorded, String candidate) {
    final r = normalizeExtension(recorded);
    return candidate.split('/').any((p) => normalizeExtension(p) == r);
  }

  /// The latency below which recall counts as automatic, for a tier whose
  /// per-question limit is [limitMs].
  static double fluencyTargetMs(int limitMs) => limitMs * _fluencyFraction;

  /// How well [answers] (chronological, for one degree) are known: 0 = not at
  /// all, 1 = fast and reliable.
  ///
  /// Accuracy sets the ceiling and fluency scales it, so a degree answered
  /// correctly every time but slowly lands around 0.6 — still in rotation,
  /// which is the point.
  static double strengthOf(List<AnswerRecord> answers, double fluencyTarget) {
    if (answers.isEmpty) return 0;

    final recent = answers.length > _recentWindow
        ? answers.sublist(answers.length - _recentWindow)
        : answers;

    var weighted = 0.0, total = 0.0;
    var latency = 0.0, latencyWeight = 0.0;
    for (var i = 0; i < recent.length; i++) {
      // Newest answer gets weight 1, each older one 0.8 of the next.
      final w = pow(_recencyDecay, recent.length - 1 - i).toDouble();
      total += w;
      if (recent[i].isCorrect) {
        weighted += w;
        latency += w * recent[i].responseTime;
        latencyWeight += w;
      }
    }
    final accuracy = weighted / total;
    if (latencyWeight == 0) return 0; // never once right → nothing is known

    final avgLatency = latency / latencyWeight;
    // 1 at the target, falling to 0 at twice the target.
    final fluency = (2 - avgLatency / fluencyTarget).clamp(0.0, 1.0);
    return (accuracy * (0.6 + 0.4 * fluency)).clamp(0.0, 1.0);
  }

  /// Uniform pick that never repeats the question just asked.
  String _uniform(List<String> possible, String currentDeg) {
    final available = possible.where((d) => d != currentDeg).toList();
    if (available.isEmpty) available.addAll(possible);
    return available[_rng.nextInt(available.length)];
  }

  /// Priority per candidate, in the order of [possible]. Exposed so the UI and
  /// the tests can see what the engine believes without re-deriving it.
  List<double> priorities({
    required List<String> possible,
    required List<AnswerRecord> history,
    required int timeLimitMs,
  }) {
    final target = fluencyTargetMs(timeLimitMs);
    return possible.map((deg) {
      final answers =
          history.where((a) => isSameDegree(a.degree, deg)).toList();

      // Never asked here: nothing is more useful than finding out.
      if (answers.isEmpty) return 1.0;

      final strength = strengthOf(answers, target);

      // Spaced review, as decay rather than as a bonus. A shaky degree fades
      // within a handful of questions; a solid one holds for dozens. Both come
      // back — the strong one just waits longer.
      final lastIdx = history.lastIndexWhere((a) => isSameDegree(a.degree, deg));
      final sinceSeen = history.length - 1 - lastIdx;
      final halfLife = 5 + 45 * strength;
      final retrievability = pow(0.5, sinceSeen / halfLife).toDouble();

      // What is left to gain. Strong AND fresh → little; anything else → more.
      final need = (1 - strength * retrievability).clamp(0.0, 1.0);
      return _priorityFloor +
          (1 - _priorityFloor) * pow(need, _sharpen).toDouble();
    }).toList();
  }

  /// [history] is every answer recorded for THIS key and mode, in true
  /// chronological order, with the current session appended.
  /// [session] is the current session's answers only.
  /// [timeLimitMs] is the per-question limit actually in force.
  String pick({
    required List<String> possible,
    required String currentDeg,
    required List<AnswerRecord> history,
    required List<AnswerRecord> session,
    required int timeLimitMs,
  }) {
    if (possible.isEmpty) return '';
    if (possible.length == 1) return possible.first;

    final weights = priorities(
      possible: possible,
      history: history,
      timeLimitMs: timeLimitMs,
    );

    // Never ask the same question twice running, and taper the few before it
    // so two weak degrees cannot trade the whole session between them. The
    // window scales with the pool: blocking three of seven degrees is a real
    // constraint, three of twelve is not.
    final window = (possible.length ~/ 3).clamp(1, 3);
    for (var i = 0; i < possible.length; i++) {
      if (possible[i] == currentDeg) {
        weights[i] = 0;
        continue;
      }
      for (var back = 2; back <= window + 1; back++) {
        final n = session.length - back;
        if (n < 0) break;
        if (isSameDegree(session[n].degree, possible[i])) {
          // 0.55 two questions ago, easing back to 1 as it recedes. Enough to
          // break an A-B-A-B rut — a gap of one leaves the answer still in
          // mind, so the retrieval is too easy to teach much — without
          // undoing the focus that put the degree there in the first place.
          weights[i] *= 0.55 + 0.45 * ((back - 2) / window).clamp(0.0, 1.0);
          break;
        }
      }
    }

    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return _uniform(possible, currentDeg);

    var r = _rng.nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      if (r < weights[i]) return possible[i];
      r -= weights[i];
    }
    return possible.last;
  }
}

/// The other half of "adaptive difficulty": the clock.
///
/// Selection decides *what* to ask; this decides how much time to allow, which
/// is the knob a player actually feels. It holds recent accuracy near the
/// band where learning is fastest — around 85% correct, per Wilson et al.,
/// *The Eighty Five Percent Rule for optimal learning* (Nature Communications
/// 10, 4646, 2019). That result is derived for binary decisions and this is a
/// 7- or 12-way choice, so treat 85% as a well-motivated target rather than a
/// number carried over from the proof.
class AdaptiveClock {
  /// Accuracy above this and the clock tightens.
  static const _upper = 0.90;

  /// Accuracy below this and it loosens.
  static const _lower = 0.78;

  /// How far the limit may move from the tier's nominal value.
  static const _tightest = 0.6;
  static const _loosest = 1.5;

  /// Answers considered. Short enough to react within a session, long enough
  /// not to swing on a single miss.
  static const window = 10;

  /// The per-question limit to use, given the tier's [nominalMs] and the
  /// answers so far (newest last).
  ///
  /// Below [window] answers the nominal limit stands: adapting off two data
  /// points would just be noise with a stopwatch attached.
  static int limitFor({
    required int nominalMs,
    required List<AnswerRecord> recent,
  }) {
    if (recent.length < window) return nominalMs;

    final slice = recent.sublist(recent.length - window);
    final accuracy = slice.where((a) => a.isCorrect).length / slice.length;

    double scale;
    if (accuracy > _upper) {
      // Cruising: take time away, proportionally to how far above the band.
      final over = (accuracy - _upper) / (1 - _upper);
      scale = 1 - (1 - _tightest) * over;
    } else if (accuracy < _lower) {
      // Struggling: give it back faster than it was taken. Frustration ends
      // sessions; boredom only slows them.
      final under = ((_lower - accuracy) / _lower).clamp(0.0, 1.0);
      scale = 1 + (_loosest - 1) * min(1.0, under * 1.6);
    } else {
      scale = 1;
    }
    return (nominalMs * scale.clamp(_tightest, _loosest)).round();
  }
}
