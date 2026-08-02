import 'package:flutter/material.dart';

import '../screens/legal_screen.dart';
import '../services/purchase_service.dart';

/// Full-screen "Improvy Pro" paywall.
///
/// Six aurora glows bleed in from the edges; over them the page runs in three
/// zones. The pitch (brand, headline, promise) and the action (CTA, legal
/// links) each take the height they need at the top and the bottom, and the
/// feature list takes everything left between them, dividing that space among
/// its own rows. Nothing is positioned by a spacer weight tuned by eye, so the
/// page has no dead bands to tidy up and never needs to scroll: on a short
/// viewport the whole rhythm compresses by [_k] instead.
class PaywallModal extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onPurchase;

  const PaywallModal({super.key, required this.onClose, required this.onPurchase});

  @override
  State<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends State<PaywallModal> with TickerProviderStateMixin {
  late final AnimationController _enter;

  bool _purchasing = false;
  bool _restoring = false;
  bool _closing = false;
  double _k = 1.0;
  double _hero = 1.0;

  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFCD34D);
  static const _ink = Color(0xFF2A1B04); // dark brown on gold — high contrast
  static const _fallbackPrice = '€19,99';
  String? _livePrice;

  // label · trailing meta · icon · chip colour · icon ink
  //
  // Ordered by hue, so the list reads down the spectrum — amber, green, cyan,
  // purple, fuchsia, pink. Each mode keeps the colour it wears everywhere else
  // in the app, so the row still points at the thing it unlocks.
  static const _features = <(String, String, IconData, Color, Color)>[
    ('Adaptive difficulty', 'auto', Icons.trending_up_rounded, Color(0xFFF59E0B), Color(0xFF2A1B04)),
    ('Note to Number', 'reverse', Icons.tag_rounded, Color(0xFF34D399), Color(0xFF04301F)),
    ('…Of What? extensions', '9 11 13', Icons.auto_awesome_rounded, Color(0xFF22D3EE), Color(0xFF04262B)),
    ('Chromatic Mode', '12 notes', Icons.piano_rounded, Color(0xFFA855F7), Color(0xFF1E0736)),
    ('Custom Mode', 'any degree', Icons.tune_rounded, Color(0xFFD857EC), Color(0xFF2E0733)),
    ('Deep analytics', 'per key', Icons.insights_rounded, Color(0xFFF472B6), Color(0xFF3B0A24)),
  ];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    // Live, store-localized price; falls back to the static one until (or
    // unless) RevenueCat returns the real product.
    PurchaseService.instance.proPriceString().then((p) {
      if (mounted && p != null) setState(() => _livePrice = p);
    });
  }

  @override
  void dispose() {
    _enter.dispose();
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

  /// Rewinds the entrance animation, so leaving reads as the reverse of
  /// arriving instead of snapping away.
  Future<void> _dismiss() async {
    if (_closing) return;
    setState(() => _closing = true);
    await _enter.animateBack(0.0,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    if (mounted) widget.onClose();
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
      _dismiss();
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
    return AnimatedBuilder(
      animation: _enter,
      builder: (_, child) {
        // Arriving, the backdrop snaps in over the first 30% so the staggered
        // content lands on a solid screen. Leaving, the fade spreads over the
        // whole rewind. The slight rise and swell make it read as a panel
        // coming up to meet you rather than a screen being switched.
        final t = _enter.value;
        final v = (_closing ? t : t / 0.3).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(v);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 26),
            child: Transform.scale(scale: 0.955 + 0.045 * eased, child: child),
          ),
        );
      },
      child: Material(
        color: const Color(0xFF150C22),
        child: Stack(children: [
          const Positioned.fill(child: _Aurora()),
          // Calms the aurora so white text stays readable over it.
          const Positioned.fill(
            child: IgnorePointer(child: ColoredBox(color: Color(0x590C0616))),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                // Three zones, not a stack of guessed gaps: the pitch at the
                // top and the action at the bottom take the height they need,
                // and the list between them takes everything that is left,
                // spreading its own rows through it. Nothing on the page is
                // sized by a spacer whose weight had to be tuned by eye.
                _k = (c.maxHeight / 880).clamp(0.55, 1.0);
                // The hero — the logo and the air above it — gives way faster
                // than the rest when height is short. A phone with room keeps
                // it at full size (hero == 1 at k == 1); a 568pt one spends
                // that height on the list and the button instead.
                _hero = _k * (0.38 + 0.62 * _k);
                final k = _k;
                return Padding(
                  padding: EdgeInsets.fromLTRB(26, 30 * _hero, 26, 14 * k),
                  child: Column(children: [
                    _in(0.0, 0.45, child: _brandRow()),
                    SizedBox(height: 20 * k),
                    _in(0.10, 0.55, child: _headline()),
                    SizedBox(height: 14 * k),
                    // The body. Its rows share this zone evenly, so the page
                    // never shows a dead band and never has to be scrolled.
                    Expanded(child: _in(0.26, 0.78, child: _featureList())),
                    SizedBox(height: 16 * k),
                    // The price belongs on the button you press to pay it —
                    // that is what freed the middle of the screen for the list.
                    _in(0.40, 0.90, child: _BuyButton(
                      label: 'Unlock lifetime access',
                      price: '${_livePrice ?? _fallbackPrice} · one-time payment',
                      busy: _purchasing,
                      height: (74 * k).clamp(62.0, 74.0),
                      onTap: _buy,
                    )),
                    SizedBox(height: 12 * k),
                    _in(0.48, 0.96, child: _footerLinks()),
                  ]),
                );
              },
            ),
          ),
          // Close sits above everything, clear of the rainbow strip.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 22,
            child: _CloseButton(onTap: _dismiss),
          ),
        ]),
      ),
    );
  }

  // ── Brand row: app icon + "Improvy Pro" + licence line ─────────────────────

  // Centred and large: on a page asking you to pay, the mark is the first thing
  // you should see, not a header pinned to a corner.
  Widget _brandRow() => Column(children: [
    Container(
      width: 116 * _hero, height: 116 * _hero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32 * _hero),
        color: Colors.black.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 34, offset: const Offset(0, 14), spreadRadius: -8),
        ],
      ),
      child: Image.asset('assets/images/improvy_logo.png',
          fit: BoxFit.cover, filterQuality: FilterQuality.high),
    ),
    SizedBox(height: 14 * _k),
    // Scales down (never up) so the wordmark can't overflow on a narrow phone.
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Improvy ',
          maxLines: 1, softWrap: false,
          style: TextStyle(fontSize: 39 * _k, fontWeight: FontWeight.w600,
            letterSpacing: -0.9, height: 1, color: Colors.white)),
        Text('Pro',
          maxLines: 1, softWrap: false,
          style: TextStyle(fontSize: 39 * _k, fontWeight: FontWeight.w600,
            letterSpacing: -0.9, height: 1, color: _gold)),
      ]),
    ),
    SizedBox(height: 6 * _k),
    Text('Lifetime licence',
      maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14.5 * _k, fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: Colors.white.withValues(alpha: 0.55))),
  ]);

  // ── Headline: "Every key. Every mode. / Forever." ──────────────────────────

  Widget _headline() {
    // One phrase per line, each scaled to the full width: the promise is the
    // loudest thing on the page, and three stacked lines carry it further than
    // one long one squeezed to fit.
    final style = TextStyle(fontSize: 46 * _k, fontWeight: FontWeight.w600,
        height: 1.06, letterSpacing: -1.6, color: Colors.white);
    Widget line(List<InlineSpan> spans) => SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text.rich(TextSpan(style: style, children: spans),
            maxLines: 1, softWrap: false),
      ),
    );
    return Column(children: [
      line([
        const TextSpan(text: 'Every '),
        const TextSpan(text: 'key', style: TextStyle(color: Color(0xFF22D3EE))),
        const TextSpan(text: '.'),
      ]),
      line([
        const TextSpan(text: 'Every '),
        const TextSpan(text: 'mode', style: TextStyle(color: Color(0xFFF472B6))),
        const TextSpan(text: '.'),
      ]),
      line([TextSpan(text: 'Forever.', style: TextStyle(color: _gold))]),
      SizedBox(height: 14 * _k),
      Text('One payment. Nothing to renew, nothing to cancel.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15.5 * _k, fontWeight: FontWeight.w300, height: 1.4,
          color: Colors.white.withValues(alpha: 0.60))),
    ]);
  }

  // ── Feature list: one quiet row per unlocked capability ────────────────────
  //
  // The rows used to carry a tinted gradient each, which — over an aurora, next
  // to a spectrum-ringed price and a gold CTA — was the noisiest thing on the
  // screen. The colour now lives only in the small icon tile, and the rows are
  // separated by hairlines instead of blocks of tint.

  Widget _featureList() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('What you unlock',
        style: TextStyle(fontSize: 12.5 * _k, fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: Colors.white.withValues(alpha: 0.42))),
      SizedBox(height: 14 * _k),
      // The rows divide what is actually left under the label — measured, not
      // estimated, so the list can never be a pixel taller than its zone.
      // Capped so a tall phone spaces them generously rather than absurdly.
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final rowH = (c.maxHeight / _features.length).clamp(24.0, 80.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final f in _features)
                SizedBox(
                  height: rowH,
                  child: Row(children: [
                Container(
                  width: 38 * _k, height: 38 * _k,
                  decoration: BoxDecoration(
                    color: f.$4.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.$3, size: 21 * _k, color: f.$4),
                ),
                SizedBox(width: 14 * _k),
                Expanded(
                  child: Text(f.$1,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17.5 * _k, fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.94))),
                ),
                const SizedBox(width: 8),
                Text(f.$2,
                  maxLines: 1, softWrap: false,
                  style: TextStyle(fontSize: 13.5 * _k, fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.45))),
                  ]),
                ),
            ],
          );
        }),
      ),
    ],
  );

  // ── Footer: restore / terms / privacy ──────────────────────────────────────

  Widget _footerLinks() => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _miniLink(_restoring ? 'Restoring…' : 'Restore', _restoring ? null : _restore),
      _dot(),
      _miniLink('Terms', () => _openLegal('Terms of Service', kTermsBody)),
      _dot(),
      _miniLink('Privacy', () => _openLegal('Privacy Policy', kPrivacyPolicyBody)),
    ]),
  );

  Widget _miniLink(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: onTap == null ? 0.28 : 0.40))),
    ),
  );

  Widget _dot() => Text('  ·  ',
    style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.25)));
}

/// Scales a single line down (never up) so a long headline can't wrap or clip.
class _FitLine extends StatelessWidget {
  final Widget child;
  const _FitLine({required this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
  );
}

// ── Aurora: six colour washes bleeding in from the edges ──────────────────────

class _Aurora extends StatelessWidget {
  const _Aurora();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: Stack(children: const [
        _Glow(top: -100, left: -100, size: 450, color: Color(0xFFEF4444), alpha: 0.55),
        _Glow(top: -50, right: -150, size: 450, color: Color(0xFFF97316), alpha: 0.55),
        _Glow(top: 200, left: -150, size: 450, color: Color(0xFFEAB308), alpha: 0.45),
        _Glow(top: 300, right: -150, size: 450, color: Color(0xFF22C55E), alpha: 0.45),
        _Glow(bottom: -100, left: -100, size: 450, color: Color(0xFF3B82F6), alpha: 0.55),
        _Glow(bottom: -150, right: -100, size: 450, color: Color(0xFFA855F7), alpha: 0.55),
      ]),
    ),
  );
}

class _Glow extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size, alpha;
  final Color color;
  const _Glow({this.top, this.bottom, this.left, this.right,
    required this.size, required this.color, required this.alpha});

  @override
  Widget build(BuildContext context) => Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          stops: const [0.0, 0.68],
        ),
      ),
    ),
  );
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
        color: Colors.white.withValues(alpha: 0.10),
      ),
      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.75), size: 19),
    ),
  );
}

// ── CTA: champagne→amber gold bar with a slow light sweep ─────────────────────

class _BuyButton extends StatefulWidget {
  final String label;
  /// Sits under the label, inside the button: what you are about to pay, on
  /// the thing you press to pay it.
  final String price;
  final bool busy;
  final double height;
  final VoidCallback onTap;
  const _BuyButton({required this.label, required this.price, required this.busy, required this.height, required this.onTap});

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shim;

  static const _ink = Color(0xFF2A1B04);

  @override
  void initState() {
    super.initState();
    // One light sweep in the first 35% of each 4.5s cycle, then a pause.
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
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFCE7A6), Color(0xFFF7C955), Color(0xFFE8A22B)],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: widget.busy ? 0.25 : 0.60),
              blurRadius: 32, offset: const Offset(0, 14), spreadRadius: -12),
          ],
        ),
        child: Stack(children: [
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
                      Text(widget.label,
                          maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w600,
                              color: _ink, height: 1.1)),
                      const SizedBox(height: 3),
                      Text(widget.price,
                          maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                              color: _ink.withValues(alpha: 0.66), height: 1.1)),
                    ],
                  ),
            ),
          ),
        ]),
      ),
    ),
  );
}
