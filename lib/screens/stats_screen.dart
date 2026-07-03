import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/stats.dart';
import '../constants/app_colors.dart';
import '../widgets/note_text.dart';
import '../widgets/animal_icon.dart';
import 'key_analytics_screen.dart';

// ─── DEGREE DATA ─────────────────────────────────────────────────────────────

const _degrees = [
  ('I', Color(0xFFEF4444)),
  ('bII', Color(0xFFF97316)),
  ('II', Color(0xFFF59E0B)),
  ('♯II', Color(0xFFEAB308)),
  ('bIII', Color(0xFFEAB308)),
  ('III', Color(0xFF84CC16)),
  ('IV', Color(0xFF22C55E)),
  ('♯IV', Color(0xFF10B981)),
  ('bV', Color(0xFF10B981)),
  ('V', Color(0xFF06B6D4)),
  ('♯V', Color(0xFF3B82F6)),
  ('bVI', Color(0xFF3B82F6)),
  ('VI', Color(0xFF6366F1)),
  ('bVII', Color(0xFF8B5CF6)),
  ('VII', Color(0xFFD946EF)),
];

const _keySignatures = {
  'C': 'NONE', 'G': '1 SHARP', 'D': '2 SHARPS', 'A': '3 SHARPS',
  'E': '4 SHARPS', 'B': '5 SHARPS', 'F♯': '6 SHARPS',
  'D♭': '5 FLATS', 'A♭': '4 FLATS', 'E♭': '3 FLATS', 'B♭': '2 FLATS', 'F': '1 FLAT',
};

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  String? _analyticsKey;
  String _rtRange = '7';
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut);
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    if (_analyticsKey != null) {
      return KeyAnalyticsScreen(
        keyName: _analyticsKey!,
        onBack: () {
          context.read<AppProvider>().setViewingKeyStats(false);
          setState(() => _analyticsKey = null);
        },
      );
    }

    final provider = context.watch<AppProvider>();
    final stats = provider.stats;
    final animalLevel = provider.animalLevel;
    final totalProgress = provider.totalProgress;
    final overallAccuracy = provider.overallAccuracy;
    final streak = provider.streak;
    final totalAttempts = stats.totalAttempts;

    // Accuracy change
    double? accuracyChange;
    if (stats.sessionHistory.length >= 60) {
      double acc(int s, int e) {
        final sl = stats.sessionHistory.sublist(s, e);
        final t = sl.fold<int>(0, (a, r) => a + r.total);
        final c = sl.fold<int>(0, (a, r) => a + r.correct);
        return t > 0 ? c / t : 0;
      }
      final cur = acc(0, 30), prev = acc(30, 60);
      if (prev > 0) accuracyChange = (cur - prev) / prev * 100;
    }

    // Response time per day (last 30d)
    final now = DateTime.now();
    final monthlyRt = List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final ds = stats.dailyHistory[k];
      if (ds == null || ds.attempts == 0) return 0;
      return (ds.responseTime / ds.attempts).round();
    });
    final displayRt = _rtRange == '7' ? monthlyRt.sublist(23) : monthlyRt;
    final validRt = displayRt.where((t) => t > 0);
    final avgRt = validRt.isEmpty ? 0 : validRt.reduce((a, b) => a + b) ~/ validRt.length;

    // ── Per-key rank (web parity): rank by total average response time across
    // diatonic + chromatic; keys with no data are unranked (rank 0 → faded). ──
    final modeTimes = <String, List<int>>{}; // key -> [dCount, dTime, cCount, cTime]
    for (final s in stats.sessionHistory) {
      for (final a in s.answers) {
        final mi = a.mode == 'diatonic' ? 0 : (a.mode == 'chromatic' ? 2 : -1);
        if (mi < 0) continue;
        final m = modeTimes.putIfAbsent(a.tonality, () => [0, 0, 0, 0]);
        m[mi] += 1;
        m[mi + 1] += a.responseTime;
      }
    }
    double rankScore(String key) {
      final m = modeTimes[key];
      if (m == null) return 200000;
      final dAvg = m[0] > 0 ? m[1] / m[0] : 100000.0;
      final cAvg = m[2] > 0 ? m[3] / m[2] : 100000.0;
      return dAvg + cAvg;
    }
    final rankedKeys = provider.progressData.map((k) => k.key).toList()
      ..sort((a, b) {
        final sa = rankScore(a), sb = rankScore(b);
        return sa == sb ? a.compareTo(b) : sa.compareTo(sb);
      });
    final keyRanks = <String, int>{
      for (final k in provider.progressData)
        k.key: (modeTimes[k.key] != null && (modeTimes[k.key]![0] > 0 || modeTimes[k.key]![2] > 0))
            ? rankedKeys.indexOf(k.key) + 1
            : 0,
    };

    // Sessions per day (last 7d)
    final weeklySessions = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return stats.dailyHistory[k]?.sessions ?? 0;
    });
    final weekDays = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
      return days[d.weekday % 7];
    });

    // Degree stats from last 30d sessions
    final thirtyAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final recentSessions = stats.sessionHistory.where((s) => s.timestamp >= thirtyAgo).toList();
    final Map<String, ({int correct, int total})> degreeStats = {};
    for (final session in recentSessions) {
      for (final ans in session.answers) {
        final deg = _normalizeDeg(ans.degree);
        if (deg.isEmpty) continue;
        final cur = degreeStats[deg] ?? (correct: 0, total: 0);
        degreeStats[deg] = (
          correct: cur.correct + (ans.isCorrect ? 1 : 0),
          total: cur.total + 1,
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 140 + MediaQuery.of(context).padding.bottom),
          child: Column(
            children: [
              // ── TOP: badge + ring + 3 cards ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(children: [
                  // Level badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1625),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: animalLevel.color, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('LEVEL ${animalLevel.level}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(128), letterSpacing: 4)),
                      const SizedBox(width: 14),
                      AnimalIcon(name: animalLevel.name, color: animalLevel.color, size: 20),
                      const SizedBox(width: 6),
                      Text(animalLevel.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: animalLevel.color, letterSpacing: 2)),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // Circular progress ring
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, _) {
                      final p = totalProgress * _progressAnim.value;
                      return SizedBox(
                        width: 218, height: 218,
                        child: Stack(alignment: Alignment.center, children: [
                          CustomPaint(size: const Size(218, 218), painter: _RingPainter(progress: p / 100)),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [Color(0xFF22D3EE), Color(0xFF818CF8), Color(0xFFF472B6)],
                                ).createShader(b),
                                child: Text('${p.round()}%',
                                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -3)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('OVERALL\nPROFICIENCY', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(102), letterSpacing: 2.25, height: 1.4)),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 3 mini stat cards
                  Row(children: [
                    Expanded(child: _MiniCard(label: 'NOTES', value: _fmt(totalAttempts), glowColor: const Color(0xFF3B82F6))),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniCard(
                      label: 'ACCURACY', value: '$overallAccuracy', valueSuffix: '%',
                      trend: accuracyChange, glowColor: const Color(0xFF10B981),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniCard(label: 'STREAK', value: '$streak', isStreak: true, glowColor: const Color(0xFFF97316))),
                  ]),
                ]),
              ),

              // ── Divider ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white10, Colors.transparent]))),
                  const SizedBox(height: 12),
                  Text('STATISTICS BASED ON THE LAST 30 DAYS',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(77), letterSpacing: 1.8)),
                ]),
              ),

              // ── Response Time ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _ResponseTimeCard(displayTimes: displayRt, avgMs: avgRt, range: _rtRange, onRange: (r) => setState(() => _rtRange = r)),
              ),

              // ── Degree Accuracy ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _DegreeAccuracyCard(degreeStats: degreeStats),
              ),

              // ── Games Played ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _GamesPlayedCard(sessions: weeklySessions, days: weekDays, total: stats.totalSessions),
              ),

              // ── Keyboard Heatmap ──
              _KeyboardHeatmapCard(sessionHistory: stats.sessionHistory),

              // ── Skill Mastery ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFA855F7), size: 22),
                    SizedBox(width: 8),
                    Text('Skill Mastery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  ]),
                  const SizedBox(height: 16),
                  ...provider.progressData.asMap().entries.map((e) {
                    final color = AppColors.keyColor(e.key);
                    return GestureDetector(
                      onTap: () {
                        provider.setViewingKeyStats(true);
                        setState(() => _analyticsKey = e.value.key);
                      },
                      child: _SkillRow(keyData: e.value, color: color, index: e.key, rank: keyRanks[e.value.key] ?? 0),
                    );
                  }),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _normalizeDeg(String deg) {
    const map = {'9': '2', '♭9': 'bII', '♯9': '♯II', '11': '4', '♯11': '♯IV', '13': '6', '♭13': 'bVI'};
    return map[deg] ?? deg;
  }
}

// ─── CIRCULAR RING PAINTER ────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  // Matches the web app's `.rainbow-ring` conic-gradient exactly:
  // red 0%, orange 15%, yellow 30%, green 45%, blue 60%, purple 75%, red 100%.
  static const _rainbowColors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFFEF4444),
  ];
  static const _rainbowStops = [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 1.0];

  // Color at fraction t (0..1) around the ring, interpolating through the
  // stops above. Flutter's SweepGradient renders this unevenly, so we sample
  // it ourselves and paint discrete segments for a perfectly uniform blend.
  static Color _colorAt(double t) {
    t = t.clamp(0.0, 1.0);
    for (int i = 0; i < _rainbowStops.length - 1; i++) {
      final s0 = _rainbowStops[i], s1 = _rainbowStops[i + 1];
      if (t <= s1) {
        final local = (t - s0) / (s1 - s0);
        return Color.lerp(_rainbowColors[i], _rainbowColors[i + 1], local)!;
      }
    }
    return _rainbowColors.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeW = 9.0;

    // Background track — rgba(255,255,255,0.05)
    final bgPaint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Level ticks
    const ticks = [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5];
    for (final t in ticks) {
      final angle = -math.pi / 2 + (t / 100) * 2 * math.pi;
      final outer = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      final inner = Offset(center.dx + (radius - 14) * math.cos(angle), center.dy + (radius - 14) * math.sin(angle));
      final tickPaint = Paint()
        ..color = progress * 100 >= t ? Colors.white.withAlpha(200) : Colors.white24
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Rainbow progress arc, drawn as uniform discrete segments. Colors are
    // anchored to angular position (like the web's fixed conic gradient) and
    // only the 0..progress portion is revealed.
    final rect = Rect.fromCircle(center: center, radius: radius);
    const segments = 180;
    final visible = (segments * progress).ceil();
    final segAngle = 2 * math.pi / segments;
    final segPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    for (int i = 0; i < visible; i++) {
      final frac = i / segments; // angular position around the full circle
      final a0 = -math.pi / 2 + i * segAngle;
      segPaint.color = _colorAt(frac + 0.5 / segments);
      // Slight overlap each side avoids anti-alias seams between segments.
      canvas.drawArc(rect, a0 - 0.004, segAngle + 0.008, false, segPaint);
    }

    // Progress tip dot — 12×12, white, with glow
    final sweepAngle = progress * 2 * math.pi;
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipPos = Offset(center.dx + radius * math.cos(tipAngle), center.dy + radius * math.sin(tipAngle));

    final glowPaint = Paint()
      ..color = Colors.white.withAlpha(77)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(tipPos, 8, glowPaint);

    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(tipPos, 6, dotPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── MINI STAT CARD ───────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String? valueSuffix;
  final double? trend;
  final bool isStreak;
  final Color glowColor;

  const _MiniCard({required this.label, required this.value, this.valueSuffix, this.trend, this.isStreak = false, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        borderRadius: BorderRadius.circular(24),
        border: isStreak
            ? Border.all(color: const Color(0xFFF97316).withAlpha(128), width: 1)
            : Border.all(color: Colors.white.withAlpha(13)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 16, offset: const Offset(0, 8)),
          if (isStreak) BoxShadow(color: const Color(0xFFF97316).withAlpha(38), blurRadius: 20),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: TextStyle(
            fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8,
            color: isStreak ? const Color(0xFFFED7AA).withAlpha(153) : Colors.white.withAlpha(102))),
        ),
        const SizedBox(height: 8),
        if (isStreak)
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1.5)))),
            ]),
          )
        else
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: glowColor, height: 1, letterSpacing: -1.5)))),
            if (valueSuffix != null) Text(valueSuffix!,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: glowColor.withAlpha(178))),
          ]),
        if (trend != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(trend! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: trend! >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185), size: 12),
              const SizedBox(width: 2),
              Text('${trend! >= 0 ? "+" : ""}${trend!.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: -0.4,
                  color: trend! >= 0 ? const Color(0xFF10B981) : const Color(0xFFFB7185))),
            ]),
          ),
      ]),
    );
  }
}

// ─── RESPONSE TIME CARD ───────────────────────────────────────────────────────

class _ResponseTimeCard extends StatefulWidget {
  final List<int> displayTimes;
  final int avgMs;
  final String range;
  final ValueChanged<String> onRange;

  const _ResponseTimeCard({required this.displayTimes, required this.avgMs, required this.range, required this.onRange});

  @override
  State<_ResponseTimeCard> createState() => _ResponseTimeCardState();
}

class _ResponseTimeCardState extends State<_ResponseTimeCard> {
  int? _selectedIndex;
  bool _isDragging = false;

  @override
  void didUpdateWidget(covariant _ResponseTimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range || oldWidget.displayTimes != widget.displayTimes) {
      _selectedIndex = null;
      _isDragging = false;
    }
  }

  String _formatDate(int index, String range) {
    final now = DateTime.now();
    final daysAgo = (range == '7' ? 6 : 29) - index;
    if (daysAgo == 0) return 'TODAY';
    if (daysAgo == 1) return 'YESTERDAY';
    final d = now.subtract(Duration(days: daysAgo));
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[d.month - 1]} ${d.day}';
  }

  void _handleDrag(double localX, double width) {
    final values = widget.displayTimes;
    if (values.isEmpty) return;
    final double fraction = localX / width;
    final int index = (fraction * (values.length - 1)).round().clamp(0, values.length - 1);
    setState(() {
      _selectedIndex = index;
      _isDragging = true;
    });
  }

  void _cancelDrag() {
    setState(() {
      _isDragging = false;
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showDragValue = _isDragging && _selectedIndex != null && _selectedIndex! < widget.displayTimes.length;
    final int valueToShow = showDragValue ? widget.displayTimes[_selectedIndex!] : widget.avgMs;
    
    String labelToShow;
    if (showDragValue) {
      final dateStr = _formatDate(_selectedIndex!, widget.range);
      if (valueToShow == 0) {
        labelToShow = 'No sessions • $dateStr';
      } else {
        labelToShow = 'Response Time • $dateStr';
      }
    } else {
      labelToShow = 'Response Time';
    }

    final String valueText = valueToShow == 0 ? '—' : '$valueToShow';
    final String suffixText = valueToShow == 0 ? '' : 'ms';

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1625),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withAlpha(26)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.timer_rounded, color: Color(0xFF60A5FA), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labelToShow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
              ),
              // Range toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _RangeBtn(label: '7D', active: widget.range == '7', onTap: () => widget.onRange('7')),
                  _RangeBtn(label: '30D', active: widget.range == '30', onTap: () => widget.onRange('30')),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            // Avg time — gradient text
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF22D3EE)]).createShader(b),
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(valueText, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1, letterSpacing: -1.5)),
                if (suffixText.isNotEmpty)
                  Text(suffixText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(102), letterSpacing: -1.5)),
              ]),
            ),
            const SizedBox(height: 20),
            // Line chart — fits the container width to allow touch scrubbing
            SizedBox(
              height: 90,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  return GestureDetector(
                    onHorizontalDragStart: (details) => _handleDrag(details.localPosition.dx, c.maxWidth),
                    onHorizontalDragUpdate: (details) => _handleDrag(details.localPosition.dx, c.maxWidth),
                    onHorizontalDragEnd: (_) => _cancelDrag(),
                    onHorizontalDragCancel: _cancelDrag,
                    onTapDown: (details) => _handleDrag(details.localPosition.dx, c.maxWidth),
                    onTapUp: (_) => _cancelDrag(),
                    onTapCancel: _cancelDrag,
                    child: SizedBox(
                      width: c.maxWidth,
                      height: 90,
                      child: CustomPaint(
                        size: Size(c.maxWidth, 90),
                        painter: _LineChartPainter(
                          values: widget.displayTimes,
                          selectedIndex: _selectedIndex ?? (widget.displayTimes.isEmpty ? 0 : widget.displayTimes.length - 1),
                          showGuideLine: _isDragging,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${widget.range == '7' ? '7' : '30'} DAYS AGO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(77))),
              Text('TODAY',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withAlpha(77))),
            ]),
          ]),
        ),
      ),
    );
  }
}

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
        // Active text follows the toggle's theme colour (blue for Response Time,
        // red/pink for the Keyboard Heatmap) — not a hard-coded blue.
        color: active ? Color.lerp(activeColor, Colors.white, 0.3)! : Colors.white.withAlpha(77))),
    ),
  );
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final int selectedIndex;
  final bool showGuideLine;
  
  _LineChartPainter({required this.values, required this.selectedIndex, required this.showGuideLine});

  static const _blue = Color(0xFF60A5FA);
  static const _cyan = Color(0xFF22D3EE);

  double _xAt(int i, Size size) =>
      values.length == 1 ? size.width / 2 : i / (values.length - 1) * size.width;
  double _yAt(int v, int maxVal, Size size) =>
      size.height * 0.85 - (v / maxVal) * size.height * 0.75;

  // Smooth path through a run of consecutive points.
  Path _runPath(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      p.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.fold<int>(0, (m, v) => v > m ? v : m);
    if (maxVal == 0) return;

    // Grid lines
    final gridPaint = Paint()..color = Colors.white.withAlpha(13)..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      final y = size.height * (i + 1) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Days without sessions are GAPS, not dips: split data into runs of
    // consecutive non-zero values and draw each run on its own.
    final runs = <List<Offset>>[];
    var current = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) {
        if (current.isNotEmpty) { runs.add(current); current = []; }
      } else {
        current.add(Offset(_xAt(i, size), _yAt(values[i], maxVal, size)));
      }
    }
    if (current.isNotEmpty) runs.add(current);
    if (runs.isEmpty) return;

    // Dashed average line (average of active days only) — quiet reference.
    final active = values.where((v) => v > 0).toList();
    final avg = active.reduce((a, b) => a + b) / active.length;
    final avgY = _yAt(avg.round(), maxVal, size);
    final dashPaint = Paint()..color = Colors.white.withAlpha(31)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, avgY), Offset(x + 5, avgY), dashPaint);
    }

    final lineShader = const LinearGradient(colors: [_blue, _cyan])
        .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final glowShader = LinearGradient(colors: [_blue.withAlpha(105), _cyan.withAlpha(105)])
        .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final run in runs) {
      if (run.length == 1) {
        // Isolated day: a small solid mark instead of a floating line.
        canvas.drawCircle(run.first, 3.5, Paint()..color = _blue);
        continue;
      }
      final path = _runPath(run);

      // Area fill under the run.
      final fill = Path.from(path)
        ..lineTo(run.last.dx, size.height)
        ..lineTo(run.first.dx, size.height)
        ..close();
      canvas.drawPath(fill, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_blue.withAlpha(56), _blue.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

      // Soft glow pass under the crisp line.
      canvas.drawPath(path, Paint()
        ..shader = glowShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      // Crisp line.
      canvas.drawPath(path, Paint()
        ..shader = lineShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    // Marker on the selected (or latest) day — only when it has data.
    if (selectedIndex >= 0 && selectedIndex < values.length && values[selectedIndex] > 0) {
      final pt = Offset(_xAt(selectedIndex, size), _yAt(values[selectedIndex], maxVal, size));
      canvas.drawCircle(pt, 10, Paint()
        ..color = _blue.withAlpha(64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(pt, 5.5, Paint()..color = const Color(0xFF1A1625));
      canvas.drawCircle(pt, 5.5, Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => 
      old.values != values || 
      old.selectedIndex != selectedIndex || 
      old.showGuideLine != showGuideLine;
}

// ─── DEGREE ACCURACY CARD ─────────────────────────────────────────────────────

class _DegreeAccuracyCard extends StatelessWidget {
  final Map<String, ({int correct, int total})> degreeStats;
  const _DegreeAccuracyCard({required this.degreeStats});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1625),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withAlpha(26)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.analytics_rounded, color: Color(0xFF34D399), size: 22),
              SizedBox(width: 8),
              Text('Degree Accuracy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 24),
            ..._degrees.map((deg) {
              final (label, color) = deg;
              final ds = degreeStats[label];
              final plays = ds?.total ?? 0;
              final accuracy = plays > 0 ? ((ds!.correct / plays) * 100).round() : 0;
              return _DegreeRow(label: label, color: color, plays: plays, accuracy: accuracy);
            }),
          ]),
        ),
      ),
    );
  }
}

class _DegreeRow extends StatelessWidget {
  final String label;
  final Color color;
  final int plays;
  final int accuracy;
  const _DegreeRow({required this.label, required this.color, required this.plays, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(children: [
        Row(children: [
          // Degree badge — 48×48, borderRadius 12
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(26)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text(label,
              style: TextStyle(fontSize: label.length > 2 ? 11 : 14, fontWeight: FontWeight.w900, color: color,
                shadows: [Shadow(color: color.withAlpha(128), blurRadius: 8)]))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PLAYS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
              color: Colors.white.withAlpha(77), letterSpacing: 0.8)),
            Text(plays > 0 ? plays.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',') : '0',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ACCURACY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
              color: Colors.white.withAlpha(77), letterSpacing: 0.8)),
            Text('$accuracy%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
              color: color, letterSpacing: -0.9)),
          ]),
        ]),
        const SizedBox(height: 8),
        // Progress bar — 6px, radius 9999
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(9999),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: Colors.white.withAlpha(13), width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (accuracy / 100).clamp(0.0, 1.0),
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9999),
                  boxShadow: [BoxShadow(color: color.withAlpha(128), blurRadius: 12)])),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── GAMES PLAYED CARD ────────────────────────────────────────────────────────

class _GamesPlayedCard extends StatelessWidget {
  final List<int> sessions;
  final List<String> days;
  final int total;
  const _GamesPlayedCard({required this.sessions, required this.days, required this.total});

  static const _barColors = [
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF22C55E), Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = sessions.fold<int>(1, (m, v) => v > m ? v : m);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xCC1A1625),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withAlpha(26)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFFFB923C), size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Games Played',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF97316).withAlpha(51)),
                ),
                child: Text('$total GAMES',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFFB923C), letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final val = sessions[i];
                  final h = val > 0 ? (val / maxVal).clamp(0.05, 1.0) : 0.04;
                  final color = _barColors[i % _barColors.length];
                  final isToday = i == 6;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text('$val', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                            color: Colors.white.withAlpha(128))),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: h,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 10)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1,
                          color: isToday ? Colors.white : Colors.white.withAlpha(77))),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── KEYBOARD HEATMAP CARD ───────────────────────────────────────────────────

class _KeyboardHeatmapCard extends StatefulWidget {
  final List<SessionRecord> sessionHistory;
  const _KeyboardHeatmapCard({required this.sessionHistory});

  @override
  State<_KeyboardHeatmapCard> createState() => _KeyboardHeatmapCardState();
}

class _KeyboardHeatmapCardState extends State<_KeyboardHeatmapCard> {
  String _range = '30';

  static String _canon(String note) {
    const m = {
      'C#': 'C#', 'Db': 'C#', 'C♯': 'C#', 'D♭': 'C#',
      'D#': 'Eb', 'Eb': 'Eb', 'D♯': 'Eb', 'E♭': 'Eb',
      'F#': 'F#', 'Gb': 'F#', 'F♯': 'F#', 'G♭': 'F#',
      'G#': 'Ab', 'Ab': 'Ab', 'G♯': 'Ab', 'A♭': 'Ab',
      'A#': 'Bb', 'Bb': 'Bb', 'A♯': 'Bb', 'B♭': 'Bb',
    };
    return m[note] ?? note;
  }

  Map<String, int> _buildHeatmap() {
    final cutoff = DateTime.now().millisecondsSinceEpoch -
        (_range == '7' ? 7 : 30) * 86400000;
    final Map<String, ({int sum, int n})> acc = {};
    for (final session in widget.sessionHistory) {
      if (session.timestamp < cutoff) continue;
      for (final ans in session.answers) {
        final k = _canon(ans.note);
        if (k.isEmpty) continue;
        final c = acc[k] ?? (sum: 0, n: 0);
        acc[k] = (sum: c.sum + ans.responseTime, n: c.n + 1);
      }
    }
    return {for (final e in acc.entries) e.key: e.value.sum ~/ e.value.n};
  }

  static Color _rtColor(String note, Map<String, int> map, int lo, int hi) {
    final rt = map[note];
    if (rt == null) return const Color(0xFF161228);
    if (hi == lo) return const Color(0xFF22C55E);
    final t = (rt - lo) / (hi - lo);
    if (t < 0.5) return Color.lerp(const Color(0xFF22C55E), const Color(0xFFfacc15), t * 2)!;
    return Color.lerp(const Color(0xFFfacc15), const Color(0xFFEF4444), (t - 0.5) * 2)!;
  }

  @override
  Widget build(BuildContext context) {
    final map = _buildHeatmap();
    final vals = map.values;
    final lo = vals.isEmpty ? 0 : vals.reduce(math.min);
    final hi = vals.isEmpty ? 0 : vals.reduce(math.max);

    const whites = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    const blacks = [('C#', 1), ('Eb', 2), ('F#', 4), ('Ab', 5), ('Bb', 6)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.grid_view_rounded, color: Color(0xFFEC4899), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Keyboard Heatmap',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('PERFORMANCE BY NOTE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withAlpha(13)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _RangeBtn(label: '7D', active: _range == '7', onTap: () => setState(() => _range = '7'), activeColor: const Color(0xFFEC4899)),
              _RangeBtn(label: '30D', active: _range == '30', onTap: () => setState(() => _range = '30'), activeColor: const Color(0xFFEC4899)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        // Piano card — borderRadius 40
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xCC1A1625),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withAlpha(26)),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20))],
              ),
              child: Column(children: [
                LayoutBuilder(builder: (ctx, box) {
                  final wkW = box.maxWidth / 7;
                  final bkW = wkW * 0.62;
                  const wkH = 130.0; // slightly longer keys
                  const bkH = 82.0;

                  return SizedBox(
                    height: wkH,
                    child: Stack(children: [
                      // White keys
                      Row(
                        children: List.generate(7, (i) {
                          final c = _rtColor(whites[i], map, lo, hi);
                          BorderRadius br;
                          if (i == 0) {
                            br = const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8));
                          } else if (i == 6) {
                            br = const BorderRadius.only(topRight: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8));
                          } else {
                            br = const BorderRadius.vertical(bottom: Radius.circular(8));
                          }
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(color: c, borderRadius: br,
                                border: Border.all(color: Colors.black.withAlpha(26), width: 1.2)),
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(whites[i],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: -0.5)),
                            ),
                          );
                        }),
                      ),
                      // Black keys
                      ...blacks.map((bk) {
                        final c = _rtColor(bk.$1, map, lo, hi);
                        final noData = !map.containsKey(bk.$1);
                        return Positioned(
                          left: bk.$2 * wkW - bkW / 2,
                          top: 0,
                          child: Container(
                            width: bkW,
                            height: bkH,
                            decoration: BoxDecoration(
                              color: noData ? const Color(0xFF0D0B17) : c,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              border: Border.all(color: Colors.white.withAlpha(51), width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(bk.$1,
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white60)),
                          ),
                        );
                      }),
                    ]),
                  );
                }),
                const SizedBox(height: 16),
                // Legend
                Row(children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))),
                  const SizedBox(width: 6),
                  Text('SLOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: Colors.white.withAlpha(102), letterSpacing: 1)),
                  const Spacer(),
                  Text('FAST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: Colors.white.withAlpha(102), letterSpacing: 1)),
                  const SizedBox(width: 6),
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22C55E))),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── SKILL MASTERY ROW ────────────────────────────────────────────────────────

class _SkillRow extends StatelessWidget {
  final dynamic keyData;
  final Color color;
  final int index;
  final int rank; // 1-12 by response time; 0 = no data yet
  const _SkillRow({required this.keyData, required this.color, required this.index, required this.rank});

  @override
  Widget build(BuildContext context) {
    final mastery = (keyData.totalProgress as int).clamp(0, 100);
    final keySig = _keySignatures[keyData.key] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xCC1A1625),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withAlpha(13)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              // Key badge — 56×56, borderRadius 16
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(21),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Center(child: NoteText(note: keyData.key,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color))),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(child: Column(children: [
                Row(children: [
                  Expanded(child: Text(keySig,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                      color: Colors.white.withAlpha(102), letterSpacing: 1))),
                  // Verified tick next to any non-zero mastery (per request).
                  if (mastery > 0) Icon(Icons.verified_rounded, color: color, size: 14),
                  const SizedBox(width: 4),
                  // Mastery % — Text.rich + explicit Lexend so it doesn't fall
                  // back to Roboto (which looked hard/robotic).
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '$mastery', style: TextStyle(fontFamily: 'Lexend', fontSize: 15, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3)),
                    TextSpan(text: '%', style: TextStyle(fontFamily: 'Lexend', fontSize: 10, fontWeight: FontWeight.w800, color: color.withAlpha(153))),
                  ])),
                ]),
                const SizedBox(height: 8),
                // Progress bar — 8px
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.white.withAlpha(13), width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (mastery / 100).clamp(0.0, 1.0),
                        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9999),
                          boxShadow: [BoxShadow(color: color.withAlpha(128), blurRadius: 8)])),
                      ),
                    ),
                  ),
                ),
              ])),
              const SizedBox(width: 16),
              // Rank — medal colours for the top 3 (web parity).
              Builder(builder: (_) {
                Color rankColor;
                List<Shadow>? rankShadow;
                if (rank == 0) {
                  rankColor = Colors.white.withAlpha(25);
                } else if (rank == 1) {
                  rankColor = const Color(0xFFFACC15); // gold
                  rankShadow = const [Shadow(color: Color(0x99FACC15), blurRadius: 8)];
                } else if (rank == 2) {
                  rankColor = const Color(0xFFCBD5E1); // silver
                  rankShadow = const [Shadow(color: Color(0x99CBD5E1), blurRadius: 8)];
                } else if (rank == 3) {
                  rankColor = const Color(0xFFF59E0B); // bronze
                  rankShadow = const [Shadow(color: Color(0x99F59E0B), blurRadius: 8)];
                } else {
                  rankColor = Colors.white.withAlpha(77);
                }
                return Container(
                  width: 44,
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white.withAlpha(13)))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('RANK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
                      color: Colors.white.withAlpha(77), letterSpacing: 0.8)),
                    // Unranked keys show "0" (faded) — matches the web original.
                    Text('$rank', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      letterSpacing: -1.2, color: rankColor, shadows: rankShadow)),
                  ]),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}
