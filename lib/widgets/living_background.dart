import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The home background from design 12a, brought to life.
///
/// Faithful to the mock's recipe — the base `#0F0A1A` under three wide,
/// top-anchored radial blobs in its slate / indigo / violet palette — but the
/// blobs slowly drift and shift colour instead of sitting still, so the screen
/// feels alive without ever getting bright enough to fight the content on top.
///
/// It is meant to be mounted **once, behind everything**, at the root: the tabs
/// above it are transparent and slide over it, so it stays put when you swipe
/// from Training to Stats rather than scrolling away with the page. During a
/// game (a different destination) it is simply not in the tree, which also
/// means its animation stops paying for itself when nobody can see it.
class LivingBackground extends StatefulWidget {
  const LivingBackground({super.key});

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground>
    with SingleTickerProviderStateMixin {
  // One slow loop. Long enough that the movement reads as breathing, not
  // animation; the blobs each carry a different phase so they never line up.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 34),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The gradient never reacts to a tap, so it must not eat one meant for the
    // content above it.
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _LivingBackgroundPainter(_c.value),
          ),
        ),
      ),
    );
  }
}

class _LivingBackgroundPainter extends CustomPainter {
  /// Loops 0 → 1.
  final double t;
  const _LivingBackgroundPainter(this.t);

  // 12a's exact palette, one list per blob, each threaded with one extra hue so
  // the colour has somewhere to travel: a cool teal for the slate blob, violet
  // for the indigo one, a dark magenta for the violet one.
  static const _slate = Color(0xFF1E293B);
  static const _indigo = Color(0xFF312E81);
  static const _violet = Color(0xFF4C1D95);
  static const _teal = Color(0xFF124E63);
  static const _magenta = Color(0xFF5B2A6E);

  static const _paletteA = [_slate, _indigo, _teal];
  static const _paletteB = [_indigo, _violet, _slate];
  static const _paletteC = [_violet, _magenta, _indigo];

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    // Base first — the same flat colour every screen used before, so nothing
    // below the blobs changes.
    canvas.drawRect(full, Paint()..color = const Color(0xFF0F0A1A));

    // Top-anchored and wide, like the mock's `130% 40%` ellipses. Each drifts
    // on its own gentle path and cycles its palette on its own phase.
    _blob(canvas, size, base: const Offset(0.20, 0.00), drift: const Offset(0.07, 0.05),
        size01: const Offset(1.30, 0.55), palette: _paletteA, phase: 0.0, opacity: 0.85);
    _blob(canvas, size, base: const Offset(1.00, 0.04), drift: const Offset(0.06, 0.045),
        size01: const Offset(1.20, 0.60), palette: _paletteB, phase: 0.37, opacity: 0.80);
    _blob(canvas, size, base: const Offset(0.88, 0.22), drift: const Offset(0.05, 0.06),
        size01: const Offset(1.05, 0.62), palette: _paletteC, phase: 0.71, opacity: 0.70);
  }

  /// One drifting, colour-shifting radial blob.
  ///
  /// [base] and [drift] are in unit space (0..1 of the screen); [size01] is the
  /// ellipse's width/height as a fraction of the screen. The centre rides a
  /// Lissajous path so it never simply retraces a line, and the opacity breathes
  /// a little so even a still moment is not quite still.
  void _blob(
    Canvas canvas,
    Size size, {
    required Offset base,
    required Offset drift,
    required Offset size01,
    required List<Color> palette,
    required double phase,
    required double opacity,
  }) {
    final a = 2 * math.pi * (t + phase);
    final cx = (base.dx + drift.dx * math.sin(a)) * size.width;
    final cy = (base.dy + drift.dy * math.cos(a * 0.8)) * size.height;
    final centre = Offset(cx, cy);

    final w = size01.dx * size.width;
    final h = size01.dy * size.height;
    final rect = Rect.fromCenter(center: centre, width: w, height: h);

    final colour = _cycle(palette, t + phase);
    final op = (opacity * (0.78 + 0.22 * math.sin(a * 1.3))).clamp(0.0, 1.0);

    final shader = RadialGradient(
      center: Alignment.center,
      radius: 0.5,
      colors: [colour.withValues(alpha: op), colour.withValues(alpha: 0)],
      stops: const [0.0, 1.0],
    ).createShader(rect);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  /// Smoothly loops through [palette] as [x] advances, easing each hand-off so
  /// the colour never visibly snaps.
  static Color _cycle(List<Color> palette, double x) {
    final n = palette.length;
    final p = (x % 1.0) * n;
    final i = p.floor() % n;
    final f = _smooth(p - p.floor());
    return Color.lerp(palette[i], palette[(i + 1) % n], f)!;
  }

  static double _smooth(double t) => t * t * (3 - 2 * t);

  @override
  bool shouldRepaint(_LivingBackgroundPainter old) => old.t != t;
}
