import 'package:intl/intl.dart';

import '../constants/app_info.dart';
import '../constants/music_constants.dart';
import '../utils/music_engine.dart';
import 'training_mode.dart';

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
  /// Key of the day ('B♭') — or, in [TrainingMode.ofWhat], the melody note the
  /// whole run is built on, since that mode has no tonality.
  final String key;
  final List<String> degrees; // the questions asked, in order
  /// Which of the three directions today is. Seeded from the date like
  /// everything else, so the whole world gets the same one.
  final TrainingMode mode;

  const DailyChallenge({
    required this.dateKey,
    required this.key,
    required this.degrees,
    this.mode = TrainingMode.chromatic,
  });

  /// The three directions the daily rotates through.
  ///
  /// Naming the note for a degree, naming the degree for a note, and naming the
  /// root a note belongs to are three different skills — the first two are
  /// famously not the same recall, and the third is the one that turns a melody
  /// into changes. A challenge that only ever asked the first was testing a
  /// third of what the app teaches.
  ///
  /// Order matters: it is indexed by the date seed, so appending is safe and
  /// reordering silently rewrites history.
  static const List<TrainingMode> modes = [
    TrainingMode.chromatic, // degree → note
    TrainingMode.noteToNumber, // note → degree
    TrainingMode.ofWhat, // note is a degree → name the root
  ];

  /// The 12 roots …Of What? can answer with, and so the notes it can be built
  /// on. Plain spellings: this mode names roots, not scale degrees.
  static const List<String> ofWhatNotes = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',
  ];

  /// Fifteen, not ten. At ten questions a single slip is a tenth of the score,
  /// so the number measured luck as much as skill — and a score that noisy is
  /// not worth sharing. Fifteen also fits the twelve chromatic degrees with
  /// only three repeats, where ten diatonic degrees meant seeing the same
  /// seven notes over and over.
  static const int questionCount = 15;

  /// Budget each question is worth, for the direction being asked. Not a
  /// per-question limit — the clock below is pooled — but the honest way to
  /// size the pool.
  ///
  /// 2.8s is deliberately under the trainer's own medium tier (3.2s): the
  /// daily is meant to be the hardest thing you do that day, and at 4s it was
  /// softer than an ordinary Virtuoso session. A confident answer takes about
  /// 2s, so a clean run still lands with a little spare while a hesitant one
  /// genuinely runs out.
  ///
  /// …Of What? gets 3.6s because it is a genuinely longer question: you hold a
  /// note, apply a degree, and name the root it implies. Every player still
  /// gets the same clock on the same day — this keeps a Wednesday from being
  /// brutal purely because of which direction the seed drew.
  static int msPerQuestionFor(TrainingMode mode) =>
      mode == TrainingMode.ofWhat ? 3600 : 2800;

  int get msPerQuestion => msPerQuestionFor(mode);

  /// **One clock for the whole run**, not a per-question limit like the other
  /// modes. That is the shape of a challenge — you spend the budget how you
  /// like, so lingering on a hard degree costs you the easy ones later.
  /// Identical for everyone, which is what makes a shared score mean something.
  /// When it runs out the run ends where it stands and the unanswered questions
  /// count as misses.
  ///
  /// Scales with [questionCount] by construction: change the number of
  /// questions and the budget follows instead of silently becoming wrong.
  int get totalTimeMs => questionCount * msPerQuestion;

  /// The rule, in words, for every surface that states it — the card, both home
  /// screen widgets, the store listing. Built from the numbers above so the
  /// promise can never drift from the clock the run actually uses.
  String get rule => '$questionCount questions · ${totalTimeMs ~/ 1000} seconds';

  /// What today asks, in three words, for the card and the widgets. The player
  /// should know before tapping whether they are naming notes or roots.
  String get modeLabel => switch (mode) {
        TrainingMode.noteToNumber => 'Note to Number',
        TrainingMode.ofWhat => '…Of What?',
        _ => 'Chromatic',
      };

  /// What comes before [key] wherever the card and widgets announce the run.
  /// …Of What? has no tonality, so calling its note a key would be a plain
  /// lie — the run is built *on* that note, it is not in it.
  String get subjectPrefix => mode == TrainingMode.ofWhat ? 'On ' : 'Key of ';

  /// Mastery tier the daily's answers are filed under (medium). The daily has
  /// no per-question clock, so this no longer sets a countdown — it only keeps
  /// the recorded difficulty honest, since key mastery is tracked per tier.
  static const int difficulty = 2;

  factory DailyChallenge.forDate(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final rng = _Lcg(_fnv1a(dateKey));

    // Drawn first, so the mode is a property of the date rather than of
    // whatever happened to be drawn before it.
    final mode = modes[rng.next(modes.length)];

    // …Of What? has no tonality: what it needs is the note every question is
    // built on. The other two need the key of the day.
    final key = mode == TrainingMode.ofWhat
        ? ofWhatNotes[rng.next(ofWhatNotes.length)]
        : kKeys[rng.next(kKeys.length)];

    // The pool the direction can actually ask.
    //
    // Chromatic asks the twelve collapsed degrees — not diatonic: the challenge
    // of the day should be able to ask for the ♯4, not only the seven easy
    // ones. Note→Number splits the enharmonics, because there a note's spelling
    // *is* the question (F is the ♭3, E♯ the ♯2). …Of What? keeps only the
    // degrees that give this note a clean root — B♭ as a ♯2 would be A𝄫, which
    // is not a chord anybody plays — and drops degree 1, which hands the answer
    // over by naming the note itself.
    final base = switch (mode) {
      TrainingMode.noteToNumber => List<String>.from(kChromaticDegreesSplit),
      TrainingMode.ofWhat => kOfWhatDegrees
          .where((d) => d != '1' && rootFromNoteAndDegree(key, d) != null)
          .toList(),
      _ => List<String>.from(kChromaticDegrees),
    };

    // A seeded shuffle of the pool (everyone meets every degree), then extra
    // picks with no immediate repeat, up to questionCount.
    for (var i = base.length - 1; i > 0; i--) {
      final j = rng.next(i + 1);
      final t = base[i];
      base[i] = base[j];
      base[j] = t;
    }
    // Cannot happen with the pools above — every note has clean roots for most
    // degrees — but an empty pool would loop forever on the fill below, and a
    // challenge that hangs is worse than one that is a little plain.
    if (base.isEmpty) base.add('5');
    final degrees = List<String>.from(base.take(questionCount));
    while (degrees.length < questionCount) {
      final d = base[rng.next(base.length)];
      if (d == degrees.last) continue;
      degrees.add(d);
    }
    return DailyChallenge(
        dateKey: dateKey, key: key, degrees: degrees, mode: mode);
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
  /// Which direction that day asked. Results saved before the daily rotated
  /// modes carry no value and read back as chromatic, which is what they were.
  final TrainingMode mode;

  const DailyResult({
    required this.dateKey,
    required this.key,
    required this.answers,
    required this.timeMs,
    required this.completed,
    required this.timestamp,
    this.mode = TrainingMode.chromatic,
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
        'mode': mode.storageKey,
      };

  factory DailyResult.fromJson(Map<String, dynamic> json) => DailyResult(
        dateKey: json['dateKey'] ?? '',
        key: json['key'] ?? 'C',
        answers: (json['answers'] as List?)?.map((a) => a == true).toList() ?? [],
        timeMs: (json['timeMs'] as num?)?.toInt() ?? 0,
        completed: json['completed'] ?? false,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        mode: TrainingMode.values.firstWhere(
          (m) => m.storageKey == json['mode'],
          orElse: () => TrainingMode.chromatic,
        ),
      );
}

/// Wordle-style share text — pasteable anywhere, renders as a story without
/// needing an image: date, key, score, time, the coloured grid, the streak.
///
/// [installUrl] is the address the reader can install from — callers pass
/// `installUrlFor(defaultTargetPlatform, isWeb: kIsWeb)` so this stays pure.
/// Defaults to the site, which is right for every platform and never dead.
String buildDailyShareText(DailyResult r, int streak, {String? installUrl}) {
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
  // The daily rotates direction, so the line has to say which one it was —
  // otherwise two scores from different days read as the same challenge, and
  // "Key of B♭ major" is plainly wrong on a day with no tonality at all.
  final subject = r.mode == TrainingMode.ofWhat
      ? '${r.key} …of what?'
      : 'Key of ${r.key} major';
  final direction = switch (r.mode) {
    TrainingMode.noteToNumber => ' · note→number',
    TrainingMode.ofWhat => '',
    _ => '',
  };
  return 'Improvy Daily · $date\n'
      '$subject$direction · ${r.correct}/${r.total} · $time\n'
      '$grid$flame\n\n'
      '${installUrl ?? kWebsiteUrl}';
}
