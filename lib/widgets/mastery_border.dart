import 'package:flutter/material.dart';

/// The coloured outline that says how far a key has been taken.
///
/// Drawn as a fraction of the tile's own border rather than as a bar beside it:
/// the grid is twelve cells wide and there is no room for a bar, but every cell
/// already has a perimeter doing nothing.
///
/// **Symmetric on purpose.** A single arc sweeping clockwise reads, at this
/// size, as a border that failed to render — and twelve of them stopped at
/// twelve different angles read as noise. Growing from the top centre in both
/// directions at once reads as a decision: the two arms close at the bottom
/// when the key is finished, and a row of tiles can be compared at a glance
/// the way a row of bars can.
class MasteryBorder extends StatelessWidget {
  /// 0 → nothing drawn (the tile keeps whatever neutral border it has),
  /// 1 → the whole perimeter is lit.
  final double progress;
  final Color color;
  final double radius;
  final double width;
  final Widget child;

  const MasteryBorder({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.radius = 16,
    this.width = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return child;
    return CustomPaint(
      // Over the child, so the tile's own background and the selected state
      // never paint on top of the one thing this is here to show.
      foregroundPainter: _MasteryPainter(
        progress: progress.clamp(0.0, 1.0),
        color: color,
        radius: radius,
        width: width,
      ),
      child: child,
    );
  }
}

class _MasteryPainter extends CustomPainter {
  _MasteryPainter({
    required this.progress,
    required this.color,
    required this.radius,
    required this.width,
  });

  final double progress;
  final Color color;
  final double radius;
  final double width;

  /// Half the outline, from the top centre down to the bottom centre.
  /// [sign] is 1 for the right-hand arm, -1 for the left.
  Path _half(Size size, double sign) {
    final cx = size.width / 2;
    final r = radius.clamp(0.0, size.shortestSide / 2);
    // Inset by half the stroke so the line sits inside the tile instead of
    // being clipped in half by its own edge.
    final i = width / 2;
    final left = i, top = i, right = size.width - i, bottom = size.height - i;
    final edge = sign > 0 ? right : left;

    return Path()
      ..moveTo(cx, top)
      ..lineTo(edge - sign * r, top)
      ..arcToPoint(Offset(edge, top + r),
          radius: Radius.circular(r), clockwise: sign > 0)
      ..lineTo(edge, bottom - r)
      ..arcToPoint(Offset(edge - sign * r, bottom),
          radius: Radius.circular(r), clockwise: sign > 0)
      ..lineTo(cx, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final sign in [1.0, -1.0]) {
      final metrics = _half(size, sign).computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final metric = metrics.first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MasteryPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.radius != radius ||
      old.width != width;
}
