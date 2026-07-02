import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/levels.dart';
import 'animal_icon.dart';

class LevelUpModal extends StatefulWidget {
  final AnimalLevel animal;
  final VoidCallback onClose;

  const LevelUpModal({super.key, required this.animal, required this.onClose});

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _haloCtrl;
  late final AnimationController _rayCtrl;
  late final AnimationController _glowCtrl; // full-screen edge glow pulse
  late final AnimationController _boxCtrl;
  late final AnimationController _iconCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _btnCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
    _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _rayCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _boxCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _btnCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _iconCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _textCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _btnCtrl.forward(); });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _haloCtrl.dispose();
    _rayCtrl.dispose();
    _glowCtrl.dispose();
    _boxCtrl.dispose();
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.animal.color;

    return GestureDetector(
      onTap: widget.onClose,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl, _haloCtrl, _rayCtrl, _glowCtrl, _boxCtrl, _iconCtrl, _textCtrl, _btnCtrl,
        ]),
        builder: (context, _) {
          final bgOpacity = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut).value;
          final glowPulse = 0.65 + 0.35 * CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut).value;

          final haloAnim = CurvedAnimation(parent: _haloCtrl, curve: Curves.easeOut);
          final haloScale = Tween<double>(begin: 0.5, end: 1.2).animate(haloAnim).value;

          final rayAngle = _rayCtrl.value * 2 * math.pi;

          final boxAnim    = CurvedAnimation(parent: _boxCtrl, curve: Curves.easeOutBack);
          final boxScale   = Tween<double>(begin: 0.8, end: 1.0).animate(boxAnim).value;
          final boxSlide   = Tween<double>(begin: 20.0, end: 0.0).animate(boxAnim).value;
          final boxOpacity = CurvedAnimation(parent: _boxCtrl, curve: Curves.easeOut).value;

          final iconScale  = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut))
              .value.clamp(0.0, 1.5);
          final iconRotate = Tween<double>(begin: -math.pi, end: 0.0)
              .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut))
              .value;

          final textAnim    = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
          final textOpacity = textAnim.value;
          final textSlide   = Tween<double>(begin: 10.0, end: 0.0).animate(textAnim).value;

          final btnAnim    = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
          final btnOpacity = btnAnim.value;
          final btnSlide   = Tween<double>(begin: 10.0, end: 0.0).animate(btnAnim).value;

          return Opacity(
            opacity: bgOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop: black/90 + blur-sm
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black.withValues(alpha:0.9)),
                ),

                // Full-screen pulsing edge glow in the animal colour (the web's
                // .level-glow-overlay). Fills the whole screen from every edge
                // instead of being confined to a centered circle.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        for (final edge in const [
                          Alignment.topCenter,
                          Alignment.bottomCenter,
                          Alignment.centerLeft,
                          Alignment.centerRight,
                        ])
                          Align(
                            alignment: edge,
                            child: Container(
                              width: (edge == Alignment.centerLeft || edge == Alignment.centerRight)
                                  ? 150 : double.infinity,
                              height: (edge == Alignment.topCenter || edge == Alignment.bottomCenter)
                                  ? 220 : double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: edge,
                                  end: -edge,
                                  colors: [color.withValues(alpha:0.45 * glowPulse), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Outer halo glow (250% width, radial gradient + blur)
                Center(
                  child: Transform.scale(
                    scale: haloScale,
                    child: LayoutBuilder(builder: (ctx, cns) {
                      final w = cns.maxWidth == double.infinity ? 360.0 : cns.maxWidth;
                      final size = w * 2.5;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withValues(alpha:0.33),
                              color.withValues(alpha:0.067),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 0.7],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Rotating sun rays (300% width, conic-like)
                Center(
                  child: Transform.rotate(
                    angle: rayAngle,
                    child: LayoutBuilder(builder: (ctx, cns) {
                      final w = cns.maxWidth == double.infinity ? 360.0 : cns.maxWidth;
                      final size = w * 3.0;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: CustomPaint(painter: _RaysPainter(color: color)),
                      );
                    }),
                  ),
                ),

                // Modal card (absorbs taps so backdrop-close doesn't fire)
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Opacity(
                      opacity: boxOpacity,
                      child: Transform.translate(
                        offset: Offset(0, boxSlide),
                        child: Transform.scale(
                          scale: boxScale,
                          child: _ModalCard(
                            color: color,
                            iconScale: iconScale,
                            iconRotate: iconRotate,
                            textOpacity: textOpacity,
                            textSlide: textSlide,
                            btnOpacity: btnOpacity,
                            btnSlide: btnSlide,
                            animal: widget.animal,
                            onClose: widget.onClose,
                          ),
                        ),
                      ),
                    ),
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

// ── Modal card widget ─────────────────────────────────────────────────────────

class _ModalCard extends StatelessWidget {
  final Color color;
  final double iconScale;
  final double iconRotate;
  final double textOpacity;
  final double textSlide;
  final double btnOpacity;
  final double btnSlide;
  final AnimalLevel animal;
  final VoidCallback onClose;

  const _ModalCard({
    required this.color,
    required this.iconScale,
    required this.iconRotate,
    required this.textOpacity,
    required this.textSlide,
    required this.btnOpacity,
    required this.btnSlide,
    required this.animal,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: color.withValues(alpha:0.4), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha:0.133), blurRadius: 80),
          BoxShadow(color: color.withValues(alpha:0.067), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: Stack(
        children: [
          // Top radial gradient decoration
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [color.withValues(alpha:0.2), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animal icon — rounded-3xl box (24px radius)
                Transform.rotate(
                  angle: iconRotate,
                  child: Transform.scale(
                    scale: iconScale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: color.withValues(alpha:0.533), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha:0.4),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimalIcon(name: animal.name, color: color, size: 52),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Text block: Level Up! + name + quote
                Opacity(
                  opacity: textOpacity,
                  child: Transform.translate(
                    offset: Offset(0, textSlide),
                    child: Column(
                      children: [
                        // "LEVEL UP!" in animal color
                        Text(
                          'Level Up!',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color.withValues(alpha:0.8),
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // "You are now a [Name]!" with gradient on name
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.75,
                              fontFamily: 'Lexend',
                            ),
                            children: [
                              const TextSpan(text: 'You are now a '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [color, color.withValues(alpha:0.67)],
                                  ).createShader(bounds),
                                  child: Text(
                                    animal.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.75,
                                      fontFamily: 'Lexend',
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: '!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quote
                        Text(
                          animal.quote,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha:0.6),
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // "Awesome!" button
                Opacity(
                  opacity: btnOpacity,
                  child: Transform.translate(
                    offset: Offset(0, btnSlide),
                    child: _AwesomeButton(color: color, onTap: onClose),
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

// ── Sun rays painter ──────────────────────────────────────────────────────────

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 3000.0; // Estendi i raggi all'infinito oltre i bordi dello schermo
    final paint = Paint()
      ..color = color.withValues(alpha:0.17)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final startAngle = i * (math.pi / 6);        // every 30°
      const sweepAngle = math.pi / 18;             // 10° wide
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

// ── Awesome button with press feedback ───────────────────────────────────────

class _AwesomeButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  const _AwesomeButton({required this.color, required this.onTap});

  @override
  State<_AwesomeButton> createState() => _AwesomeButtonState();
}

class _AwesomeButtonState extends State<_AwesomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha:0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha:0.267),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'Awesome!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
