import 'package:intl/intl.dart';

import '../constants/app_info.dart';
import '../constants/music_constants.dart';

/// The Daily Challenge: one shared run for the whole world, every day.
///
/// Everything is derived **deterministically from the date** — no backend, no
/// download: hashing the local date seeds a tiny self-contained PRNG which
/// picks the key of the day and the 10-question degree sequence. Two phones on
/// the same calendar day always build the exact same challenge, which is what
/// makes the score shareable ("same questions, beat me").
///
/// Local date by design (like Wordle): everyone plays "their" today.
class DailyChallenge {
  final String dateKey; // YYYY-MM-DD, same format as AppStats.dailyHistory
  final String key; // key of the day, e.g. 'B♭'
  final List<String> degrees; // the 10 diatonic degrees asked, in order

  const DailyChallenge({required this.dateKey, required this.key, required this.degrees});

  static const int questionCount = 10;

  factory DailyChallenge.forDate(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final rng = _Lcg(_fnv1a(dateKey));
    final key = kKeys[rng.next(kKeys.length)];

    // A seeded shuffle of all 7 degrees (everyone meets every degree), then 3
    // extra picks with no immediate repeat — 10 questions total.
    final base = ['1', '2', '3', '4', '5', '6', '7'];
    for (var i = base.length - 1; i > 0; i--) {
      final j = rng.next(i + 1);
      final t = base[i];
      base[i] = base[j];
      base[j] = t;
    }
    final degrees = List<String>.from(base);
    while (degrees.length < questionCount) {
      final d = base[rng.next(base.length)];
      if (d == degrees.last) continue;
      degrees.add(d);
    }
    return DailyChallenge(dateKey: dateKey, key: key, degrees: degrees);
  }

  // FNV-1a 32-bit — stable across every platform, unlike String.hashCode.
  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }
}

/// Park–Miller LCG. dart:math's Random is not guaranteed to yield identical
/// sequences on every platform (the web backend differs) — this is, and the
/// whole feature rests on that guarantee.
class _Lcg {
  int _s;
  _Lcg(int seed) : _s = seed & 0x7fffffff {
    if (_s == 0) _s = 1;
  }

  /// Uniform int in [0, max).
  int next(int max) {
    _s = (_s * 48271) % 0x7fffffff;
    return _s % max;
  }
}

/// The (single) attempt at one day's challenge. [answers] always holds one
/// flag per question — a run abandoned halfway is padded with misses, so the
/// share grid and the calendar never show a short row.
class DailyResult {
  final String dateKey;
  final String key;
  final List<bool> answers;
  final int timeMs; // sum of the answered questions' response times
  final bool completed; // false when the run was abandoned mid-way
  final int timestamp;

  const DailyResult({
    required this.dateKey,
    required this.key,
    required this.answers,
    required this.timeMs,
    required this.completed,
    required this.timestamp,
  });

  int get correct => answers.where((a) => a).length;
  int get total => answers.length;
  bool get perfect => completed && total > 0 && correct == total;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'key': key,
        'answers': answers,
        'timeMs': timeMs,
        'completed': completed,
        'timestamp': timestamp,
      };

  factory DailyResult.fromJson(Map<String, dynamic> json) => DailyResult(
        dateKey: json['dateKey'] ?? '',
        key: json['key'] ?? 'C',
        answers: (json['answers'] as List?)?.map((a) => a == true).toList() ?? [],
        timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
        completed: json['completed'] ?? false,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      );
}

/// Wordle-style share text — pasteable anywhere, renders as a story without
/// needing an image: date, key, score, time, the coloured grid, the streak.
String buildDailyShareText(DailyResult r, int streak) {
  DateTime d;
  try {
    d = DateTime.parse(r.dateKey);
  } catch (_) {
    d = DateTime.now();
  }
  final date = DateFormat('d MMM').format(d);
  final secs = (r.timeMs / 1000).round();
  final time = secs >= 60 ? '${secs ~/ 60}m ${(secs % 60).toString().padLeft(2, '0')}s' : '${secs}s';
  final grid = r.answers.map((a) => a ? '🟩' : '🟥').join();
  final flame = streak > 1 ? '\n🔥 $streak-day streak' : '';
  return 'Improvy Daily · $date\n'
      'Key of ${r.key} major · ${r.correct}/${r.total} · $time\n'
      '$grid$flame\n\n'
      '$kWebsiteUrl';
}
