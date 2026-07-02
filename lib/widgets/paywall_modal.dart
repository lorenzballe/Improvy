import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../screens/legal_screen.dart';
import '../services/purchase_service.dart';

/// Full-screen, premium "Improvy PRO" paywall.
///
/// Shares the welcome screen's design language — layered gradient background,
/// soft glows, drifting musical glyphs and a staggered entrance — themed gold
/// for PRO. Content scrolls; the call-to-action stays pinned at the bottom.
class PaywallModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onPurchase;

  const PaywallModal({super.key, required this.onClose, required this.onPurchase});

  @override
  State<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends State<PaywallModal> with TickerProviderStateMixin {
  late final AnimationController _enter; // staggered entrance
  late final AnimationController _float; // drifting glyphs + breathing glow

  bool _restoring = false;

  static const _amber = Color(0xFFFBBF24);
  static const _amberSoft = Color(0xFFFCD34D);
  static const _orange = Color(0xFFF97316);
  static const _fallbackPrice = '€16,99';

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    // Price is shown statically as [_fallbackPrice] (€16,99) for now. Once the
    // real store product price is configured, swap back to the live, auto-
    // localized price via PurchaseService.instance.proPriceString().
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  // Fade + slide-up over an interval of the entrance controller (stagger).
  Widget _in(double start, double end, {double dy = 24, required Widget child}) {
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

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final ok = await PurchaseService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (ok) {
      widget.onClose();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No previous purchase found'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _openLegal(String title, String body) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LegalScreen(title: title, body: body)));

  @override
  Widget build(BuildContext context) {
    // Gentle overall fade so the screen doesn't pop in.
    final reveal = CurvedAnimation(parent: _enter, curve: const Interval(0.0, 0.25));
    return AnimatedBuilder(
      animation: reveal,
      builder: (_, child) => Opacity(opacity: reveal.value.clamp(0.0, 1.0), child: child),
      child: Material(
        color: const Color(0xFF0F0A1A),
        child: Stack(children: [
          // ── Layered background ─────────────────────────────────────────────
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF231A3F), Color(0xFF0F0A1A), Color(0xFF0F0A1A)],
            ),
          ))),
          Positioned(top: -110, right: -90, child: _glow(340, _amber.withValues(alpha: 0.18))),
          Positioned(top: 140, left: -120, child: _glow(300, const Color(0x33A855F7))),
          Positioned(bottom: -130, right: -70, child: _glow(320, const Color(0x2622D3EE))),
          _FloatingSymbols(controller: _float),

          SafeArea(
            child: Stack(children: [
              Column(children: [
              // ── Scrollable content (rises to the very top of the screen) ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 6, 26, 6),
                  child: Column(children: [
                    _in(0.0, 0.5, dy: 36, child: _ProEmblem(float: _float)),
                    const SizedBox(height: 16),
                    _in(0.12, 0.6, child: _wordmark()),
                    const SizedBox(height: 10),
                    _in(0.2, 0.68, child: Text(
                      'Unlock every mode and master\nall 12 keys — forever.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.45,
                        color: Colors.white.withValues(alpha: 0.55)),
                    )),
                    const SizedBox(height: 26),
                    for (int i = 0; i < _features.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _in(0.3 + i * 0.07, 0.78 + i * 0.05, dy: 16,
                          child: _FeatureRow(icon: _features[i].$1, title: _features[i].$2, desc: _features[i].$3)),
                      ),
                  ]),
                ),
              ),

              // ── Pinned CTA ───────────────────────────────────────────────
              _in(0.62, 1.0, dy: 18, child: _bottomBar(context)),
            ]),
              // ── Close (X): floats over the top-right corner ──────────────
              Positioned(top: 2, right: 12, child: _CloseButton(onTap: widget.onClose)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _wordmark() => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFFA855F7), Color(0xFFEC4899)],
          ).createShader(b),
          child: const Text('Improvy ',
            maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.4, height: 1)),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [_amberSoft, _orange]).createShader(b),
          child: const Text('PRO',
            maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.4, height: 1)),
        ),
      ],
    ),
  );

  Widget _bottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _BuyButton(label: 'Unlock $_fallbackPrice', onTap: widget.onPurchase),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text('One-time purchase  ·  lifetime access',
            maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5))),
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            _miniLink(_restoring ? 'Restoring…' : 'Restore', _restoring ? null : _restore),
            _dot(),
            _miniLink('Terms', () => _openLegal('Terms of Service', kTermsBody)),
            _dot(),
            _miniLink('Privacy', () => _openLegal('Privacy Policy', kPrivacyPolicyBody)),
          ]),
        ),
        const SizedBox(height: 2),
      ]),
    );
  }

  Widget _miniLink(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Text(text, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: onTap == null ? 0.3 : 0.5))),
  );

  Widget _dot() => Text('   ·   ',
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.22)));

  Widget _glow(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent], stops: const [0.0, 0.7]),
    ),
  );
}

// ── Hero: a glowing gold PRO emblem with twinkling sparkles ───────────────────

class _ProEmblem extends StatelessWidget {
  final AnimationController float;
  const _ProEmblem({required this.float});

  static const _amberSoft = Color(0xFFFCD34D);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: float,
      builder: (_, _) {
        final t = float.value * 2 * math.pi;
        final breathe = (math.sin(t) + 1) / 2; // 0..1
        return SizedBox(
          width: 200, height: 176,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            // Soft breathing glow — purple, echoing the brand gradient.
            Container(
              width: 172 + 20 * breathe, height: 172 + 20 * breathe,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFA855F7).withValues(alpha: 0.16 + 0.10 * breathe), Colors.transparent],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
            // The official app logo with a colourful drop shadow so it lifts off.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(31),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.42), blurRadius: 42, offset: const Offset(-9, 15), spreadRadius: -8),
                  BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.34), blurRadius: 42, offset: const Offset(11, 17), spreadRadius: -10),
                ],
              ),
              child: const _AppLogo(size: 134),
            ),
            // Twinkling gold sparkles for a touch of magic.
            _sparkle(const Offset(76, -58), 25, breathe),
            _sparkle(const Offset(-78, 40), 19, (math.sin(t + 2.4) + 1) / 2),
          ]),
        );
      },
    );
  }

  Widget _sparkle(Offset offset, double size, double p) => Transform.translate(
    offset: offset,
    child: Opacity(
      opacity: 0.35 + 0.55 * p,
      child: Transform.scale(
        scale: 0.7 + 0.4 * p,
        child: Icon(Icons.auto_awesome, color: _amberSoft, size: size),
      ),
    ),
  );
}

// ── The official Improvy app icon (real PNG asset) ────────────────────────────

class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({required this.size});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/improvy_logo.png',
    width: size, height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}

// ── Drifting musical glyphs (very subtle, gold-tinted) ────────────────────────

class _FloatingSymbols extends StatelessWidget {
  final AnimationController controller;
  const _FloatingSymbols({required this.controller});

  // (x, y, size, phase, gold?)
  static const _items = [
    (0.14, 0.20, 58.0, 0.0, true),
    (0.84, 0.26, 66.0, 1.4, false),
    (0.20, 0.66, 80.0, 2.6, false),
    (0.80, 0.72, 50.0, 3.6, true),
  ];
  static const _glyphs = ['♪', '♫', '𝄞', '♩'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) => Stack(children: [
          for (int i = 0; i < _items.length; i++)
            Positioned(
              left: _items[i].$1 * size.width,
              top: _items[i].$2 * size.height + math.sin(controller.value * 2 * math.pi + _items[i].$4) * 14,
              child: Transform.rotate(
                angle: math.sin(controller.value * 2 * math.pi + _items[i].$4) * 0.12,
                child: Text(_glyphs[i], style: TextStyle(
                  fontSize: _items[i].$3,
                  color: (_items[i].$5 ? const Color(0xFFFBBF24) : Colors.white).withValues(alpha: 0.05),
                )),
              ),
            ),
        ]),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.55), size: 22),
    ),
  );
}

// (icon, title, description)
const _features = [
  (Icons.piano_rounded,        'Chromatic Mode',      'Master all 12 chromatic keys'),
  (Icons.swap_horiz_rounded,   'Note to Number',      'Identify degrees from notes instantly'),
  (Icons.psychology_rounded,   'Adaptive Difficulty', 'Training that adapts to your level'),
  (Icons.analytics_rounded,    'Deep Analytics',      'Track every key and every degree'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFBBF24).withValues(alpha: 0.13),
          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: const Color(0xFFFBBF24), size: 26),
      ),
      const SizedBox(width: 15),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
          const SizedBox(height: 4),
          Text(desc,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.5), height: 1.2)),
        ],
      )),
    ]),
  );
}

class _BuyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _BuyButton({required this.label, required this.onTap});

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
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: AnimatedBuilder(
        animation: _shim,
        builder: (ctx, _) => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFEA580C)],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            boxShadow: const [BoxShadow(color: Color(0x59F59E0B), blurRadius: 38, offset: Offset(0, 16))],
          ),
          child: Stack(children: [
            // Sweeping shimmer
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    begin: Alignment(-3 + _shim.value * 6, 0),
                    end: Alignment(-2 + _shim.value * 6, 0),
                    colors: [Colors.transparent, Colors.white.withValues(alpha: 0.28), Colors.transparent],
                  ).createShader(b),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 19),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(widget.label,
                        maxLines: 1, softWrap: false,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, letterSpacing: 0.3, color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}
