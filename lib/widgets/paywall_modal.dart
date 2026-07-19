import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../screens/legal_screen.dart';
import '../services/purchase_service.dart';

/// Full-screen "Improvy Pro" paywall — cinematic dark, membership-card feel.
///
/// One static screen (no scrolling; Spacers absorb device height). The visual
/// core is a glass "what's included" card with a gradient hairline border and
/// a top-edge sheen, under a hero logo with dual colored glows. One gold CTA
/// carries the price. Design language: hairlines at 8% white, radius 16–22,
/// a single accent (gold), quiet ambient glows, nothing animated after entry.
class PaywallModal extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onPurchase;

  const PaywallModal({super.key, required this.onClose, required this.onPurchase});

  @override
  State<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends State<PaywallModal> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _border;  // slow rainbow sweep on the card
  late final AnimationController _breathe; // ambient drift + logo halo pulse

  bool _purchasing = false;
  bool _restoring = false;

  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFCD34D);
  static const _goldDeep = Color(0xFFF59E0B);
  static const _fallbackPrice = '€16,99';
  String? _livePrice;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _border = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _breathe = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    // Live, store-localized price. Falls back to the static price until
    // (or unless) RevenueCat returns the real product.
    PurchaseService.instance.proPriceString().then((p) {
      if (mounted && p != null) setState(() => _livePrice = p);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _border.dispose();
    _breathe.dispose();
    super.dispose();
  }

  // Fade + slide-up over an interval of the entrance controller (stagger).
  Widget _in(double start, double end, {double dy = 16, required Widget child}) {
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

  Future<void> _buy() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    await widget.onPurchase();
    if (mounted) setState(() => _purchasing = false);
  }

  Future<void> _restore() async {
    if (_restoring) return;
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

  static const _features = <String>[
    'Chromatic Mode',
    'Note to Number',
    'Custom Mode',
    '…Of What? Extensions',
    'Adaptive Difficulty',
    'Deep Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    final reveal = CurvedAnimation(parent: _enter, curve: const Interval(0.0, 0.3));
    return AnimatedBuilder(
      animation: reveal,
      builder: (_, child) => Opacity(opacity: reveal.value.clamp(0.0, 1.0), child: child),
      child: Material(
        color: AppColors.background,
        child: Stack(children: [
          // ── Cinematic base: vertical gradient + two still ambient glows ────
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [0.0, 0.45, 1.0],
              colors: [Color(0xFF1D1434), Color(0xFF110C1E), Color(0xFF0C0814)],
            ),
          ))),
          // Ambient glows breathe and drift very slowly — alive, not busy.
          AnimatedBuilder(
            animation: _breathe,
            builder: (_, __) {
              final t = Curves.easeInOut.transform(_breathe.value);
              return Stack(children: [
                Positioned(
                  top: -140 + 14 * t, right: -80 - 10 * t,
                  child: IgnorePointer(child: Container(
                    width: 380, height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_goldDeep.withValues(alpha: 0.09 + 0.05 * t), Colors.transparent],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  )),
                ),
                Positioned(
                  bottom: -160 + 12 * (1 - t), left: -110 - 8 * (1 - t),
                  child: IgnorePointer(child: Container(
                    width: 420, height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [const Color(0xFF7C3AED).withValues(alpha: 0.08 + 0.05 * (1 - t)), Colors.transparent],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  )),
                ),
              ]);
            },
          ),

          SafeArea(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  const Spacer(flex: 3),

                  _in(0.0, 0.45, child: _hero()),

                  const Spacer(flex: 3),

                  _in(0.14, 0.62, child: _membershipCard()),

                  const Spacer(flex: 3),

                  _in(0.32, 0.85, child: _BuyButton(
                    title: 'Unlock Lifetime Access',
                    subtitle: '${_livePrice ?? _fallbackPrice} · one-time payment',
                    busy: _purchasing,
                    onTap: _buy,
                  )),
                  const SizedBox(height: 14),
                  _in(0.42, 0.95, child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _miniLink(_restoring ? 'Restoring…' : 'Restore Purchase', _restoring ? null : _restore),
                      _dot(),
                      _miniLink('Terms', () => _openLegal('Terms of Service', kTermsBody)),
                      _dot(),
                      _miniLink('Privacy', () => _openLegal('Privacy Policy', kPrivacyPolicyBody)),
                    ]),
                  )),

                  const SizedBox(height: 10),
                ]),
              ),
              Positioned(top: 6, right: 16, child: _CloseButton(onTap: widget.onClose)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Hero: logo with dual colored glow, wordmark, promise ───────────────────

  Widget _hero() => Column(children: [
    Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Breathing halo behind the logo — painted out of layout.
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _breathe,
                builder: (_, __) {
                  final t = Curves.easeInOut.transform(_breathe.value);
                  return Container(
                    width: 235 + 26 * t, height: 235 + 26 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color.lerp(const Color(0xFF7C3AED), _goldDeep, t)!
                              .withValues(alpha: 0.10 + 0.07 * t),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Container(
          width: 124, height: 124,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.48),
                blurRadius: 44, offset: const Offset(-11, 16), spreadRadius: -6),
              BoxShadow(color: _goldDeep.withValues(alpha: 0.38),
                blurRadius: 44, offset: const Offset(11, 18), spreadRadius: -8),
            ],
          ),
          // The asset is the app icon: piano keys inside a black rounded
          // square whose frame eats ~25% of the tile. Scale it up inside the
          // clipped box so the keys fill the tile and only a slim frame stays.
          child: Transform.scale(
            scale: 1.25,
            child: Image.asset('assets/images/improvy_logo.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
          ),
        ),
      ],
    ),
    const SizedBox(height: 14),
    Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text('Improvy',
          maxLines: 1, softWrap: false,
          style: TextStyle(fontSize: 37, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.1, height: 1)),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [_goldSoft, _goldDeep]).createShader(b),
          child: const Text(' Pro',
            maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 37, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.1, height: 1)),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Text('Every key. Every mode. Forever.',
      textAlign: TextAlign.center,
      maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4,
        color: Colors.white.withValues(alpha: 0.58))),
  ]);

  // ── Glass membership card: gradient hairline border + sheen + check rows ───

  Widget _membershipCard() {
    return AnimatedBuilder(
      animation: _border,
      builder: (_, child) => Container(
        // Animated rainbow hairline — the same slow 8s sweep as the home
        // progress card, so the paywall shares the app's "magic" signature.
        padding: const EdgeInsets.all(1.4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: SweepGradient(
            transform: GradientRotation(_border.value * 2 * math.pi),
            colors: const [
              Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
              Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFA855F7),
              Color(0xFFEC4899), Color(0xFFEF4444),
            ],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14)),
            BoxShadow(color: _goldDeep.withValues(alpha: 0.07), blurRadius: 44, offset: const Offset(0, 6)),
          ],
        ),
        child: child,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        // Opaque base so the border gradient stays a hairline and cannot
        // bleed through the glass fill.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          color: const Color(0xFF181022),
        ),
        // Glass sheen: lighter at the top edge.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.07),
              Colors.white.withValues(alpha: 0.015),
              Colors.white.withValues(alpha: 0.03),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 21, 24, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header: label + LIFETIME tag
            Row(children: [
              Text('WHAT\'S INCLUDED',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7,
                  color: Colors.white.withValues(alpha: 0.42))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _gold.withValues(alpha: 0.12),
                  border: Border.all(color: _gold.withValues(alpha: 0.30)),
                ),
                child: const Text('LIFETIME',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4,
                    color: _goldSoft)),
              ),
            ]),
            const SizedBox(height: 8),
            for (int i = 0; i < _features.length; i++) ...[
              if (i > 0) Container(height: 1, color: Colors.white.withValues(alpha: 0.055)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(children: [
                  Container(
                    width: 25, height: 25,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [_goldSoft, _goldDeep],
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, size: 17, color: Color(0xFF2A1B04)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: Text(_features[i],
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2,
                      letterSpacing: 0.1, color: Colors.white.withValues(alpha: 0.93)))),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _miniLink(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: onTap == null ? 0.3 : 0.45))),
    ),
  );

  Widget _dot() => Text('   ·   ',
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.2)));
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.65), size: 20),
    ),
  );
}

// ── CTA: gold, top-edge highlight, dark accessible ink, price inside ─────────

class _BuyButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;
  const _BuyButton({required this.title, required this.subtitle, required this.busy, required this.onTap});

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shim;

  static const _ink = Color(0xFF2A1B04); // near-black brown on gold: 10:1+ contrast

  @override
  void initState() {
    super.initState();
    // One light sweep, then a pause — the sweep lives in the first 35% of
    // each 4.5s cycle.
    _shim = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();
  }

  @override
  void dispose() {
    _shim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.busy ? null : (_) => setState(() => _pressed = true),
    onTapUp: widget.busy ? null : (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: Container(
        width: double.infinity,
        height: 68,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFFDDB6E), Color(0xFFFBBF24), Color(0xFFF59E0B)],
            stops: [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: widget.busy ? 0.18 : 0.38),
              blurRadius: 30, offset: const Offset(0, 12), spreadRadius: -4),
          ],
        ),
        child: Stack(children: [
          // Top-edge highlight — the "pressed metal" sheen.
          Positioned(
            top: 0, left: 14, right: 14,
            child: Container(height: 1.4, color: Colors.white.withValues(alpha: 0.55)),
          ),
          // Light blade sweeping across the gold — then resting.
          if (!widget.busy)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shim,
                  builder: (_, __) {
                    final p = Curves.easeInOut.transform((_shim.value / 0.35).clamp(0.0, 1.0));
                    if (p >= 1) return const SizedBox.shrink();
                    return ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        begin: Alignment(-2.8 + p * 5.6, -0.4),
                        end: Alignment(-2.0 + p * 5.6, 0.4),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.32),
                          Colors.transparent,
                        ],
                      ).createShader(b),
                      child: Container(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.busy
                ? const SizedBox(
                    key: ValueKey('spinner'),
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6, color: _ink))
                : Column(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.title,
                        maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800,
                          letterSpacing: 0.1, color: _ink, height: 1.1)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                        maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: _ink.withValues(alpha: 0.72), height: 1.1)),
                    ],
                  ),
            ),
          ),
        ]),
      ),
    ),
  );
}
