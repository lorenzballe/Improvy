import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../services/haptics_service.dart';
import '../widgets/note_text.dart';
import '../widgets/pressable_scale.dart';

/// Free Mode — a self-paced drill with no answers, no timer and no score.
///
/// One degree fills the screen; a tap anywhere brings the next one. Nothing is
/// checked and nothing is counted right or wrong: the point is to work the
/// calculation out in your own head, in whatever key you like, and move on when
/// *you* are ready. A run is [_kTotal] numbers, tracked by the bar at the top —
/// the only structure the mode imposes.
class FreeModeScreen extends StatefulWidget {
  const FreeModeScreen({super.key});

  @override
  State<FreeModeScreen> createState() => _FreeModeScreenState();
}

const int _kTotal = 200;

/// The spectrum the degree colours run through, reused by every rainbow fill
/// on this screen so the bar, the summary and the icon all match.
const List<Color> kFreeSpectrum = [
  Color(0xFFff4d4d), Color(0xFFffdb4d), Color(0xFF4dff4d),
  Color(0xFF00dcdc), Color(0xFF4d4dff), Color(0xFFff4dff),
];

/// Draws the next Free Mode degree, spelled as a **single** number — never a
/// slash pair like '♭3/♯2'.
///
/// The draw is over the twelve semitones, not the fifteen spellings: picking
/// uniformly from the spellings would make the three enharmonic semitones
/// (♭3/♯2, ♯4/♭5, ♭6/♯5) turn up half again as often as the rest. So a semitone
/// is chosen first — every pitch equally likely — and only then, where it has
/// two names, one of them at even odds.
///
/// [previousBase] is excluded so the same pitch never comes up twice running:
/// a repeat reads as a missed tap rather than a new question, and it would read
/// that way even when the two draws spell it differently. Returns both the
/// semitone drawn (to pass back in next time) and the spelling to show.
({String base, String spelling}) nextFreeDegree(math.Random rng, String previousBase) {
  var base = previousBase;
  while (base == previousBase) {
    base = kChromaticDegrees[rng.nextInt(kChromaticDegrees.length)];
  }
  final split = kDegreeSplitMap[base];
  return (base: base, spelling: split == null ? base : split[rng.nextInt(split.length)]);
}

class _FreeModeScreenState extends State<FreeModeScreen>
    with TickerProviderStateMixin {
  final math.Random _rng = math.Random();

  /// The semitone currently shown, as its slash form ('♭3/♯2') — kept so a
  /// pitch never comes up twice running even when the two draws would spell it
  /// differently.
  String _base = '';
  String _degree = '';
  int _index = 1;

  /// Breathing halo behind the number, and the pulse under the hint line.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  /// Fires once per tap: a ring blooms out of the number.
  late final AnimationController _bloom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _roll();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _bloom.dispose();
    super.dispose();
  }

  void _roll() {
    final draw = nextFreeDegree(_rng, _base);
    _base = draw.base;
    _degree = draw.spelling;
  }

  bool get _done => _index > _kTotal;

  void _next() {
    if (_done) return;
    if (_index == _kTotal) {
      // The run is over — land on the summary instead of a 201st number.
      HapticsService.success();
      setState(() => _index++);
      return;
    }
    HapticsService.impactLight();
    _bloom.forward(from: 0);
    setState(() {
      _roll();
      _index++;
    });
  }

  void _restart() {
    HapticsService.impactMedium();
    setState(() {
      _base = '';
      _roll();
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
                      done: _done,
                      onExit: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: _done
                            ? _DoneCard(onRestart: _restart)
                            : _BigDegree(
                                degree: _degree,
                                color: color,
                                pulse: _pulse,
                                bloom: _bloom,
                              ),
                      ),
                    ),
                    if (!_done) _Hint(pulse: _pulse),
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
  final Animation<double> pulse;
  final Animation<double> bloom;

  const _BigDegree({
    required this.degree,
    required this.color,
    required this.pulse,
    required this.bloom,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing halo — gives the number something to sit on, in its own
          // colour, so the screen is never just type on a gradient.
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              final p = Curves.easeInOut.transform(pulse.value);
              return Container(
                width: 300 + 26 * p,
                height: 300 + 26 * p,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.20 + 0.08 * p),
                      color.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              );
            },
          ),
          // Ring blooming out of the centre on every tap: the tap is confirmed
          // by the screen itself, since there is no button to light up.
          AnimatedBuilder(
            animation: bloom,
            builder: (_, __) {
              if (bloom.value == 0 || bloom.value == 1) {
                return const SizedBox.shrink();
              }
              final b = Curves.easeOutCubic.transform(bloom.value);
              return Container(
                width: 180 + 260 * b,
                height: 180 + 260 * b,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.45 * (1 - b)),
                    width: 2.5 * (1 - b) + 0.5,
                  ),
                ),
              );
            },
          ),
          // The degree. Single spellings only, so there is room to set it big.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.78, end: 1).animate(anim),
                child: child,
              ),
            ),
            child: Padding(
              key: ValueKey(degree),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NoteText(
                  note: degree,
                  accidentalLift: 0.34,
                  accidentalScale: 0.48,
                  style: TextStyle(
                    fontSize: 186,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -6,
                    color: Colors.white,
                    height: 1.05,
                    shadows: [
                      Shadow(color: color.withValues(alpha: 0.95), blurRadius: 38),
                      Shadow(color: color.withValues(alpha: 0.55), blurRadius: 90),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hint line ────────────────────────────────────────────────────────────────

class _Hint extends StatelessWidget {
  final Animation<double> pulse;
  const _Hint({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final p = Curves.easeInOut.transform(pulse.value);
          return Opacity(
            opacity: 0.22 + 0.24 * p,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                const Text(
                  'TAP ANYWHERE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Top bar: exit, counter, progress ─────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int index;
  final int total;
  final double progress;
  final bool done;
  final VoidCallback onExit;

  const _TopBar({
    required this.index,
    required this.total,
    required this.progress,
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
                  // The title carries the spectrum too, so the mode is
                  // recognisable from the top of the screen alone.
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: kFreeSpectrum).createShader(b),
                    child: const Text(
                      'FREE MODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done ? '$total / $total' : '$index / $total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.92),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Rainbow-filled progress bar, with a glowing head at the leading
          // edge so progress is legible at a glance from across a room.
          LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth * progress;
              return SizedBox(
                height: 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        height: 6,
                        width: w,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: kFreeSpectrum),
                        ),
                      ),
                    ),
                    if (progress > 0.005)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        left: (w - 4).clamp(0.0, c.maxWidth - 8),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
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
            shaderCallback: (b) => const LinearGradient(colors: kFreeSpectrum).createShader(b),
            child: const Text(
              '$_kTotal',
              style: TextStyle(
                fontSize: 88,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -4,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'NUMBERS DONE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No score, no clock — just the reps.\nGo again whenever you like.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 30),
          PressableScale(
            onTap: onRestart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'GO AGAIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
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
/// Deliberately louder than the app's LivingBackground: Free Mode has one
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
    return List<Offset>.generate(52, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();
  static final List<double> _starPhase = () {
    final r = math.Random(21);
    return List<double>.generate(52, (_) => r.nextDouble());
  }();
  static final List<double> _starSize = () {
    final r = math.Random(43);
    return List<double>.generate(52, (_) => 0.5 + r.nextDouble());
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
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: w);

      final paint = Paint()
        ..blendMode = BlendMode.plus // light adds, so overlaps go white-hot
        ..shader = RadialGradient(
          colors: [colour.withValues(alpha: op * 0.55), colour.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
    }

    // Twinkling stars — the "magic" on top of the aurora. A few carry a soft
    // cross-flare so the field reads as sparkle rather than noise.
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _stars.length; i++) {
      final p = _stars[i];
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + _starPhase[i]));
      final centre = Offset(p.dx * size.width, p.dy * size.height);
      final r = (0.6 + 1.6 * tw) * _starSize[i];
      starPaint.color = Colors.white.withValues(alpha: 0.10 + 0.55 * tw);
      canvas.drawCircle(centre, r, starPaint);

      if (i % 7 == 0 && tw > 0.55) {
        final flare = (tw - 0.55) / 0.45;
        final arm = 5.0 + 9 * flare;
        final flarePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.30 * flare)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(centre.translate(-arm, 0), centre.translate(arm, 0), flarePaint);
        canvas.drawLine(centre.translate(0, -arm), centre.translate(0, arm), flarePaint);
      }
    }

    // Vignette: pulls the eye to the number in the middle.
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.58)],
          stops: const [0.42, 1.0],
        ).createShader(full),
    );
  }

  @override
  bool shouldRepaint(_MagicPainter old) => old.t != t;
}
