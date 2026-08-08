import 'package:flutter/material.dart';

/// A tappable wrapper that gives its child a small, consistent press-in scale
/// so buttons across the app "give" under the finger instead of firing flat.
///
/// Drop-in for `GestureDetector(onTap: …)` — same callback, plus the feedback.
/// When [onTap] is null the child is shown inert (no scale, no hit test), so it
/// can wrap a disabled control without special-casing at the call site.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Scale at full press. 0.96 is a light, universal default; denser controls
  /// (small chips) can go a touch lower.
  final double pressedScale;
  final Duration duration;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 110),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
