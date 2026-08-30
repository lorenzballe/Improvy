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

  /// Key mastery stays diatonic + chromatic only. The harmonizer and Note to
  /// Number are separate skills with their own dials; folding either in here
  /// would silently redefine every percentage already on the home screen — and
  /// with it the animal level, which reads the average of this. Whether they
  /// should eventually feed it is a deliberate decision, not a side effect.
  int get totalProgress {
    final dCapped = _cappedLevels(diatonicLevels);
    final cCapped = _cappedLevels(chromaticLevels);
    final total = [...dCapped, ...cCapped].reduce((a, b) => a + b);
    return (total / 240 * 100).round().clamp(0, 100);
  }

  List<int> _cappedLevels(List<int> levels) {
    final caps = [30, 40, 50];
    return List.generate(3, (i) => levels[i].clamp(0, caps[i]));
  }

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
