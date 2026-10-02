import 'package:flutter/material.dart';

/// Keeps the app a phone-shaped column on anything wider than a phone.
///
/// Every screen here is drawn for one hand holding a phone upright: a 60pt
/// question, a keyboard across the width, cards edge to edge. Handed an iPad's
/// 1024pt the same layout does not become a tablet app, it becomes a phone app
/// with everything stretched — line lengths nobody can read, a keyboard a foot
/// wide, buttons the size of a fist. Until there is a real tablet layout, the
/// honest thing is a centred column of phone width on the app's own ground.
///
/// The MediaQuery size is narrowed too, not just the box: screens that measure
/// themselves against `MediaQuery.sizeOf` must see the column they are in, or
/// they lay out for a width they do not have.
class PhoneColumn extends StatelessWidget {
  final Widget child;
  const PhoneColumn({super.key, required this.child});

  /// A shade wider than the largest iPhone (430pt), so no phone is ever
  /// touched by this and a tablet gets a comfortable column.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth) return child;
    // The room either side carries the app's own light, so the column reads
    // as the app sitting on its backdrop rather than a strip with dead bars.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1230), Color(0xFF0F0A1A)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.9, -0.85),
                  radius: 0.9,
                  colors: [Color(0x406366F1), Color(0x006366F1)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.95, 0.8),
                  radius: 0.9,
                  colors: [Color(0x33DB2777), Color(0x00DB2777)],
                ),
              ),
            ),
          ),
          Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 48)],
              ),
              child: SizedBox(
                width: maxWidth,
                child: MediaQuery(
                  data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
