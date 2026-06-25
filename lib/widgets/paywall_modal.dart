import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium "Improvy PRO" paywall — gold/amber themed to match the web original
/// (crown badge, gradient PRO wordmark, four feature rows, one-time CTA).
class PaywallModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onPurchase;

  const PaywallModal({super.key, required this.onClose, required this.onPurchase});

  @override
  State<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends State<PaywallModal>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  late final Animation<double> _scale;

  static const _amber = Color(0xFFFBBF24);
  static const _amberSoft = Color(0xFFFCD34D);
  static const _orange = Color(0xFFF97316);
  static const _orangeDeep = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 30, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Opacity(opacity: _fade.value.clamp(0.0, 1.0), child: child),
      child: GestureDetector(
        onTap: widget.onClose,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.85),
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: Transform.scale(scale: _scale.value, child: child),
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      constraints: const BoxConstraints(maxWidth: 460),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1625),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 80, offset: const Offset(0, 40)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(children: [
                        // Ambient glows — purple top-right, amber bottom-left (web).
                        Positioned(top: -48, right: -48, child: _glow(256, const Color(0x26A855F7))),
                        Positioned(bottom: -48, left: -48, child: _glow(256, const Color(0x1AF59E0B))),

                        // Content
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Crown badge: pulsing halo + twinkling sparkle
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, __) {
                                  final p = _pulse.value; // 0..1
                                  return SizedBox(
                                    width: 96, height: 96,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        // Soft amber halo that gently breathes.
                                        Container(
                                          width: 84 + 26 * p, height: 84 + 26 * p,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [_amber.withOpacity(0.10 + 0.16 * p), Colors.transparent],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 84, height: 84,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(26),
                                            gradient: LinearGradient(
                                              colors: [_amber.withOpacity(0.20), _orangeDeep.withOpacity(0.20)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            border: Border.all(color: _amber.withOpacity(0.30)),
                                            boxShadow: const [BoxShadow(color: Color(0x33F59E0B), blurRadius: 40)],
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.workspace_premium_rounded, color: _amber, size: 44),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2, right: 2,
                                          child: Opacity(
                                            opacity: 0.5 + 0.5 * p,
                                            child: Transform.scale(
                                              scale: 0.8 + 0.35 * p,
                                              child: const Icon(Icons.auto_awesome, color: _amberSoft, size: 24),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── Title: Improvy PRO ─────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text('Improvy ',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                                  ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(
                                      colors: [_amberSoft, _orange],
                                    ).createShader(b),
                                    child: const Text('PRO',
                                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Unlock advanced training modes and achieve total mastery of every scale.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5), height: 1.45),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── Features ───────────────────────────────────
                              ..._features.map((f) => _FeatureRow(icon: f.$1, title: f.$2, desc: f.$3)),
                              const SizedBox(height: 28),

                              // ── CTA ────────────────────────────────────────
                              _BuyButton(onTap: widget.onPurchase),
                              const SizedBox(height: 16),
                              Text(
                                'ONE-TIME PURCHASE • LIFETIME ACCESS',
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(0.22), letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Close (X) ─────────────────────────────────────────
                        Positioned(
                          top: 16, right: 16,
                          child: GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent], stops: const [0.0, 0.6]),
    ),
  );
}

// (icon, title, description) — mirrors the web feature list.
const _features = [
  (Icons.piano_rounded,        'Chromatic Mode',      'Master all 12 chromatic keys with ease'),
  (Icons.swap_horiz_rounded,   'Note to Number',      'Identify degrees from notes instantly'),
  (Icons.psychology_rounded,   'Adaptive Difficulty', 'Auto-adjusts to your skill level'),
  (Icons.analytics_rounded,    'Deep Analytics',      'Track your progress constantly'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: const Color(0xFFFBBF24).withOpacity(0.85), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), height: 1)),
          ],
        )),
      ]),
    ),
  );
}

class _BuyButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BuyButton({required this.onTap});

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shim;

  @override
  void initState() {
    super.initState();
    _shim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _shim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: AnimatedBuilder(
        animation: _shim,
        builder: (ctx, _) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: const [BoxShadow(color: Color(0x40F59E0B), blurRadius: 35, offset: Offset(0, 15))],
          ),
          child: Stack(children: [
            // Sweeping shimmer
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    begin: Alignment(-3 + _shim.value * 6, 0),
                    end: Alignment(-2 + _shim.value * 6, 0),
                    colors: [Colors.transparent, Colors.white.withOpacity(0.22), Colors.transparent],
                  ).createShader(b),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GET PRO FOREVER',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(r'$16.99',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}
