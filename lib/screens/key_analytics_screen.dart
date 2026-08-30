import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/key_progress.dart';
import '../models/stats.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../widgets/note_text.dart';
import '../constants/app_scroll.dart';
import '../widgets/pressable_scale.dart';

// Roman labels for the 12 semitones (0..11), flat spellings only — used for
// the note the user actually tapped, where the keyboard gives no enharmonic
// spelling. Asked degrees use romanDegree() instead, which keeps all 15
// distinct spellings (♯II vs bIII, …).
const _romanLabels = ['I', 'bII', 'II', 'bIII', 'III', 'IV', 'bV', 'V', 'bVI', 'VI', 'bVII', 'VII'];

int? _noteSemi(String note) {
  final n = note.split('/')[0].trim();
  return kNoteToSemitone[n];
}

// Partial desaturation (saturation ≈ 0.2) — the locked per-tonality preview
// is mostly grey but keeps just a hint of colour. s=0.2 → each channel is
// lerp(luminance, itself, 0.2).
const List<double> _kDesaturated = <double>[
  0.37008, 0.57216, 0.05776, 0, 0,
  0.17008, 0.77216, 0.05776, 0, 0,
  0.17008, 0.57216, 0.25776, 0, 0,
  0,       0,       0,       1, 0,
];

class KeyAnalyticsScreen extends StatefulWidget {
  final String keyName;
  final VoidCallback onBack;
  final void Function([String? reason])? onShowPaywall;

  const KeyAnalyticsScreen({super.key, required this.keyName, required this.onBack, this.onShowPaywall});

  @override
  State<KeyAnalyticsScreen> createState() => _KeyAnalyticsScreenState();
}

class _KeyAnalyticsScreenState extends State<KeyAnalyticsScreen> {
  bool _last30 = false; // false = last 14 games, true = last 30 games
  int _selPoint = 6;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tone = widget.keyName;

    // Per-tonality analytics are Pro — except C. Locked keys render as a
    // greyed-out teaser with all displayed stats blanked to zero. The real
    // data stays stored untouched, so it appears the moment Pro is unlocked.
    final locked = !provider.isPro && tone != 'C';

    final keyIndex = provider.progressData.indexWhere((k) => k.key == tone);
    final keyData = (keyIndex >= 0 && !locked) ? provider.progressData[keyIndex] : KeyProgress(key: tone);
    // Match the tonality's colour to its row in the Skill Mastery list
    // (positional rainbow keyed by its index in progressData), not the
    // fixed per-note colour — so the two screens agree.
    final color = AppColors.keyColor(keyIndex.clamp(0, 11));

    // The headline, and the three families it is the mean of. Showing the
    // parts under the whole is what stops the number being a black box: a key
    // at 33% should say, on the same screen, which two thirds are missing.
    final mastery = keyData.totalProgress;
    final normal = keyData.normalProgress;
    final noteToNumber = keyData.noteToNumberProgress;
    // "…Of What?" is drilled per NOTE rather than per key — the one seam in
    // the figure above, and the reason this row keeps its own name.
    final harmonizer = keyData.harmonizerProgress;

    // Locked: feed empty history into every chart/stat below (display only —
    // the stored session history is not modified).
    final history = locked ? <SessionRecord>[] : provider.stats.sessionHistory;

    // ── Aggregate stats across all tones (for ranking) and for this tone ──
    final tonalityStats = <String, (int correct, int total, int rt, int rtN)>{};
    final degTone = <String, (int correct, int total)>{}; // roman label -> stats
    final confusions = <String, int>{}; // "asked→selected" roman -> count

    // Two windows on purpose: RANK and AVG RESP. compare the 12 keys over the
    // whole stored history (a stable cross-key comparison), while Degree
    // Mastery and Common Confusions describe the player NOW — they only count
    // the last 30 games in which this key was played, matching the game-based
    // windows used across the stats. A confusion drilled away months ago must
    // not haunt the card forever.
    // "…Of What?" answers store the fixed NOTE in `tonality` — that is not a
    // key context, so they must not leak into any per-key statistic here.
    bool inKey(dynamic a) => a.tonality == tone && a.mode != 'of-what';

    final recentToneSessions = history
        .where((s) => s.answers.any(inKey))
        .take(30)
        .toSet();

    for (final session in history) {
      final inWindow = recentToneSessions.contains(session);
      for (final ans in session.answers) {
        if (ans.mode == 'of-what') continue; // not key-playing (see inKey)
        final t = ans.tonality;
        final cur = tonalityStats[t] ?? (0, 0, 0, 0);
        // Timed-out questions count for accuracy but carry no speed info —
        // their responseTime is just the time limit of the difficulty played.
        final timed = ans.selectedNote.isNotEmpty;
        tonalityStats[t] = (
          cur.$1 + (ans.isCorrect ? 1 : 0),
          cur.$2 + 1,
          cur.$3 + (timed ? ans.responseTime : 0),
          cur.$4 + (timed ? 1 : 0),
        );

        if (t == tone && inWindow) {
          final deg = romanDegree(ans.degree);
          if (deg.isNotEmpty) {
            final d = degTone[deg] ?? (0, 0);
            degTone[deg] = (d.$1 + (ans.isCorrect ? 1 : 0), d.$2 + 1);
            if (!ans.isCorrect && ans.selectedNote.isNotEmpty) {
              final selSemi = _noteSemi(ans.selectedNote);
              final rootSemi = kNoteToSemitone[tone];
              if (selSemi != null && rootSemi != null) {
                final rel = ((selSemi - rootSemi) % 12 + 12) % 12;
                final key = '$deg for ${_romanLabels[rel]}';
                confusions[key] = (confusions[key] ?? 0) + 1;
              }
            }
          }
        }
      }
    }

    final toneStat = tonalityStats[tone] ?? (0, 0, 0, 0);
    final hasToneData = toneStat.$2 > 0;
    final avgResp = toneStat.$4 > 0 ? (toneStat.$3 / toneStat.$4).round() : 0;

    // Rank comes from the provider — the same computation the Skill Mastery
    // list uses, so tapping a key can't change its rank.
    final rank = provider.keyRanks[tone] ?? 0;

    // Chromatic degree mastery — all 15 degree spellings, enharmonics distinct
    final chromDegrees = kRomanDegrees.map((label) {
      final d = degTone[label] ?? (0, 0);
      final acc = d.$2 > 0 ? (d.$1 / d.$2 * 100).round() : 0;
      return (label: label, accuracy: acc);
    }).toList();

    // Common confusions (top 3, min 2 occurrences)
    final confList = confusions.entries.map((e) {
      final parts = e.key.split(' for ');
      final asked = parts[0];
      final selected = parts.length > 1 ? parts[1] : '';
      final totalAsked = degTone[asked]?.$2 ?? 0;
      final errorRate = totalAsked > 0 ? (e.value / totalAsked * 100).round() : 0;
      return (degree: asked, selectedDegree: selected, count: e.value, errorRate: errorRate);
    }).where((c) => c.count >= 2).toList()
      ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : b.errorRate.compareTo(a.errorRate));
    final topConfusions = confList.take(3).toList();

    // Trend (last 10 vs previous 10 answers for this tone)
    final toneAnswers = <bool>[];
    for (final s in history) {
      for (final a in s.answers) {
        if (inKey(a)) toneAnswers.add(a.isCorrect);
      }
    }
    double? trend;
    if (toneAnswers.length >= 20) {
      final cur = toneAnswers.take(10).where((v) => v).length / 10;
      final prev = toneAnswers.skip(10).take(10).where((v) => v).length / 10;
      trend = cur - prev;
    }

    // Accuracy-over-time chart points (7 buckets, y in 0..200 where 0 = 100%)
    final chartMs = _buildRtChart(history, tone, _last30 ? 30 : 14);
    final chartY = chartMs.map(_rtToY).toList();
    _selPoint = _selPoint.clamp(0, 6);
    // Response time at the scrubbed point, in seconds.
    final selMs = chartMs[_selPoint];

    // Change against the previous equal-length period. Faster is better, so
    // the sign is flipped before it reaches the arrow: a negative change in
    // milliseconds is a positive change in the player.
    double? speedDelta;
    {
      final toneSessions = history.where((s) =>
          (s.answers as List).any(inKey)).toList(); // newest-first
      double? rtOf(Iterable sessions) {
        int sum = 0, n = 0;
        for (final s in sessions) {
          for (final a in (s.answers as List)) {
            if (!inKey(a) || (a.selectedNote as String).isEmpty) continue;
            if ((a.responseTime as int) <= 0) continue;
            sum += a.responseTime as int;
            n++;
          }
        }
        return n > 0 ? sum / n : null;
      }
      final window = _last30 ? 30 : 14;
      if (toneSessions.length > window) {
        final cur = rtOf(toneSessions.take(window));
        final prev = rtOf(toneSessions.skip(window).take(window));
        if (cur != null && prev != null && prev > 0) {
          speedDelta = (prev - cur) / prev * 100;
        }
      }
    }

    final content = SingleChildScrollView(
      physics: kAppScrollPhysics,
          padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: back arrow (left) + KEY ANALYSIS badge centred on the
              // SAME line, so there is no empty space above it. Full width so
              // the badge stays centred even when the arrow is hidden (locked).
              SizedBox(
                height: 40,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!locked) Align(
                      alignment: Alignment.centerLeft,
                      child: PressableScale(
                        onTap: widget.onBack,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x08FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 20),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: Colors.white.withAlpha(26), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_note_rounded, size: 13, color: color),
                          const SizedBox(width: 6),
                          Text('KEY ANALYSIS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Hero tone letter on a soft glow in its note colour. The glow is
              // painted via OverflowBox so it does NOT inflate the layout — the
              // hero only takes the height of the letter itself.
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: OverflowBox(
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          alignment: Alignment.center,
                          child: Container(
                            width: 170, height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [color.withValues(alpha: 0.20), Colors.transparent],
                                stops: const [0.0, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    NoteText(
                      note: formatNoteForDisplay(tone, provider.notation),
                      style: TextStyle(
                        fontSize: 84, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -3, height: 1,
                        shadows: [Shadow(color: color.withValues(alpha: 0.55), blurRadius: 28)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── 3 stat cards ──
              // AVG RESP. and RANK are meaningless before the first game in
              // this key — a fresh key would otherwise claim "0ms" and "#1".
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'MASTERY', value: '$mastery', suffix: '%', trendUp: trend != null && trend > 0)),
                  const SizedBox(width: 12),
                  Expanded(child: hasToneData
                      ? _StatCard(label: 'AVG RESP.', value: '$avgResp', suffix: 'ms')
                      : const _StatCard(label: 'AVG RESP.', value: '—')),
                  const SizedBox(width: 12),
                  Expanded(child: hasToneData
                      ? _StatCard(label: 'RANK', value: '$rank', prefix: '#', suffix: '/12')
                      : const _StatCard(label: 'RANK', value: '—')),
                ],
              ),
              const SizedBox(height: 20),

              // ── Accuracy over time ──
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SectionTitle(icon: Icons.timeline_rounded, color: color, title: 'Response Time')),
                        // Speed growth badge sits in the space freed by the
                        // compact range toggle. Already sign-flipped, so up and
                        // green mean "quicker than you were".
                        if (speedDelta != null) ...[
                          Icon(speedDelta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: speedDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185), size: 16),
                          const SizedBox(width: 3),
                          Text('${speedDelta >= 0 ? "+" : ""}${speedDelta.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3,
                              color: speedDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185))),
                          const SizedBox(width: 12),
                        ],
                        // Segmented range toggle — same style as the Response Time
                        // toggle in the general stats, tinted with the tonality colour.
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withAlpha(13)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _RangeBtn(label: '30G', active: _last30, activeColor: color,
                              onTap: () => setState(() { _last30 = true; _selPoint = 6; })),
                            _RangeBtn(label: '14G', active: !_last30, activeColor: color,
                              onTap: () => setState(() { _last30 = false; _selPoint = 6; })),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Big accuracy value at the scrubbed point — stays here and
                    // updates as the dot moves (no tooltip over the point).
                    // With no games in this key yet there is nothing to show:
                    // a flat 0% line would read as terrible performance, not
                    // as absence of data. Sized boxes keep the card height.
                    if (!hasToneData)
                      const SizedBox(height: 32)
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(selMs > 0 ? (selMs / 1000).toStringAsFixed(2) : '—',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1, letterSpacing: -1.5)),
                          Text('s',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color.withAlpha(160), letterSpacing: -1)),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text('PER ANSWER',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(90), letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (!hasToneData)
                      const SizedBox(height: 108.0 + 28)
                    else
                      LayoutBuilder(
                        builder: (ctx, box) {
                          final w = box.maxWidth;
                          const h = 108.0;
                          return GestureDetector(
                            onTapDown: (d) => _updateSel(d.localPosition.dx, w),
                            onHorizontalDragUpdate: (d) => _updateSel(d.localPosition.dx, w),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: w, height: h + 28,
                              child: CustomPaint(
                                painter: _ChartPainter(ys: chartY, color: color, selected: _selPoint, chartH: h),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_last30 ? '30 GAMES AGO' : '14 GAMES AGO',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                            color: _selPoint == 0 ? Colors.white70 : Colors.white.withAlpha(77), letterSpacing: 1.5)),
                        Text('TODAY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                            color: _selPoint == 6 ? Colors.white70 : Colors.white.withAlpha(77), letterSpacing: 1.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Chromatic degree mastery ──
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(icon: Icons.analytics_rounded, color: color, title: 'Chromatic Degree Mastery'),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (ctx, box) {
                        final cellW = (box.maxWidth - 16) / 2;
                        return Wrap(
                          // Full rows span the whole width, so centring only
                          // moves the final odd cell to the middle.
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            for (final d in chromDegrees)
                              SizedBox(
                                width: cellW,
                                child: _DegreeMasteryCell(label: d.label, accuracy: d.accuracy, color: color),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Mode progress ──
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(icon: Icons.school_rounded, color: color, title: 'Mode Progress'),
                    const SizedBox(height: 20),
                    _ModeBar(label: 'DEGREE → NOTE', pct: normal, color: color),
                    const SizedBox(height: 18),
                    _ModeBar(label: 'NOTE → DEGREE', pct: noteToNumber, color: color),
                    const SizedBox(height: 18),
                    _ModeBar(label: '…OF WHAT?', pct: harmonizer, color: color),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Common confusions ──
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(icon: Icons.compare_arrows_rounded, color: color, title: 'Common Confusions'),
                    const SizedBox(height: 18),
                    if (topConfusions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.task_alt_rounded, size: 30, color: Colors.white.withAlpha(51)),
                            const SizedBox(height: 8),
                            Text('NO CONFUSIONS YET. GREAT JOB!',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withAlpha(102), letterSpacing: 1.2)),
                          ],
                        ),
                      )
                    else
                      ...topConfusions.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ConfusionRow(asked: c.degree, selected: c.selectedDegree, errorRate: c.errorRate, color: color),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Harmonizer ──
              // The note on its own, outside any key: how far "…Of What?" has
              // been drilled on it. The ring around the note IS the progress.
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOTE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                        color: Colors.white.withAlpha(102), letterSpacing: 1.5)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _HarmonizerRing(
                          note: formatNoteForDisplay(tone, provider.notation),
                          pct: harmonizer,
                          color: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harmonizer',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: Colors.white, letterSpacing: 0.2)),
                              const SizedBox(height: 3),
                              Text('“…Of What?” mastery',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(102))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$harmonizer%',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                            color: color, letterSpacing: -0.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: locked
            ? Stack(children: [
                // Greyed, faded, non-interactive preview; a tap anywhere opens
                // the paywall.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onShowPaywall?.call('key_stats'),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_kDesaturated),
                    child: Opacity(opacity: 0.72, child: AbsorbPointer(child: content)),
                  ),
                ),
                // Back arrow stays live and in colour — same button as Choose Mode.
                Positioned(
                  top: 4, left: 20,
                  child: PressableScale(
                    onTap: widget.onBack,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 20),
                    ),
                  ),
                ),
              ])
            : content,
      ),
    );
  }

  void _updateSel(double dx, double w) {
    final idx = ((dx / w) * 6).round().clamp(0, 6);
    if (idx != _selPoint) setState(() => _selPoint = idx);
  }

  // Build 7 bucket y-values (0..200, where 0 = 100% accuracy) for the tone.
  // "…Of What?" answers are excluded — their `tonality` is a fixed note, not
  // a key context (same rule as every per-key stat on this screen).
  /// Average response time in this key, in seven buckets across the window.
  /// Zero where there is nothing to say.
  ///
  /// This card used to plot accuracy, and accuracy is the one measure here
  /// that moves the WRONG WAY when you improve: the day you unlock Virtuoso
  /// the clock drops from 6s to 3.2s and your accuracy falls off a cliff. The
  /// chart showed a decline for what was unambiguously progress, which is why
  /// it was impossible to read.
  ///
  /// Response time has no such reversal. It is measured, not capped — a
  /// timed-out question is thrown away rather than recorded at the limit — so
  /// it falls whenever you actually get quicker, at any tier, and climbing a
  /// tier makes it fall faster rather than jump.
  ///
  /// "…Of What?" stays out. It asks you to search twelve keys rather than
  /// place one note, so its times are slower for a reason that has nothing to
  /// do with how well you know this key.
  List<int> _buildRtChart(List history, String tone, int limit) {
    bool inKey(dynamic a) => a.tonality == tone && a.mode != 'of-what';
    final sessions = history.where((s) =>
        (s.answers as List).any(inKey)).toList().reversed.toList();
    if (sessions.isEmpty) return List.filled(7, 0);

    final n = math.min(limit, sessions.length);
    final relevant = sessions.sublist(sessions.length - n);
    final buckets = List.generate(7, (_) => [0, 0]); // [sum ms, count]
    for (var i = 0; i < relevant.length; i++) {
      final bi = math.min(((i / relevant.length) * 7).floor(), 6);
      for (final a in (relevant[i].answers as List)) {
        // Timed out: its responseTime is the tier's limit, not the player's
        // speed, and averaging it in would make the line track the difficulty.
        if (!inKey(a) || (a.selectedNote as String).isEmpty) continue;
        if ((a.responseTime as int) <= 0) continue;
        buckets[bi][0] += a.responseTime as int;
        buckets[bi][1]++;
      }
    }
    for (var i = 0; i < 7; i++) {
      if (buckets[i][1] == 0 && i > 0 && buckets[i - 1][1] > 0) {
        buckets[i] = [buckets[i - 1][0], buckets[i - 1][1]];
      }
    }
    for (var i = 5; i >= 0; i--) {
      if (buckets[i][1] == 0 && buckets[i + 1][1] > 0) {
        buckets[i] = [buckets[i + 1][0], buckets[i + 1][1]];
      }
    }
    return buckets.map((b) => b[1] > 0 ? b[0] ~/ b[1] : 0).toList();
  }

  /// The painter's y axis runs 0 (top, best) to 200 (bottom). Four seconds is
  /// the floor: past that the difference between slow and slower says nothing
  /// worth a pixel, and a fixed ceiling keeps the line comparable month to
  /// month instead of rescaling under you every time your worst day drops off
  /// the window.
  static const int _rtFloorMs = 4000;

  static double _rtToY(int ms) =>
      ms <= 0 ? 200.0 : (ms / _rtFloorMs * 200).clamp(0.0, 200.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1625),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _SectionTitle({required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(33), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2))),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? prefix;
  final String? suffix;
  final bool trendUp;
  const _StatCard({required this.label, required this.value, this.prefix, this.suffix, this.trendUp = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1625),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(102), letterSpacing: 1.5)),
            const SizedBox(height: 8),
            // "#12/12" with a trend arrow is the widest this card ever gets,
            // and it ran past the edge on a 320dp phone. Scaling the whole
            // figure keeps the suffix — which is what makes a rank a rank.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (prefix != null)
                    Text(prefix!, maxLines: 1, softWrap: false, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(102))),
                  Text(value, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, height: 1)),
                  if (suffix != null)
                    Text(suffix!, maxLines: 1, softWrap: false, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(102))),
                  if (trendUp) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF22C55E)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _DegreeMasteryCell extends StatelessWidget {
  final String label;
  final int accuracy;
  final Color color;
  const _DegreeMasteryCell({required this.label, required this.accuracy, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32, height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withAlpha(33),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  // NoteText draws ♯/♭ from the bundled Noto Music font (a
                  // plain Text needs a runtime font download for ♯ — offline
                  // it renders a placeholder box).
                  child: NoteText(note: label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                ),
                Text('$accuracy%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
            const SizedBox(height: 10),
            _Bar(pct: accuracy / 100, color: color, height: 6),
          ],
        ),
      );
}

class _ModeBar extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  const _ModeBar({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(153), letterSpacing: 1.5)),
              Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          _Bar(pct: pct / 100, color: color, height: 12),
        ],
      );
}

class _ConfusionRow extends StatelessWidget {
  final String asked;
  final String selected;
  final int errorRate;
  final Color color;
  const _ConfusionRow({required this.asked, required this.selected, required this.errorRate, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _degBadge(asked, Colors.white.withAlpha(13), Colors.white, Colors.white.withAlpha(26)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white38),
                    ),
                    _degBadge(selected, const Color(0x1AF43F5E), const Color(0xFFF87171), const Color(0x33F43F5E)),
                  ],
                ),
                Text('$errorRate%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            _Bar(pct: errorRate / 100, color: color, height: 6),
          ],
        ),
      );

  Widget _degBadge(String label, Color bg, Color fg, Color border) => Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border, width: 1.2),
        ),
        // NoteText: bundled ♯/♭ glyphs, no runtime font download needed.
        child: NoteText(note: label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg)),
      );
}

class _Bar extends StatelessWidget {
  final double pct;
  final Color color;
  final double height;
  const _Bar({required this.pct, required this.color, required this.height});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          height: height,
          color: Colors.black.withAlpha(102),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      );
}

// ─── Harmonizer dial: the note in a ring that fills with its progress ─────────

class _HarmonizerRing extends StatelessWidget {
  final String note;
  final int pct;
  final Color color;
  const _HarmonizerRing({required this.note, required this.pct, required this.color});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _size, height: _size,
        child: CustomPaint(
          painter: _RingPainter(pct: pct / 100, color: color),
          child: Center(
            child: Padding(
              // Keep the label clear of the ring — solfège spellings ("Si♭")
              // are far wider than a single letter.
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NoteText(
                  note: note,
                  style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -0.5, height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double pct; // 0..1
  final Color color;
  _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    // Well inside the ring, so the fill never bleeds over the track.
    canvas.drawCircle(center, radius - stroke / 2, Paint()..color = Colors.white.withAlpha(8));
    canvas.drawCircle(
      center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withAlpha(20),
    );

    final v = pct.clamp(0.0, 1.0);
    if (v <= 0) return;

    final arc = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2; // 12 o'clock
    final sweep = 2 * math.pi * v;

    canvas.drawArc(arc, start, sweep, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 1.5
        ..strokeCap = StrokeCap.round
        ..color = color.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawArc(arc, start, sweep, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct || old.color != color;
}

// ─── Smooth line chart with gradient fill + selectable point ──────────────────

class _ChartPainter extends CustomPainter {
  final List<double> ys; // 0..200, 0 = top (100%)
  final Color color;
  final int selected;
  final double chartH;

  _ChartPainter({required this.ys, required this.color, required this.selected, required this.chartH});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const topPad = 14.0; // small top margin (no tooltip — value is in the header)
    final h = chartH;

    Offset pt(int i) => Offset(i / 6 * w, topPad + ys[i] / 200 * h);

    // Grid lines
    final grid = Paint()..color = Colors.white.withAlpha(13)..strokeWidth = 1;
    for (int g = 0; g <= 3; g++) {
      final y = topPad + g / 3 * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // Build smooth path (mirrors the web's S-curve smoothing)
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    Offset prevC2 = pt(0);
    for (int i = 0; i < 6; i++) {
      final p0 = pt(i), p1 = pt(i + 1);
      final c1 = i == 0 ? Offset(p0.dx + 20 / 400 * w, p0.dy) : Offset(2 * p0.dx - prevC2.dx, 2 * p0.dy - prevC2.dy);
      final c2 = Offset(p1.dx - 20 / 400 * w, p1.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p1.dx, p1.dy);
      prevC2 = c2;
    }

    // Dashed average reference line — same quiet detail as the stats chart.
    final avgY = topPad + (ys.reduce((a, b) => a + b) / ys.length) / 200 * h;
    final dash = Paint()..color = Colors.white.withAlpha(31)..strokeWidth = 1;
    for (double x = 0; x < w; x += 10) {
      canvas.drawLine(Offset(x, avgY), Offset(x + 5, avgY), dash);
    }

    // Gradient fill under the line (kept light, like the stats chart).
    final fill = Path.from(path)
      ..lineTo(w, topPad + h)
      ..lineTo(0, topPad + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(56), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, topPad, w, h)),
    );

    // Soft glow pass under a crisp thin line — the stats-chart language.
    final lineShader = LinearGradient(
      colors: [color, Color.lerp(color, Colors.white, 0.30)!],
    ).createShader(Rect.fromLTWH(0, topPad, w, h));
    final glowShader = LinearGradient(
      colors: [color.withAlpha(105), Color.lerp(color, Colors.white, 0.30)!.withAlpha(105)],
    ).createShader(Rect.fromLTWH(0, topPad, w, h));
    canvas.drawPath(path, Paint()
      ..shader = glowShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(path, Paint()
      ..shader = lineShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Selected point marker — refined ring with a soft halo.
    final sp = pt(selected);
    canvas.drawCircle(sp, 10, Paint()
      ..color = color.withAlpha(64)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(sp, 5.5, Paint()..color = const Color(0xFF1A1625));
    canvas.drawCircle(sp, 5.5, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.selected != selected || old.color != color || !_listEq(old.ys, ys);

  bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Segmented range button for the Accuracy Over Time chart — same style as the
// Response Time toggle in the general stats (a pill that lights up when active),
// tinted with the tonality colour. '30G' = last 30 games, '14G' = last 14 games.
class _RangeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  const _RangeBtn({required this.label, required this.active, required this.onTap, this.activeColor = const Color(0xFF3B82F6)});

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? activeColor.withAlpha(50) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
        color: active ? Color.lerp(activeColor, Colors.white, 0.3)! : Colors.white.withAlpha(77))),
    ),
  );
}
