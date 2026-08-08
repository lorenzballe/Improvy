import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../services/haptics_service.dart';
import '../utils/music_engine.dart';
import '../widgets/note_text.dart';
import '../widgets/pressable_scale.dart';

/// Free Mode — a self-paced drill with no answers, no timer and no score.
///
/// One degree fills the ring; a tap anywhere brings the next one. Nothing is
/// checked and nothing is counted right or wrong: the point is to work the
/// calculation out in your own head, in whatever key you like, and move on when
/// *you* are ready. A run is [_kTotal] numbers, tracked by the bar in the
/// session card — the only structure the mode imposes.
///
/// The chrome is deliberately the app's own: the 48px round exit, the centred
/// spaced title, the frosted session card with its progress bar over a stat
/// row, and the contour ring around the number — all the same as Pocket Mode
/// and the trainer, so this reads as a first-class mode rather than a screen
/// borrowed from somewhere else.
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

/// The spectrum as six hard bands instead of a smooth blend.
///
/// For a mark only a few dozen pixels across, a continuous gradient spends
/// most of its width on the transitions and every hue comes out muddied — the
/// thing stops reading as a rainbow at all. Repeating each colour at both ends
/// of its own stop gives clean steps, so all six stay identifiable however
/// small the glyph is. Runs diagonally by default: across a square icon that
/// is the longest line available, so each band gets the most room.
LinearGradient freeSpectrumBands({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) =>
    LinearGradient(
      begin: begin,
      end: end,
      colors: [for (final c in kFreeSpectrum) ...[c, c]],
      stops: [
        for (var i = 0; i < kFreeSpectrum.length; i++) ...[
          i / kFreeSpectrum.length,
          (i + 1) / kFreeSpectrum.length,
        ],
      ],
    );

/// Draws the next Free Mode degree, named exactly the way Chromatic mode names
/// the degree it asks for — a **single** number, never a slash pair.
///
/// The naming goes through [chromaticDegreeNames], the same call the trainer's
/// `_askedName` and Pocket Mode's voice use, so the three modes can never drift
/// apart about what a degree may be called. That means both enharmonic
/// spellings (♭3 / ♯2) *and* the upper-structure names a chart actually prints
/// (2 also asks as 9, ♯4 as ♯11, ♭6 as ♭13), each with an equal share.
///
/// The pitch is drawn first, over the twelve semitones rather than over the
/// names: drawing from the names would make the pitches with three of them turn
/// up three times as often as ones with a single name. [previousBase] is
/// excluded so the same pitch never comes up twice running — a repeat reads as
/// a missed tap rather than a new question, and it would read that way even
/// when the two draws name it differently. Returns both the semitone drawn (to
/// pass back in next time) and the name to show.
({String base, String spelling}) nextFreeDegree(math.Random rng, String previousBase) {
  var base = previousBase;
  while (base == previousBase) {
    base = kChromaticDegrees[rng.nextInt(kChromaticDegrees.length)];
  }
  final names = chromaticDegreeNames(base);
  return (base: base, spelling: names[rng.nextInt(names.length)]);
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

  /// Breathes the ambient wash and the hint, exactly as Pocket Mode's does.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _roll();
  }

  @override
  void dispose() {
    _pulse.dispose();
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
    // Upper-structure names (9, ♯11, ♭13 …) aren't keys in the colour map —
    // they are the same pitch as their base degree and must be lit the same,
    // or a 9 would come up white while a 2 came up yellow.
    final live = AppColors.degreeColors[normalizeExtension(_degree)] ?? Colors.white;
    final donePart = (_index - 1).clamp(0, _kTotal);
    final progress = donePart / _kTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Slow rainbow aurora, kept low and desaturated so it stays a lit
          // room rather than a poster competing with the number.
          const Positioned.fill(child: _Aurora()),
          // Ambient wash in the live degree's colour — the same move Pocket
          // Mode makes, so the background answers the content instead of
          // ignoring it. Painted once per degree; only opacity breathes.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Opacity(
                opacity: 0.62 + 0.38 * Curves.easeInOut.transform(_pulse.value),
                child: child,
              ),
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.95,
                      colors: [live.withValues(alpha: 0.16), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: -90, right: -70, child: _blob(300, live.withValues(alpha: 0.10))),
          Positioned(bottom: -80, left: -60, child: _blob(260, const Color(0xFF7C3AED).withValues(alpha: 0.10))),

          // The whole stage advances — there is no button to hunt for, which
          // is what makes it usable with your eyes on an instrument. The exit
          // and the "go again" button sit deeper in the tree, so they win
          // their own taps.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _done ? null : _next,
            child: SafeArea(
              child: Column(
                children: [
                  _topBar(context),
                  const SizedBox(height: 12),
                  _sessionCard(donePart, progress),
                  Expanded(
                    child: Center(
                      child: _done
                          ? _DoneCard(onRestart: _restart)
                          : _stage(live),
                    ),
                  ),
                  if (!_done) _Hint(pulse: _pulse),
                  SizedBox(height: 12 + MediaQuery.of(context).padding.bottom * 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar: the app's, verbatim — round exit, spaced title, round badge ──

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          PressableScale(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10, width: 1.2),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20)],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
            ),
          ),
          const Expanded(
            child: Text('FREE MODE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
          ),
          // Mirrors the trainer's key badge, carrying the mode's rainbow mark
          // instead of a key — the same star that opens it from Settings.
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(51), width: 1.2),
            ),
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => freeSpectrumBands().createShader(b),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ]),
      );

  // ── Session card: the app's signature frosted card ──

  Widget _sessionCard(int donePart, double progress) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: const Color(0x1A1A1625),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10, width: 1.2),
          ),
          child: Column(children: [
            LayoutBuilder(
              builder: (ctx, bc) => TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                builder: (_, p, __) => SizedBox(
                  height: 6,
                  child: Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    // The spectrum is laid out across the WHOLE track and
                    // revealed as the run goes, so colours arrive in their own
                    // places a few numbers at a time. Painting it into the
                    // filled part instead squeezed the entire rainbow into
                    // whatever was done so far — every colour present from the
                    // first tap, the lot stretching as you played.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: p.clamp(0.0, 1.0),
                        child: Container(
                          width: bc.maxWidth,
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: kFreeSpectrum),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _stat('DONE', '$donePart')),
              Container(width: 1, height: 28, color: Colors.white10),
              Expanded(child: _stat('LEFT', '${_kTotal - donePart}')),
              Container(width: 1, height: 28, color: Colors.white10),
              Expanded(child: _stat('RUN', '$_kTotal')),
            ]),
          ]),
        ),
      );

  /// Stat cell — matches the trainer's and Pocket Mode's exactly.
  Widget _stat(String label, String value) => Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, softWrap: false,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 2)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, softWrap: false,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      );

  // ── Stage: the number inside the app's contour ring ──

  Widget _stage(Color live) => LayoutBuilder(builder: (ctx, c) {
        // Fit the ring to whatever room is left: never wider than the stage,
        // never taller than the space available, capped so it stays elegant on
        // big screens. Same sizing rule Pocket Mode uses.
        // Never larger than the room actually given. Clamping the height up to
        // a minimum first would hand back a ring taller than the stage on a
        // short screen, which is an overflow rather than a small ring.
        final ring = math.min(280.0, math.min(c.maxWidth - 32, c.maxHeight));
        return SizedBox(
          width: ring,
          height: ring,
          child: Stack(alignment: Alignment.center, children: [
            RepaintBoundary(
              child: CustomPaint(
                size: Size(ring, ring),
                painter: _RingPainter(color: live),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ring * 0.18),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.80, end: 1).animate(anim),
                    child: child,
                  ),
                ),
                child: FittedBox(
                  key: ValueKey(_degree),
                  fit: BoxFit.scaleDown,
                  child: NoteText(
                    note: _degree,
                    accidentalLift: 0.30,
                    accidentalScale: 0.52,
                    style: TextStyle(
                      fontSize: 112,
                      fontWeight: FontWeight.w900,
                      color: live,
                      height: 1,
                      shadows: [Shadow(color: live.withValues(alpha: 0.45), blurRadius: 34)],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      });

  Widget _blob(double size, Color color) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      );
}

// ── Hint pill ────────────────────────────────────────────────────────────────

/// Glass pill, like the app's other bottom chrome, breathing so it reads as an
/// invitation rather than a label.
class _Hint extends StatelessWidget {
  final Animation<double> pulse;
  const _Hint({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 8),
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final p = Curves.easeInOut.transform(pulse.value);
          return Opacity(
            opacity: 0.55 + 0.45 * p,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white10, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 9),
                  Text(
                    'TAP ANYWHERE FOR THE NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
        decoration: BoxDecoration(
          color: const Color(0x1A1A1625),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: kFreeSpectrum).createShader(b),
              child: const Text(
                '$_kTotal',
                style: TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -3,
                  height: 1.05,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'NUMBERS DONE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No score, no clock — just the reps.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            PressableScale(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 10)),
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
      ),
    );
  }
}

// ── Contour ring ─────────────────────────────────────────────────────────────

/// The same ring the trainer and Pocket Mode draw around the big number, at
/// rest: a faint full track with the coloured contour and its glow on top.
class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}

// ── Aurora ───────────────────────────────────────────────────────────────────

/// A slow rainbow wash with a scatter of twinkling stars.
///
/// Kept low and desaturated on purpose. An earlier pass ran the blobs at full
/// saturation in additive blend, which blew the overlaps out to white and left
/// the number fighting its own background — the opposite of what the rest of
/// the app does, where the room is lit and the content is the brightest thing
/// in it.
class _Aurora extends StatefulWidget {
  const _Aurora();

  @override
  State<_Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<_Aurora> with SingleTickerProviderStateMixin {
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(size: Size.infinite, painter: _AuroraPainter(_c.value)),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  /// Loops 0 → 1.
  final double t;
  const _AuroraPainter(this.t);

  // Fixed scatter, generated once from a fixed seed so the stars keep their
  // places between frames (a fresh Random each paint would make them jump).
  static final List<Offset> _stars = () {
    final r = math.Random(7);
    return List<Offset>.generate(38, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();
  static final List<double> _starPhase = () {
    final r = math.Random(21);
    return List<double>.generate(38, (_) => r.nextDouble());
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas.drawRect(full, Paint()..color = AppColors.background);

    // Three wide blobs, each on its own arc of the colour wheel and rotating
    // through it, so the room is always a slightly different colour.
    const blobs = [
      (Offset(0.16, 0.12), Offset(0.09, 0.06), 1.25),
      (Offset(0.88, 0.30), Offset(0.08, 0.06), 1.15),
      (Offset(0.40, 0.88), Offset(0.10, 0.07), 1.30),
    ];

    for (var i = 0; i < blobs.length; i++) {
      final (base, drift, spread) = blobs[i];
      final phase = i / blobs.length;
      final a = 2 * math.pi * (t + phase);

      final cx = (base.dx + drift.dx * math.sin(a)) * size.width;
      final cy = (base.dy + drift.dy * math.cos(a * 0.75)) * size.height;

      final hue = ((t + phase) * 360) % 360;
      // Held well below full: this is a lit room, not a poster.
      final colour = HSVColor.fromAHSV(1, hue, 0.55, 0.80).toColor();
      final op = 0.16 + 0.06 * math.sin(a * 1.2);

      final w = spread * size.width;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: w);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [colour.withValues(alpha: op.clamp(0.0, 1.0)), colour.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    // Twinkling stars — the quiet bit of magic, dim enough to stay behind.
    final star = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _stars.length; i++) {
      final p = _stars[i];
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 2 + _starPhase[i]));
      star.color = Colors.white.withValues(alpha: 0.06 + 0.30 * tw);
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        0.6 + 1.2 * tw,
        star,
      );
    }

    // Vignette: pulls the eye to the ring in the middle.
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0.45, 1.0],
        ).createShader(full),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
