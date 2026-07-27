class KeyProgress {
  final String key;
  final List<int> diatonicLevels; // [level1score, level2score, level3score]
  final List<int> chromaticLevels;
  // "…Of What?" — the harmonizer drill, where this note is given as a degree
  // and the player names the key it belongs to. Tracked per note, on the same
  // three-difficulty scale as the other modes.
  final List<int> harmonizerLevels;

  KeyProgress({
    required this.key,
    List<int>? diatonicLevels,
    List<int>? chromaticLevels,
    List<int>? harmonizerLevels,
  })  : diatonicLevels = diatonicLevels ?? [0, 0, 0],
        chromaticLevels = chromaticLevels ?? [0, 0, 0],
        harmonizerLevels = harmonizerLevels ?? [0, 0, 0];

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

  /// Key mastery stays diatonic + chromatic only: the harmonizer is a separate
  /// skill with its own dial, so adding it here would silently redefine every
  /// existing percentage on the home screen.
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
  }) {
    return KeyProgress(
      key: key,
      diatonicLevels: diatonicLevels ?? List.from(this.diatonicLevels),
      chromaticLevels: chromaticLevels ?? List.from(this.chromaticLevels),
      harmonizerLevels: harmonizerLevels ?? List.from(this.harmonizerLevels),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'diatonicLevels': diatonicLevels,
        'chromaticLevels': chromaticLevels,
        'harmonizerLevels': harmonizerLevels,
      };

  // Saves written before the harmonizer existed simply have no such key, and
  // _levels turns that into a clean [0, 0, 0].
  factory KeyProgress.fromJson(Map<String, dynamic> json) => KeyProgress(
        key: json['key'] as String,
        diatonicLevels: _levels(json['diatonicLevels']),
        chromaticLevels: _levels(json['chromaticLevels']),
        harmonizerLevels: _levels(json['harmonizerLevels']),
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
