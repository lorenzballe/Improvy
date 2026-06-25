import 'dart:math' as math;
import 'package:flutter/material.dart';

/// First-launch introduction — three themed slides with floating musical
/// symbols, a segmented progress bar and gradient titles (matches the web
/// OnboardingTutorial).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final String kicker;
  final String title;
  final String desc;
  final IconData icon;
  final Color accent;
  final Color bgTint;
  const _Slide(this.kicker, this.title, this.desc, this.icon, this.accent, this.bgTint);
}

const _slides = [
  _Slide(
    'THE CORE CONCEPT',
    'Mental Mapping',
    'Stop relying on shapes and patterns. Train your brain to instantly visualize notes, intervals, and scales across your instrument.',
    Icons.psychology_rounded,
    Color(0xFF22D3EE),
    Color(0xFF083344),
  ),
  _Slide(
    'YOUR JOURNEY',
    'Diatonic to Chromatic',
    "Start by mastering the 7 notes of the major scale. Once you're ready, unlock all 12 semitones for absolute musical freedom.",
    Icons.layers_rounded,
    Color(0xFFC084FC),
    Color(0xFF3B0764),
  ),
  _Slide(
    'TRACK PROGRESS',
    'Evolve Your Skills',
    'Build your daily streak, achieve perfect scores, and watch your rank evolve from a humble Snail to a lightning-fast Cheetah.',
    Icons.trending_up_rounded,
    Color(0xFFFBBF24),
    Color(0xFF451A03),
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _float;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final last = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1A),
      body: Stack(
        children: [
          // Per-slide tinted gradient background.
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(slide.bgTint, const Color(0xFF0F0A1A), 0.4)!,
                  const Color(0xFF0F0A1A),
                  const Color(0xFF0F0A1A),
                ],
              ),
            ),
          ),

          // Floating musical symbols.
          _FloatingSymbols(controller: _float),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Segmented progress bar.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      for (int i = 0; i < _slides.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 4,
                              color: Colors.white.withOpacity(0.1),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  widthFactor: i <= _currentPage ? 1.0 : 0.0,
                                  child: Container(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Slides.
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _SlideContent(slide: _slides[i]),
                  ),
                ),

                // CTA + skip.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      _ContinueButton(label: last ? 'START TRAINING' : 'CONTINUE', showChevron: !last, onTap: _next),
                      SizedBox(
                        height: 40,
                        child: Center(
                          child: last
                              ? null
                              : GestureDetector(
                                  onTap: widget.onComplete,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'SKIP INTRODUCTION',
                                      style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w800,
                                        color: Colors.white.withOpacity(0.3), letterSpacing: 1.6,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
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

// ── One slide: glassmorphism icon, kicker, gradient title, description ─────────

class _SlideContent extends StatelessWidget {
  final _Slide slide;
  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in a glass tile, with a soft accent glow behind it.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -10, top: -10,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [slide.accent.withOpacity(0.4), Colors.transparent]),
                  ),
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(slide.icon, color: slide.accent, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 40),

          Text(
            slide.kicker,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.5), letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),

          // Title — subtle white→white/60 gradient.
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white.withOpacity(0.6)],
            ).createShader(b),
            child: Text(
              slide.title,
              style: const TextStyle(
                fontSize: 38, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: -1.2, height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            slide.desc,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.5), height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating musical symbols (ambient background motion) ──────────────────────

class _FloatingSymbols extends StatelessWidget {
  final AnimationController controller;
  const _FloatingSymbols({required this.controller});

  static const _symbols = [
    (0.10, 0.15, 64.0, 0.0),
    (0.80, 0.40, 76.0, 1.0),
    (0.15, 0.68, 92.0, 2.0),
    (0.72, 0.80, 56.0, 3.0),
    (0.55, 0.25, 48.0, 1.5),
  ];
  static const _glyphs = ['♪', '♫', '𝄞', '♩', '𝄢'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Stack(
            children: [
              for (int i = 0; i < _symbols.length; i++)
                Positioned(
                  left: _symbols[i].$1 * size.width,
                  top: _symbols[i].$2 * size.height +
                      math.sin((controller.value * 2 * math.pi) + _symbols[i].$4) * 16,
                  child: Transform.rotate(
                    angle: math.sin((controller.value * 2 * math.pi) + _symbols[i].$4) * 0.15,
                    child: Text(
                      _glyphs[i],
                      style: TextStyle(
                        fontSize: _symbols[i].$3,
                        color: Colors.white.withOpacity(0.07),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Continue / Start button (white, dark label) ───────────────────────────────

class _ContinueButton extends StatefulWidget {
  final String label;
  final bool showChevron;
  final VoidCallback onTap;
  const _ContinueButton({required this.label, required this.showChevron, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900,
                color: Color(0xFF0F0A1A), letterSpacing: 2,
              ),
            ),
            if (widget.showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F0A1A), size: 20),
            ],
          ],
        ),
      ),
    ),
  );
}
