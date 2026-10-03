import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fills a tablet's screen with the app, scaled up whole.
///
/// Every screen here is drawn for one hand holding a phone upright: a 60pt
/// question, a keyboard across the width, cards edge to edge. Handed an iPad's
/// 1024pt as it is, the layout stretches — a keyboard a foot wide, buttons the
/// size of a fist, lines nobody can read. Shrunk to a phone-wide strip in the
/// middle, it wastes the screen people bought.
///
/// So on a tablet the app lays out on a slightly roomy phone — never narrower
/// than [minLogicalWidth], never shorter than [minLogicalHeight] — and that is
/// scaled up to fill the display edge to edge. Text and icons are drawn at the
/// final size, so nothing is blurred; the screen simply reads larger, which is
/// what a bigger screen held further away needs.
///
/// MediaQuery is rewritten to match — size, safe areas, insets and pixel
/// ratio — so screens that measure themselves see the space they really have.
class TabletFit extends StatelessWidget {
  final Widget child;
  const TabletFit({super.key, required this.child});

  /// Wider than the largest iPhone (430pt), so no phone is ever touched.
  static const double phoneMaxWidth = 480;
  static const double minLogicalWidth = 520;
  static const double minLogicalHeight = 800;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    if (size.width <= phoneMaxWidth) return child;
    final scale = math.max(
      1.0,
      math.min(size.width / minLogicalWidth, size.height / minLogicalHeight),
    );
    if (scale <= 1.0) return child;
    final logical = size / scale;
    EdgeInsets down(EdgeInsets e) => e / scale;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: logical.width,
        maxWidth: logical.width,
        minHeight: logical.height,
        maxHeight: logical.height,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: MediaQuery(
            data: mq.copyWith(
              size: logical,
              devicePixelRatio: mq.devicePixelRatio * scale,
              padding: down(mq.padding),
              viewPadding: down(mq.viewPadding),
              viewInsets: down(mq.viewInsets),
              systemGestureInsets: down(mq.systemGestureInsets),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
