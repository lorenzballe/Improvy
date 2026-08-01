import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'legal_screen.dart';

/// First-launch welcome — the "3a" poster from the redesign: one full-bleed
/// colour field, the promise in huge type, the scale as a colour strip, and a
/// single call to action.
///
/// The design is drawn at 390×844 with a 47pt status bar and a 34pt home
/// indicator, so its content box is 763pt tall. Every number below is that
/// drawing's, and the whole poster is scaled by one factor ([_Poster.s]) so it
/// lands whole on a smaller screen instead of being re-flowed into something
/// the design never showed.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  // True from the moment START is pressed: the entrance is then played in
  // reverse, and the poster lifts towards the viewer as it goes, so handing over
  // to the app reads as stepping through the poster rather than a hard cut.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  Future<void> _finish() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await _enter.animateBack(0.0,
        duration: const Duration(milliseconds: 460), curve: Curves.easeInCubic);
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// Fade + rise over an interval of the entrance controller (stagger). The
  /// poster at rest is exactly the design; this only governs how it arrives.
  Widget _in(double start, double end, {double dy = 22, required Widget child}) {
    final anim = CurvedAnimation(
        parent: _enter, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * dy), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _enter,
        builder: (_, child) {
          // Arriving, the poster settles in over the first third while the
          // staggered pieces land on top of it. Leaving, the same value runs
          // back to zero and the whole poster lifts towards the viewer.
          final t = _enter.value;
          final v = (_leaving ? t : t / 0.34).clamp(0.0, 1.0);
          return Opacity(
            opacity: v,
            child: Transform.scale(
              scale: _leaving ? 1.0 + (1 - v) * 0.06 : 0.98 + 0.02 * v,
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, c) {
            final free = c.maxHeight - inset.top - inset.bottom;
            final s = math.min(c.maxWidth / 390, free / _designHeight)
                .clamp(0.5, 1.0);
            // The poster is a fixed composition scaled to fit, so it does not
            // scroll — it is one screen, and dragging it was never meant to do
            // anything. The scroll view stays as the measuring frame (and as a
            // guard against a few points of platform text-metric disagreement),
            // with its physics off.
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: IntrinsicHeight(
                  child: _Poster(
                    s: s,
                    inset: inset,
                    stagger: _in,
                    onStart: _finish,
                    onLegal: (title, body) => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                LegalScreen(title: title, body: body))),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Palette, straight from the design ─────────────────────────────────────────

const Color _bg = Color(0xFF12081C);
const Color _ink = Color(0xFF12081C); // type on the white CTA

/// Height of the poster at scale 1, between the safe areas — measured from the
/// rendered widget, not taken from the drawing. The design's own box is 763pt,
/// but Flutter's line boxes for Lexend and Outfit round about 1.2% taller than
/// the browser the design was drawn in, so scaling against 763 leaves the
/// footer a few points short of the screen.
const double _designHeight = 773;

/// The colour field: `linear-gradient(160deg, …)`. CSS measures the gradient
/// line from the box centre, so a 160° sweep over 390×566 starts and ends
/// slightly outside the box — hence the ±1.1 alignment.
const _field = LinearGradient(
  begin: Alignment(-0.584, -1.105),
  end: Alignment(0.584, 1.105),
  colors: [Color(0xFFFF6B5A), Color(0xFFE23B7B), Color(0xFF9333EA), Color(0xFF5B21B6)],
  stops: [0.0, 0.38, 0.74, 1.0],
);

/// The scale as a colour strip: degrees 1–7 in the app's own note colours, each
/// bar's height standing for nothing in particular beyond making a skyline.
/// The 7 borrows ♭7's pink rather than repeating the tonic's red, which would
/// read as a mistake sitting seven bars away from it.
const List<(double, Color, Color, String)> _bars = [
  (44, Color(0xFFFF4D4D), Color(0xFF3D0A0A), '1'),
  (54, Color(0xFFFFDB4D), Color(0xFF3D3000), '2'),
  (64, Color(0xFF4DFF4D), Color(0xFF0A3D0A), '3'),
  (72, Color(0xFF00DCDC), Color(0xFF03383A), '4'),
  (88, Color(0xFF4D4DFF), Color(0xFFFFFFFF), '5'),
  (66, Color(0xFFFF4DFF), Color(0xFF3D0A3D), '6'),
  (50, Color(0xFFFF4D94), Color(0xFF3D0A22), '7'),
];

const List<(String, Color, String)> _stats = [
  ('12', Color(0xFFFFDB4D), 'keys to\nmaster'),
  ('6', Color(0xFF4DFF4D), 'training\nmodes'),
  ('2m', Color(0xFF22D3EE), 'a day is\nenough'),
];

// ── The poster ────────────────────────────────────────────────────────────────

typedef _Stagger = Widget Function(double start, double end,
    {double dy, required Widget child});

class _Poster extends StatelessWidget {
  final double s;
  final EdgeInsets inset;
  final _Stagger stagger;
  final VoidCallback onStart;
  final void Function(String title, String body) onLegal;

  const _Poster({
    required this.s,
    required this.inset,
    required this.stagger,
    required this.onStart,
    required this.onLegal,
  });

  @override
  Widget build(BuildContext context) {
    final side = 30 * s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _colourField(side),
        // The design's flexible gap: 4.8pt of it sits inside the colour field
        // (above), 6.4pt below it. On a taller screen this is where the slack
        // goes.
        Expanded(child: SizedBox(height: 6.4 * s)),
        Padding(
          padding: EdgeInsets.fromLTRB(
              side, 0, side, 24 * s + inset.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stagger(0.34, 0.86, child: _statRow()),
              SizedBox(height: 20 * s),
              stagger(0.46, 1.0, dy: 16 * s, child: _StartButton(s: s, onTap: onStart)),
              SizedBox(height: 16 * s),
              stagger(0.6, 1.0, dy: 8, child: _legal(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colourField(double side) => ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(44 * s)),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _field),
          child: Stack(
            children: [
              // Warm light pooling in the bottom-left corner of the field.
              Positioned(
                left: -80 * s,
                bottom: -120 * s,
                child: Container(
                  width: 340 * s,
                  height: 340 * s,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x66FFDB4D), Color(0x00FFDB4D)],
                      stops: [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    side, inset.top + 26 * s, side, 4.8 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    stagger(0.0, 0.5, dy: 14, child: _header()),
                    SizedBox(height: 58 * s),
                    stagger(0.08, 0.62, dy: 28 * s, child: _headline()),
                    SizedBox(height: 26 * s),
                    stagger(0.2, 0.74, child: _promise()),
                    SizedBox(height: 34 * s),
                    stagger(0.28, 0.9, dy: 18 * s, child: _scaleStrip()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _header() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('IMPROVY',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20 * s,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4 * s,
                  color: Colors.white)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 7 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Mental training',
                style: TextStyle(
                    fontSize: 11.5 * s,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      );

  Widget _headline() => Text(
        'Every note\nis a\nnumber.',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 60 * s,
          fontWeight: FontWeight.w600,
          height: 0.98,
          letterSpacing: -2.6 * s,
          color: Colors.white,
        ),
      );

  // SizedBox, not ConstrainedBox(maxWidth:): the poster is measured by an
  // IntrinsicHeight, and only a *tight* width constraint is substituted into
  // that measurement. With a loose one this paragraph is measured at the full
  // column width — one line short of how it actually wraps.
  Widget _promise() => SizedBox(
        width: 296 * s,
        child: Text(
          'See the number under any note instantly, in all twelve keys — '
          'no counting, no theory book.',
          style: TextStyle(
            fontSize: 16 * s,
            fontWeight: FontWeight.w300,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );

  Widget _scaleStrip() => SizedBox(
        height: 88 * s,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, bar) in _bars.indexed) ...[
              if (i > 0) SizedBox(width: 6 * s),
              Expanded(
                child: Container(
                  height: bar.$1 * s,
                  padding: EdgeInsets.only(top: 9 * s),
                  alignment: Alignment.topCenter,
                  decoration: BoxDecoration(
                    color: bar.$2,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12 * s),
                      topRight: Radius.circular(12 * s),
                      bottomLeft: Radius.circular(4 * s),
                      bottomRight: Radius.circular(4 * s),
                    ),
                  ),
                  child: Text(bar.$4,
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w600,
                          color: bar.$3)),
                ),
              ),
            ],
          ],
        ),
      );

  // IntrinsicHeight so the three cards share a height. A bare stretching Row
  // cannot report an intrinsic height, and the poster is measured by one.
  Widget _statRow() => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, stat) in _stats.indexed) ...[
              if (i > 0) SizedBox(width: 10 * s),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16 * s),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20 * s),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(stat.$1,
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 26 * s,
                              fontWeight: FontWeight.w600,
                              color: stat.$2)),
                      SizedBox(height: 5 * s),
                      Text(stat.$3,
                          style: TextStyle(
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _legal(BuildContext context) {
    final style = TextStyle(
        fontSize: 11 * s,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.35));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => onLegal('Privacy Policy', kPrivacyPolicyBody),
          child: Text('Privacy Policy', style: style),
        ),
        Text('  ·  ', style: style),
        GestureDetector(
          onTap: () => onLegal('Terms of Service', kTermsBody),
          child: Text('Terms of Service', style: style),
        ),
      ],
    );
  }
}

// ── The one call to action ────────────────────────────────────────────────────

class _StartButton extends StatefulWidget {
  final double s;
  final VoidCallback onTap;
  const _StartButton({required this.s, required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 60 * s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Start training',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.5 * s,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              SizedBox(width: 9 * s),
              Icon(Icons.arrow_forward_rounded, size: 21 * s, color: _ink),
            ],
          ),
        ),
      ),
    );
  }
}
