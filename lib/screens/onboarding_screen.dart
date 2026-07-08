import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'legal_screen.dart';

/// First-launch welcome — a single, premium screen with one call to action.
/// (If you ever want a full-bleed lifestyle photo instead of the chord hero,
/// drop an image into [_ChordHero].)
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))..forward();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  // Fade + slide-up over an interval of the entrance controller (stagger).
  Widget _in(double start, double end, {double dy = 26, required Widget child}) {
    final anim = CurvedAnimation(parent: _enter, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - anim.value) * dy), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(children: [
        // Rich layered background.
        Positioned.fill(child: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1C1338), Color(0xFF0F0A1A), Color(0xFF0F0A1A)],
          ),
        ))),
        Positioned(top: -90, right: -70, child: _glow(300, const Color(0x33A855F7))),
        Positioned(bottom: -110, left: -90, child: _glow(320, const Color(0x2622D3EE))),
        _FloatingSymbols(controller: _float),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
            child: Column(children: [
              const Spacer(flex: 3),
              _in(0.0, 0.55, dy: 38, child: const _ChordHero()),
              const Spacer(flex: 2),
              _in(0.18, 0.7, child: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFFA855F7), Color(0xFFEC4899)],
                ).createShader(b),
                child: const Text('Improvy',
                  style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2, height: 1)),
              )),
              const SizedBox(height: 16),
              _in(0.3, 0.82, child: Text(
                'Train your mind to recognize\nevery note and degree, instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: Colors.white.withValues(alpha: 0.55)),
              )),
              const Spacer(flex: 3),
              _in(0.45, 1.0, dy: 18, child: _GetStartedButton(onTap: widget.onComplete)),
              const SizedBox(height: 16),
              _in(0.6, 1.0, dy: 8, child: _legalLinks(context)),
              const SizedBox(height: 4),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _legalLinks(BuildContext context) {
    TextStyle s(bool link) => TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: link ? 0.5 : 0.22));
    void open(String t, String b) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LegalScreen(title: t, body: b)));
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      GestureDetector(onTap: () => open('Privacy Policy', kPrivacyPolicyBody), child: Text('Privacy Policy', style: s(true))),
      Text('   •   ', style: s(false)),
      GestureDetector(onTap: () => open('Terms of Service', kTermsBody), child: Text('Terms of Service', style: s(true))),
    ]);
  }

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent], stops: const [0.0, 0.7]),
    ),
  );
}

// ── Hero: a fanned C–E–G major triad in the app's note colours ────────────────

class _ChordHero extends StatelessWidget {
  const _ChordHero();

  Widget _tile(String note, Color color, double angle, Offset offset) => Transform.translate(
    offset: offset,
    child: Transform.rotate(
      angle: angle,
      child: Container(
        width: 108, height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.20)!, color],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 30, offset: const Offset(0, 12), spreadRadius: -4)],
        ),
        alignment: Alignment.center,
        child: Text(note,
          style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white,
            shadows: [Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2))])),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, width: 280,
      child: Stack(alignment: Alignment.center, children: [
        _tile('C', const Color(0xFFFF4D4D), -0.22, const Offset(-82, 16)),
        _tile('G', const Color(0xFF4D6DFF), 0.22, const Offset(82, 16)),
        _tile('E', const Color(0xFF34D399), 0.0, const Offset(0, -10)), // front
      ]),
    );
  }
}

// ── Single premium CTA ────────────────────────────────────────────────────────

class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 12))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('GET STARTED', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F0A1A), letterSpacing: 2)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F0A1A), size: 20),
          ],
        ),
      ),
    ),
  );
}

// ── Subtle floating musical symbols ───────────────────────────────────────────

class _FloatingSymbols extends StatelessWidget {
  final AnimationController controller;
  const _FloatingSymbols({required this.controller});

  static const _items = [
    (0.12, 0.18, 60.0, 0.0),
    (0.82, 0.30, 70.0, 1.4),
    (0.18, 0.74, 84.0, 2.6),
    (0.74, 0.82, 52.0, 3.6),
  ];
  static const _glyphs = ['♪', '♫', '𝄞', '♩'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Stack(children: [
          for (int i = 0; i < _items.length; i++)
            Positioned(
              left: _items[i].$1 * size.width,
              top: _items[i].$2 * size.height + math.sin(controller.value * 2 * math.pi + _items[i].$4) * 14,
              child: Transform.rotate(
                angle: math.sin(controller.value * 2 * math.pi + _items[i].$4) * 0.12,
                child: Text(_glyphs[i],
                  style: TextStyle(fontSize: _items[i].$3, color: Colors.white.withValues(alpha: 0.05))),
              ),
            ),
        ]),
      ),
    );
  }
}
