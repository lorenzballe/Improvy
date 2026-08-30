import 'dart:math' as math;

/// How many questions a tier is worth. Apprentice is shorter because it is
/// where the answer is being worked out; the tiers above it are longer because
/// by then it should be recall.
const List<int> kTierCaps = [30, 40, 50];

/// How much of a tier must be answered before the next one opens.
///
/// One fraction for every ladder in the app. It used to be 27 of 30 to reach
/// Virtuoso and 37 of 40 to reach Master — 90% and 92.5%, two different bars
/// nobody chose, written out by hand in five places that could drift apart.
const double kTierUnlockFraction = 0.80;

/// [kTierUnlockFraction] of the tier BELOW, in questions: nothing to open
/// Apprentice, 24 of 30 for Virtuoso, 32 of 40 for Master.
const List<int> kTierUnlock = [0, 24, 32];

class KeyProgress {
  final String key;
  final List<int> diatonicLevels; // [level1score, level2score, level3score]
  final List<int> chromaticLevels;
  // "…Of What?" — the harmonizer drill, where this note is given as a degree
  // and the player names the key it belongs to. Tracked per note, on the same
  // three-difficulty scale as the other modes.
  final List<int> harmonizerLevels;

  // Note to Number — the same key, asked backwards: the note is played and the
  // answer is its degree. Kept apart from [diatonicLevels] rather than folded
  // in, because naming the degree for a note and naming the note for a degree
  // are genuinely different skills; someone fluent one way is routinely lost
  // the other.
  //
  // Two stores, not one, for the same reason the forward modes have two: a
  // run over the 7 diatonic degrees and a run over all 12 are different work,
  // and one bar for both would let the easy half fill the hard half's share.
  final List<int> ntnDiatonicLevels;
  final List<int> ntnChromaticLevels;

  KeyProgress({
    required this.key,
    List<int>? diatonicLevels,
    List<int>? chromaticLevels,
    List<int>? harmonizerLevels,
    List<int>? ntnDiatonicLevels,
    List<int>? ntnChromaticLevels,
  })  : diatonicLevels = diatonicLevels ?? [0, 0, 0],
        chromaticLevels = chromaticLevels ?? [0, 0, 0],
        harmonizerLevels = harmonizerLevels ?? [0, 0, 0],
        ntnDiatonicLevels = ntnDiatonicLevels ?? [0, 0, 0],
        ntnChromaticLevels = ntnChromaticLevels ?? [0, 0, 0];

  int get diatonicProgress {
    final capped = _cappedLevels(diatonicLevels);
    return (capped.reduce((a, b) => a + b) / 120 * 100).round().clamp(0, 100);
  }

  int get chromaticProgress {
    final capped = _cappedLevels(chromaticLevels);
    return (capped.reduce((a, b) => a + b) / 120 * 100).round().clamp(0, 100);
  }

  int get harmonizerProgress {
    final capped = _cappedLevels(harmonizerLevels);
    return (capped.reduce((a, b) => a + b) / 120 * 100).round().clamp(0, 100);
  }

  /// All three tiers together, like every other dial here: the outline on a
  /// key fills only when Apprentice, Virtuoso and Master have all been taken.
  int get ntnDiatonicProgress {
    final capped = _cappedLevels(ntnDiatonicLevels);
    return (capped.reduce((a, b) => a + b) / 120 * 100).round().clamp(0, 100);
  }

  int get ntnChromaticProgress {
    final capped = _cappedLevels(ntnChromaticLevels);
    return (capped.reduce((a, b) => a + b) / 120 * 100).round().clamp(0, 100);
  }

  // ── Mastery ────────────────────────────────────────────────────────────────
  //
  // The six scores are not six independent facts. They sit in a 2x3 grid with
  // TWO containment relations running through it:
  //
  //                  Apprentice   Virtuoso   Master
  //     Diatonic         d1    <     d2   <    d3       ↑ chromatic contains
  //     Chromatic        c1    <     c2   <    c3       ↑ the diatonic degrees
  //
  //   * Vertically: the tiers ask the SAME questions with less time. Answering
  //     94% of them at 1.2s means you would answer at least as many at 3s.
  //   * Horizontally: the chromatic set is the 12 degrees, which contains the
  //     7 diatonic ones. 94% over all 12 leaves at most three wrong answers in
  //     fifty, so no subset of them — the diatonic seven included — can be
  //     worse than that.
  //
  // Summing the six raw scores, which is what this did, ignores both. Someone
  // who had never opened Diatonic and scored 47/50 on chromatic MASTER — the
  // single cell that dominates all the others — was told they knew 19% of the
  // key. They knew 94% of it.

  /// One cell of a row, as a fraction of what that tier is worth.
  static double _cell(List<int> levels, int tier) =>
      (levels[tier] / kTierCaps[tier]).clamp(0.0, 1.0);

  /// The best score in [levels] at [tier] or any harder tier, as a fraction.
  static double _bestFrom(List<int> levels, int tier) {
    var best = 0.0;
    for (var t = tier; t < 3; t++) {
      best = math.max(best, _cell(levels, t));
    }
    return best;
  }

  /// A row of three tier scores after the closure, back in question counts so
  /// that the dial, the tier gate and the "24/30" the user reads are all the
  /// same number.
  ///
  /// [wider] is the row that CONTAINS this one — chromatic contains diatonic,
  /// and nothing contains chromatic. Evidence flows down (a harder tier proves
  /// the easier ones) and inward (a wider set proves the narrower one), never
  /// the other way.
  ///
  /// One function for every ladder in the app: the same shape serves Note to
  /// Number's two rows, and a lone row (the harmonizer) by passing no [wider].
  static List<int> closeRow(List<int> row, {List<int>? wider}) => [
        for (var t = 0; t < 3; t++)
          (math.max(_bestFrom(row, t),
                      wider == null ? 0.0 : _bestFrom(wider, t)) *
                  kTierCaps[t])
              .round()
      ];

  /// The three diatonic tiers, counting what chromatic runs already proved.
  List<int> get effectiveDiatonic =>
      closeRow(diatonicLevels, wider: chromaticLevels);

  /// The three chromatic tiers. Nothing is wider, so only the tiers close.
  List<int> get effectiveChromatic => closeRow(chromaticLevels);

  List<int> get effectiveNtnDiatonic =>
      closeRow(ntnDiatonicLevels, wider: ntnChromaticLevels);

  List<int> get effectiveNtnChromatic => closeRow(ntnChromaticLevels);

  static double _rowMean(List<int> effective) {
    var sum = 0.0;
    for (var t = 0; t < 3; t++) {
      sum += _cell(effective, t);
    }
    return sum / 3;
  }

  /// The seven degrees of the scale, across all three speeds, counting what
  /// chromatic runs have already proved. 0–1.
  double get diatonicReach => _rowMean(effectiveDiatonic);

  /// The five altered degrees on top of them. 0–1.
  double get chromaticReach => _rowMean(effectiveChromatic);

  /// How well this key is known, 0–100.
  ///
  /// The two halves are weighted equally, which is the one number worth
  /// arguing about, so here is the argument. By content the diatonic seven are
  /// 7 of 12 degrees — 58%. But the five it leaves out are the hard ones: an
  /// altered degree has to be computed and its spelling chosen, where a scale
  /// degree is recalled. Weighting them by count alone would flatter the easy
  /// half, so the split is nudged to even. It is also the figure the app has
  /// always shown for a finished Diatonic, so nobody's number moves for a
  /// reason they cannot see.
  ///
  /// A third — the other candidate — would say that someone who plays all
  /// seven degrees of the scale instantly, in every position, knows a third of
  /// the key. Most of the music actually played in a key is those seven notes.
  ///
  /// Note to Number and the harmonizer are NOT folded in. They are different
  /// skills with their own dials; adding them here would redefine this number
  /// and the animal level with it, which is a decision to take on purpose.
  int get totalProgress =>
      ((diatonicReach + chromaticReach) / 2 * 100).round().clamp(0, 100);

  /// Raw evidence for one mode: what was actually scored in it, with no
  /// inference from the other. This is what the per-mode bars show — a bar
  /// labelled DIATONIC must report diatonic runs, not what chromatic runs
  /// imply about them.
  List<int> _cappedLevels(List<int> levels) =>
      List.generate(3, (i) => levels[i].clamp(0, kTierCaps[i]));

  KeyProgress copyWith({
    List<int>? diatonicLevels,
    List<int>? chromaticLevels,
    List<int>? harmonizerLevels,
    List<int>? ntnDiatonicLevels,
    List<int>? ntnChromaticLevels,
  }) {
    return KeyProgress(
      key: key,
      diatonicLevels: diatonicLevels ?? List.from(this.diatonicLevels),
      chromaticLevels: chromaticLevels ?? List.from(this.chromaticLevels),
      harmonizerLevels: harmonizerLevels ?? List.from(this.harmonizerLevels),
      ntnDiatonicLevels:
          ntnDiatonicLevels ?? List.from(this.ntnDiatonicLevels),
      ntnChromaticLevels:
          ntnChromaticLevels ?? List.from(this.ntnChromaticLevels),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'diatonicLevels': diatonicLevels,
        'chromaticLevels': chromaticLevels,
        'harmonizerLevels': harmonizerLevels,
        'ntnDiatonicLevels': ntnDiatonicLevels,
        'ntnChromaticLevels': ntnChromaticLevels,
      };

  // Saves written before the harmonizer existed simply have no such key, and
  // _levels turns that into a clean [0, 0, 0].
  factory KeyProgress.fromJson(Map<String, dynamic> json) => KeyProgress(
        key: json['key'] as String,
        diatonicLevels: _levels(json['diatonicLevels']),
        chromaticLevels: _levels(json['chromaticLevels']),
        harmonizerLevels: _levels(json['harmonizerLevels']),
        ntnDiatonicLevels: _levels(json['ntnDiatonicLevels']),
        ntnChromaticLevels: _levels(json['ntnChromaticLevels']),
      );

  // Tolerant parse: a single malformed value (e.g. a double from an import)
  // must not throw — the caller's catch would reset ALL keys to zero.
  static List<int> _levels(dynamic raw) {
    if (raw is! List) return [0, 0, 0];
    return List.generate(3, (i) {
      final v = i < raw.length ? raw[i] : 0;
      return v is num ? v.toInt() : 0;
    });
  }
}

const List<String> kDefaultKeyOrder = ['C', 'G', 'F', 'D', 'B♭', 'A', 'E♭', 'E', 'A♭', 'B', 'D♭', 'F♯'];
