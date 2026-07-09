import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/key_progress.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../widgets/note_text.dart';

// Roman labels for the 12 chromatic degrees, indexed by semitone (0..11).
const _romanLabels = ['I', 'bII', 'II', 'bIII', 'III', 'IV', 'bV', 'V', 'bVI', 'VI', 'bVII', 'VII'];

// Map a stored degree token (or extension) to a semitone offset 0..11.
const _tokenToSemi = {
  '1': 0,
  '♭2': 1, 'b2': 1, '♯1': 1,
  '2': 2,
  '♭3': 3, 'b3': 3, '♯2': 3,
  '3': 4,
  '4': 5,
  '♭5': 6, 'b5': 6, '♯4': 6,
  '5': 7,
  '♭6': 8, 'b6': 8, '♯5': 8,
  '6': 9,
  '♭7': 10, 'b7': 10,
  '7': 11,
  // jazz extensions
  '9': 2, '♭9': 1, '♯9': 3, '11': 5, '♯11': 6, '13': 9, '♭13': 8,
};

int? _degSemi(String deg) {
  if (_tokenToSemi.containsKey(deg)) return _tokenToSemi[deg];
  for (final part in deg.split('/')) {
    if (_tokenToSemi.containsKey(part)) return _tokenToSemi[part];
  }
  return null;
}

int? _noteSemi(String note) {
  final n = note.split('/')[0].trim();
  return kNoteToSemitone[n];
}

class KeyAnalyticsScreen extends StatefulWidget {
  final String keyName;
  final VoidCallback onBack;

  const KeyAnalyticsScreen({super.key, required this.keyName, required this.onBack});

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
    final keyIndex = provider.progressData.indexWhere((k) => k.key == tone);
    final keyData = keyIndex >= 0 ? provider.progressData[keyIndex] : KeyProgress(key: tone);
    // Match the tonality's colour to its row in the Skill Mastery list
    // (positional rainbow keyed by its index in progressData), not the
    // fixed per-note colour — so the two screens agree.
    final color = AppColors.keyColor(keyIndex.clamp(0, 11));

    final mastery = keyData.totalProgress;
    final diatonic = keyData.diatonicProgress;
    final chromatic = keyData.chromaticProgress;

    final history = provider.stats.sessionHistory;

    // ── Aggregate stats across all tones (for ranking) and for this tone ──
    final tonalityStats = <String, (int correct, int total, int rt)>{};
    final degTone = <int, (int correct, int total)>{}; // semitone -> stats
    final confusions = <String, int>{}; // "asked→selected" roman -> count

    for (final session in history) {
      for (final ans in session.answers) {
        final t = ans.tonality;
        final cur = tonalityStats[t] ?? (0, 0, 0);
        tonalityStats[t] = (cur.$1 + (ans.isCorrect ? 1 : 0), cur.$2 + 1, cur.$3 + ans.responseTime);

        if (t == tone) {
          final semi = _degSemi(ans.degree);
          if (semi != null) {
            final d = degTone[semi] ?? (0, 0);
            degTone[semi] = (d.$1 + (ans.isCorrect ? 1 : 0), d.$2 + 1);
            if (!ans.isCorrect && ans.selectedNote.isNotEmpty) {
              final selSemi = _noteSemi(ans.selectedNote);
              final rootSemi = kNoteToSemitone[tone];
              if (selSemi != null && rootSemi != null) {
                final rel = ((selSemi - rootSemi) % 12 + 12) % 12;
                final key = '${_romanLabels[semi]} for ${_romanLabels[rel]}';
                confusions[key] = (confusions[key] ?? 0) + 1;
              }
            }
          }
        }
      }
    }

    final toneStat = tonalityStats[tone] ?? (0, 0, 0);
    final avgResp = toneStat.$2 > 0 ? (toneStat.$3 / toneStat.$2).round() : 0;

    // Rank among the 12 keys (accuracy desc, then avg response asc)
    final ranked = [...kKeys]..sort((a, b) {
        final sa = tonalityStats[a] ?? (0, 0, 0);
        final sb = tonalityStats[b] ?? (0, 0, 0);
        final accA = sa.$2 > 0 ? sa.$1 / sa.$2 : 0.0;
        final accB = sb.$2 > 0 ? sb.$1 / sb.$2 : 0.0;
        if (accB != accA) return accB.compareTo(accA);
        final rA = sa.$2 > 0 ? sa.$3 / sa.$2 : 999999.0;
        final rB = sb.$2 > 0 ? sb.$3 / sb.$2 : 999999.0;
        return rA.compareTo(rB);
      });
    final rank = ranked.indexOf(tone) + 1;

    // Chromatic degree mastery (12 fixed labels)
    final chromDegrees = List.generate(12, (semi) {
      final d = degTone[semi] ?? (0, 0);
      final acc = d.$2 > 0 ? (d.$1 / d.$2 * 100).round() : 0;
      return (label: _romanLabels[semi], accuracy: acc);
    });

    // Common confusions (top 3, min 2 occurrences)
    final confList = confusions.entries.map((e) {
      final parts = e.key.split(' for ');
      final asked = parts[0];
      final selected = parts.length > 1 ? parts[1] : '';
      final askedSemi = _romanLabels.indexOf(asked);
      final totalAsked = (askedSemi >= 0 ? degTone[askedSemi]?.$2 : 0) ?? 0;
      final errorRate = totalAsked > 0 ? (e.value / totalAsked * 100).round() : 0;
      return (degree: asked, selectedDegree: selected, count: e.value, errorRate: errorRate);
    }).where((c) => c.count >= 2).toList()
      ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : b.errorRate.compareTo(a.errorRate));
    final topConfusions = confList.take(3).toList();

    // Trend (last 10 vs previous 10 answers for this tone)
    final toneAnswers = <bool>[];
    for (final s in history) {
      for (final a in s.answers) {
        if (a.tonality == tone) toneAnswers.add(a.isCorrect);
      }
    }
    double? trend;
    if (toneAnswers.length >= 20) {
      final cur = toneAnswers.take(10).where((v) => v).length / 10;
      final prev = toneAnswers.skip(10).take(10).where((v) => v).length / 10;
      trend = cur - prev;
    }

    // Accuracy-over-time chart points (7 buckets, y in 0..200 where 0 = 100%)
    final chartY = _buildChart(history, tone, _last30 ? 30 : 14);
    _selPoint = _selPoint.clamp(0, 6);
    // Accuracy at the scrubbed point — shown in a fixed spot in the header,
    // updating as the dot moves (matches the Response Time chart).
    final selAcc = (100 - chartY[_selPoint] / 200 * 100).round();

    // Accuracy growth vs the previous equal-length period (same tone), shown
    // next to the value like the general ACCURACY stat: green up / red down.
    double? accuracyDelta;
    {
      final toneSessions = history.where((s) =>
          (s.answers as List).any((a) => a.tonality == tone)).toList(); // newest-first
      double accOf(Iterable sessions) {
        int c = 0, t = 0;
        for (final s in sessions) {
          for (final a in (s.answers as List)) {
            if (a.tonality == tone) { t++; if (a.isCorrect) c++; }
          }
        }
        return t > 0 ? c / t : 0;
      }
      final window = _last30 ? 30 : 14;
      if (toneSessions.length > window) {
        final cur = accOf(toneSessions.take(window));
        final prev = accOf(toneSessions.skip(window).take(window));
        if (prev > 0) accuracyDelta = (cur - prev) / prev * 100;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: back arrow (left) + KEY ANALYSIS badge centred on the
              // SAME line, so there is no empty space above it.
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(26), width: 1.2),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
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
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'MASTERY', value: '$mastery', suffix: '%', trendUp: trend != null && trend > 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'AVG RESP.', value: '$avgResp', suffix: 'ms')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'RANK', value: '$rank', prefix: '#', suffix: '/12')),
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
                        Expanded(child: _SectionTitle(icon: Icons.timeline_rounded, color: color, title: 'Accuracy Over Time')),
                        // Accuracy growth badge sits in the space freed by the
                        // compact range toggle (green up / red down).
                        if (accuracyDelta != null) ...[
                          Icon(accuracyDelta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: accuracyDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185), size: 16),
                          const SizedBox(width: 3),
                          Text('${accuracyDelta >= 0 ? "+" : ""}${accuracyDelta.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3,
                              color: accuracyDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185))),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$selAcc',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1, letterSpacing: -1.5)),
                        Text('%',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color.withAlpha(160), letterSpacing: -1)),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('ACCURACY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(90), letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    _ModeBar(label: 'DIATONIC MODE', pct: diatonic, color: color),
                    const SizedBox(height: 18),
                    _ModeBar(label: 'CHROMATIC MODE', pct: chromatic, color: color),
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
            ],
          ),
        ),
      ),
    );
  }

  void _updateSel(double dx, double w) {
    final idx = ((dx / w) * 6).round().clamp(0, 6);
    if (idx != _selPoint) setState(() => _selPoint = idx);
  }

  // Build 7 bucket y-values (0..200, where 0 = 100% accuracy) for the tone.
  List<double> _buildChart(List history, String tone, int limit) {
    final sessions = history.where((s) =>
        (s.answers as List).any((a) => a.tonality == tone)).toList().reversed.toList();
    if (sessions.isEmpty) return List.filled(7, 200.0);

    final n = math.min(limit, sessions.length);
    final relevant = sessions.sublist(sessions.length - n);
    final buckets = List.generate(7, (_) => [0, 0]); // [correct, total]
    for (var i = 0; i < relevant.length; i++) {
      final bi = math.min(((i / relevant.length) * 7).floor(), 6);
      for (final a in (relevant[i].answers as List)) {
        if (a.tonality == tone) {
          buckets[bi][1]++;
          if (a.isCorrect) buckets[bi][0]++;
        }
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
    return buckets.map((b) {
      final acc = b[1] > 0 ? b[0] / b[1] : 0.0;
      return 200 - acc * 200;
    }).toList();
  }
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (prefix != null)
                  Text(prefix!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(102))),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, height: 1)),
                if (suffix != null)
                  Text(suffix!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(102))),
                if (trendUp) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF22C55E)),
                ],
              ],
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
                  child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
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
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg)),
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
  Widget build(BuildContext context) => GestureDetector(
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
