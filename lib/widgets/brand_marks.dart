import 'package:flutter/material.dart';

/// Google's mark, on the sign-in button.
///
/// Their artwork, at their plate size, scaled down — not a drawing of it.
/// Four arcs and a bar never quite become a G at twenty pixels, and a
/// look-alike on a sign-in button is the thing people have learnt not to
/// trust. It is never recoloured and never sits on anything but white.
class GoogleMark extends StatelessWidget {
  final double size;
  const GoogleMark({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/google-g.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
}
