import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../services/haptics_service.dart';
import '../widgets/note_text.dart';
import '../widgets/pressable_scale.dart';

/// Free Mode — a self-paced drill with no answers, no timer and no score.
///
/// One chromatic degree fills the screen; a tap anywhere brings the next one.
/// Nothing is checked and nothing is counted right or wrong: the point is to
/// work the calculation out in your own head, in whatever key you like, and
/// move on when *you* are ready. A run is [_kTotal] numbers, tracked by the bar
/// at the top — the only structure the mode imposes.
class FreeModeScreen extends StatefulWidget {
  const FreeModeScreen({super.key});

  @override
  State<FreeModeScreen> createState() => _FreeModeScreenState();
}

const int _kTotal = 200;

class _FreeModeScreenState extends State<FreeModeScreen> {
  final math.Random _rng = math.Random();
  late String _degree = kChromaticDegrees[_rng.nextInt(kChromaticDegrees.length)];
  int _index = 1; // 1-based: the number on screen is the _index-th of the run

  bool get _done => _index > _kTotal;

  void _next() {
    if (_done) return;
    if (_index == _kTotal) {
      // The run is over — land on the summary instead of a 201st number.
      HapticsService.success();
      setState(() => _index++);
      return;
    }
    // Never show the same degree twice in a row: a repeat reads as a missed
    // tap rather than a new question.
    String next = _degree;
    while (next == _degree) {
      next = kChromaticDegrees[_rng.nextInt(kChromaticDegrees.length)];
    }
    HapticsService.impactLight();
    setState(() {
      _degree = next;
      _index++;
    });
  }

  void _restart() {
    HapticsService.impactMedium();
    setState(() {
      _degree = kChromaticDegrees[_rng.nextInt(kChromaticDegrees.length)];
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.degreeColors[_degree] ?? Colors.white;
    final progress = (_index - 1).clamp(0, _kTotal) / _kTotal;

    return Scaffold(
      backgroundColor: const Color(0xFF07030F),
      body: Stack(
        children: [
          const Positioned.fill(child: _MagicBackground()),
          // The whole screen advances — there is no button to hunt for, which
          // is what makes it usable with your eyes on an instrument.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _done ? null : _next,
              child: SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      index: _index.clamp(1, _kTotal),
                      total: _kTotal,
                      progress: progress,
                      color: color,
                      done: _done,
                      onExit: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: _done
                            ? _DoneCard(onRestart: _restart)
                            : _BigDegree(degree: _degree, color: color),
                      ),
                    ),
                    if (!_done)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Text(
                          'TAP ANYWHERE FOR THE NEXT NUMBER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── The number itself ────────────────────────────────────────────────────────

class _BigDegree extends StatelessWidget {
  final String degree;
  final Color color;
  const _BigDegree({required this.degree, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: Padding(
        // The key is the degree, so a repeat of the same value would not
        // re-run the animation — the state above guarantees it never repeats.
        key: ValueKey(degree),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            // The glow is the degree's own colour, so the number reads as the
            // same colour language the trainer uses.
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 90, spreadRadius: 10),
              ],
              shape: BoxShape.circle,
            ),
            child: NoteText(
              note: degree,
              accidentalLift: 0.30,
              accidentalScale: 0.52,
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.w900,
                letterSpacing: -4,
                color: color,
                height: 1.1,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.8), blurRadius: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar: exit, counter, progress ─────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int index;
  final int total;
  final double progress;
  final Color color;
  final bool done;
  final VoidCallback onExit;

  const _TopBar({
    required this.index,
    required this.total,
    required this.progress,
    required this.color,
    required this.done,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              PressableScale(
                onTap: onExit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FREE MODE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done ? '$total / $total' : '$index / $total',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Rainbow-filled progress bar: it fills as the run goes, and the
          // gradient is the same spectrum the degree colours run through.
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                LayoutBuilder(
                  builder: (ctx, c) => AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    height: 6,
                    width: c.maxWidth * progress,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFFff4d4d), Color(0xFFffdb4d), Color(0xFF4dff4d),
                        Color(0xFF00dcdc), Color(0xFF4d4dff), Color(0xFFff4dff),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── End of a run ─────────────────────────────────────────────────────────────

class _DoneCard extends StatelessWidget {
  final VoidCallback onRestart;
  const _DoneCard({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [
              Color(0xFFff4d4d), Color(0xFFffdb4d), Color(0xFF4dff4d),
              Color(0xFF00dcdc), Color(0xFF4d4dff), Color(0xFFff4dff),
            ]).createShader(b),
            child: const Text(
              '$_kTotal',
              style: TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NUMBERS DONE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No score, no clock — just the reps. Go again whenever you like.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 28),
          PressableScale(
            onTap: onRestart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), blurRadius: 28, offset: const Offset(0, 8)),
                ],
              ),
              child: const Text(
                'GO AGAIN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Magic rainbow background ─────────────────────────────────────────────────

/// Slow rainbow aurora with drifting blobs and a scatter of twinkling stars.
///
/// Deliberately louder than the app's [LivingBackground]: Free Mode has one
/// number and no chrome, so the background is most of what you see and can
/// carry the whole spectrum without fighting anything for attention.
class _MagicBackground extends StatefulWidget {
  const _MagicBackground();

  @override
  State<_MagicBackground> createState() => _MagicBackgroundState();
}

class _MagicBackgroundState extends State<_MagicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _MagicPainter(_c.value),
          ),
        ),
      ),
    );
  }
}

class _MagicPainter extends CustomPainter {
  /// Loops 0 → 1.
  final double t;
  const _MagicPainter(this.t);

  // Fixed scatter, generated once from a fixed seed so the stars keep their
  // places between frames (a fresh Random each paint would make them jump).
  static final List<Offset> _stars = () {
    final r = math.Random(7);
    return List<Offset>.generate(46, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();
  static final List<double> _starPhase = () {
    final r = math.Random(21);
    return List<double>.generate(46, (_) => r.nextDouble());
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    // Deep base so the colours above read as light, not paint.
    canvas.drawRect(full, Paint()..color = const Color(0xFF07030F));

    // Five wide blobs, each parked on its own arc of the colour wheel and
    // rotating through it, so the screen is always a different rainbow.
    const blobs = [
      (Offset(0.18, 0.14), Offset(0.10, 0.07), 1.15, 0.62),
      (Offset(0.86, 0.10), Offset(0.09, 0.06), 1.05, 0.58),
      (Offset(0.50, 0.52), Offset(0.12, 0.09), 1.30, 0.50),
      (Offset(0.12, 0.86), Offset(0.08, 0.07), 1.00, 0.55),
      (Offset(0.90, 0.84), Offset(0.10, 0.08), 1.10, 0.52),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final (base, drift, spread, alpha) = blobs[i];
      final phase = i / blobs.length;
      final a = 2 * math.pi * (t + phase);

      final cx = (base.dx + drift.dx * math.sin(a)) * size.width;
      final cy = (base.dy + drift.dy * math.cos(a * 0.75)) * size.height;

      // Hue sweeps the full wheel over one loop; each blob is a fifth apart,
      // so together they always span the spectrum.
      final hue = ((t + phase) * 360) % 360;
      final colour = HSVColor.fromAHSV(1, hue, 0.72, 1).toColor();

      // Breathe the opacity so even a still moment is not quite still.
      final op = (alpha * (0.72 + 0.28 * math.sin(a * 1.2))).clamp(0.0, 1.0);

      final w = spread * size.width;
      final h = spread * size.width; // circular in pixels, not stretched
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

      final paint = Paint()
        ..blendMode = BlendMode.plus // light adds, so overlaps go white-hot
        ..shader = RadialGradient(
          colors: [colour.withValues(alpha: op * 0.55), colour.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    // Twinkling stars — the "magic" on top of the aurora.
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _stars.length; i++) {
      final p = _stars[i];
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + _starPhase[i]));
      final r = 0.7 + 1.5 * tw;
      starPaint.color = Colors.white.withValues(alpha: 0.10 + 0.55 * tw);
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), r, starPaint);
    }

    // Vignette: pulls the eye to the number in the middle.
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          stops: const [0.45, 1.0],
        ).createShader(full),
    );
  }

  @override
  bool shouldRepaint(_MagicPainter old) => old.t != t;
}
