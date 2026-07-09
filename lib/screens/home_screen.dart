import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/training_mode.dart';
import '../models/key_progress.dart';
import '../constants/app_colors.dart';
import '../constants/levels.dart';
import '../services/haptics_service.dart';
import '../widgets/note_text.dart';
import '../widgets/animal_icon.dart';

class HomeScreen extends StatelessWidget {
  final void Function([String? reason]) onShowPaywall;
  final void Function(TrainingMode mode) onOpenSetup;

  const HomeScreen({super.key, required this.onShowPaywall, required this.onOpenSetup});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) {
          final isDetail = child.key == const ValueKey('detail');
          final slideAnim = Tween<Offset>(
            begin: isDetail ? const Offset(1, 0) : const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slideAnim, child: FadeTransition(opacity: anim, child: child));
        },
        child: provider.selectedKey == null
            ? _HomeMain(key: const ValueKey('main'), onShowPaywall: onShowPaywall, onOpenSetup: onOpenSetup)
            : _KeyDetail(key: const ValueKey('detail'), onShowPaywall: onShowPaywall, onOpenSetup: onOpenSetup),
      ),
    );
  }
}

// ─── MAIN HOME ────────────────────────────────────────────────────────────────

class _HomeMain extends StatelessWidget {
  final void Function([String? reason]) onShowPaywall;
  final void Function(TrainingMode mode) onOpenSetup;
  const _HomeMain({super.key, required this.onShowPaywall, required this.onOpenSetup});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final animalLevel = provider.animalLevel;
    final totalProgress = provider.totalProgress;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 140 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMPROVY logo ──
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 28),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        alignment: Alignment.center,
                        child: const RepaintBoundary(child: _LogoGlow()),
                      ),
                    ),
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF22D3EE), Color(0xFF944DFF), Color(0xFFEF4444)],
                          ).createShader(bounds),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Text(
                              'IMPROVY',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 56,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.12,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: 0.5,
                          child: Container(
                            width: 260, height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Color(0x33FFFFFF), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Progress card ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: RepaintBoundary(child: _ProgressCard(animalLevel: animalLevel, totalProgress: totalProgress)),
            ),

            // ── All Keys Mastery ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: _SectionHeader('ALL KEYS MASTERY'),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(child: _KeyGrid(progressData: provider.progressData, onKeySelect: (key) {
              HapticsService.impactMedium();
              provider.selectKey(key);
            })),
            const SizedBox(height: 28),

            // ── Special Modes ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: _SectionHeader('SPECIAL MODES'),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                _BigSpecialCard(
                  title: 'Note to Number',
                  subtitle: 'Given a note name, identify its numerical degree.',
                  icon: Icons.swap_horiz_rounded,
                  accentColor: const Color(0xFF34D399),
                  borderColor: const Color(0xFF34D399).withAlpha(110),
                  isLocked: !provider.isPro,
                  onTap: () {
                    if (!provider.isPro) { onShowPaywall(); return; }
                    if (provider.selectedKey == null) provider.selectKey(provider.progressData.first.key);
                    onOpenSetup(TrainingMode.noteToNumber);
                  },
                ),
                const SizedBox(height: 12),
                _BigSpecialCard(
                  title: 'Custom Mode',
                  subtitle: 'Choose your key, direction, and specific degrees to train on.',
                  icon: Icons.tune_rounded,
                  accentColor: const Color(0xFFD857EC),
                  borderColor: const Color(0xFFD857EC).withAlpha(110),
                  isLocked: !provider.isPro,
                  onTap: () {
                    if (!provider.isPro) { onShowPaywall(); return; }
                    if (provider.selectedKey == null) provider.selectKey(provider.progressData.first.key);
                    onOpenSetup(TrainingMode.custom);
                  },
                ),
              ]),
            )),
            const SizedBox(height: 28),

            // ── Pick Up Where You Left Off ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
              child: _SectionHeader('PICK UP WHERE YOU LEFT OFF'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _LastSessionCard(
                lastSession: provider.lastSession,
                onResume: () {
                  final ls = provider.lastSession;
                  if (ls == null) return;
                  final key = ls['key'] as String;
                  final mode = ls['mode'] as String;
                  final diff = ls['difficulty'] as int;
                  provider.selectKey(key);
                  final tm = mode == 'diatonic' ? TrainingMode.diatonic : TrainingMode.chromatic;
                  if (tm == TrainingMode.diatonic) provider.setDiatonicDifficulty(diff);
                  else provider.setChromaticDifficulty(diff);
                  provider.startMode(tm);
                },
              ),
            ),
            const SizedBox(height: 28),

            // ── Mini stats: Total Sessions + Accuracy ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(child: _MiniStatCard(
                  label: 'TOTAL SESSIONS',
                  value: '${provider.stats.totalSessions}',
                  accentColor: const Color(0xFFEAB308),
                  icon: Icons.bolt_rounded,
                  isAccuracy: false,
                )),
                const SizedBox(width: 12),
                Expanded(child: _MiniStatCard(
                  label: 'ACCURACY',
                  value: '${provider.overallAccuracy}',
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.adjust,
                  isAccuracy: true,
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0x99FFFFFF), letterSpacing: 2.2)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Container(
        height: 1,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x1AFFFFFF), Colors.transparent])),
      )),
    ]);
  }
}

// ─── LOGO GLOW ───────────────────────────────────────────────────────────────
// Two layered halos behind IMPROVY, mirroring the web header:
//  L1: -inset-6, blur 35px, cyan-500/40 → purple-600/40 → red-600/40, 4s pulse
//  L2: -inset-10, blur 50px, indigo-500/30 → transparent → rose-600/30, 6s breath (1s delay)

class _LogoGlow extends StatefulWidget {
  const _LogoGlow();

  @override
  State<_LogoGlow> createState() => _LogoGlowState();
}

class _LogoGlowState extends State<_LogoGlow> with TickerProviderStateMixin {
  late final AnimationController _inner; // 2s half-cycle → 4s full pulse
  late final AnimationController _outer; // 3s half-cycle → 6s full breath

  @override
  void initState() {
    super.initState();
    _inner = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _outer = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _outer.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _inner.dispose();
    _outer.dispose();
    super.dispose();
  }

  Widget _halo({
    required AnimationController ctrl,
    required double width,
    required double height,
    required double sigma,
    required Gradient gradient,
    required double minScale,
    required double maxScale,
    required double minOpacity,
    required double maxOpacity,
  }) {
    final pad = sigma * 2;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(ctrl.value);
        return Opacity(
          opacity: minOpacity + (maxOpacity - minOpacity) * t,
          child: Transform.scale(
            scale: minScale + (maxScale - minScale) * t,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: width + pad * 2,
        height: height + pad * 2,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
          child: Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: gradient,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IMPROVY text box ≈ 250×56 (Outfit 56 w600)
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // L2 — deep ambient aura: text + 40px on every side
        _halo(
          ctrl: _outer,
          width: 330, height: 136, sigma: 38,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x4D6366F1), Colors.transparent, Color(0x4DE11D48)],
          ),
          minScale: 0.8, maxScale: 1.2,
          minOpacity: 0.18, maxOpacity: 0.30,
        ),
        // L1 — inner pulsing glow: text + 24px on every side
        _halo(
          ctrl: _inner,
          width: 298, height: 104, sigma: 26,
          gradient: const LinearGradient(
            colors: [Color(0x6606B6D4), Color(0x669333EA), Color(0x66DC2626)],
          ),
          minScale: 1.0, maxScale: 1.1,
          minOpacity: 0.32, maxOpacity: 0.52,
        ),
      ],
    );
  }
}

// ─── PROGRESS CARD ───────────────────────────────────────────────────────────

class _ProgressCard extends StatefulWidget {
  final AnimalLevel animalLevel;
  final double totalProgress;
  const _ProgressCard({required this.animalLevel, required this.totalProgress});

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> with SingleTickerProviderStateMixin {
  late final AnimationController _borderCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  String _nextMilestone() {
    const thresholds = [12.5, 25.0, 37.5, 50.0, 62.5, 75.0, 87.5, 100.0];
    const names = ['Turtle', 'Rabbit', 'Dog', 'Horse', 'Eagle', 'Dolphin', 'Cheetah', 'Max'];
    for (int i = 0; i < thresholds.length; i++) {
      if (widget.totalProgress < thresholds[i]) {
        final rem = (thresholds[i] - widget.totalProgress).toStringAsFixed(1);
        return '${rem}% to ${names[i]}';
      }
    }
    return 'MAX LEVEL!';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.animalLevel;
    final p = widget.totalProgress;

    // Rainbow ring: conic-gradient(red→orange→yellow→green→blue→purple→pink→red)
    // spinning 360° every 8s, masked to a 2px border by the inner card.
    return AnimatedBuilder(
      animation: _borderCtrl,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: SweepGradient(
            transform: GradientRotation(_borderCtrl.value * 2 * math.pi),
            colors: const [
              Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
              Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFA855F7),
              Color(0xFFEC4899), Color(0xFFEF4444),
            ],
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.6), blurRadius: 60, offset: const Offset(0, 20))],
        ),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF21A1625),
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient overlay 135deg — covers the full card surface
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x0D06B6D4), Color(0x0DA855F7), Color(0x0DEC4899)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('TOTAL PROGRESS',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0x80FFFFFF), letterSpacing: 2)),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) => const LinearGradient(
                                    colors: [Color(0xFF22D3EE), Color(0xFF818CF8), Color(0xFFF472B6)],
                                  ).createShader(b),
                                  child: Text(
                                    '${p.round()}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2.4, color: Colors.white, height: 1),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('%',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0x4DFFFFFF))),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withAlpha(13)),
                              ),
                              child: Center(child: AnimalIcon(name: a.name, color: a.color, size: 40)),
                            ),
                            Positioned(
                              top: -10, right: -10,
                              child: Transform.rotate(
                                angle: 0.21,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: a.color,
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(color: const Color(0xFF1A1625), width: 2),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('LVL ${a.level}',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1A1625))),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(a.name.toUpperCase(),
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: a.color, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('NEXT MILESTONE',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0x33FFFFFF), letterSpacing: 1.8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(_nextMilestone(),
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0x80FFFFFF), letterSpacing: 0.9)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.white.withAlpha(13), width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    // Rainbow anchored to the FULL track; the fill is a window
                    // that reveals more of it (more colours) as progress grows —
                    // the colours stay fixed in place, they do not stretch.
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final fullW = c.maxWidth;
                        // The fill eases from 0 to its value on first build (and
                        // between values), so the card feels alive on open.
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (p / 100).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (ctx, frac, _) => Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: fullW * frac,
                              height: 12,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  minWidth: fullW,
                                  maxWidth: fullW,
                                  minHeight: 12,
                                  maxHeight: 12,
                                  child: Container(
                                    width: fullW,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
                                        Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFA855F7),
                                        Color(0xFFEC4899),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Text('“${a.quote}”',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Color(0x80FFFFFF))),
                ),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HORIZONTAL KEY GRID (2 pages) ───────────────────────────────────────────

class _KeyGrid extends StatefulWidget {
  final List<KeyProgress> progressData;
  final void Function(String) onKeySelect;
  const _KeyGrid({required this.progressData, required this.onKeySelect});

  @override
  State<_KeyGrid> createState() => _KeyGridState();
}

class _KeyGridState extends State<_KeyGrid> with SingleTickerProviderStateMixin {
  int _page = 0;
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.progressData;
    final pages = <List<KeyProgress>>[];
    for (int i = 0; i < all.length; i += 6) {
      pages.add(all.sublist(i, (i + 6).clamp(0, all.length)));
    }

    // Grid height must follow the cell aspect ratio at the actual screen
    // width, or the bottom row gets clipped.
    final gridW = MediaQuery.of(context).size.width - 48;
    final cellH = ((gridW - 20) / 3) * (110 / 106);
    final gridH = cellH * 2 + 10;

    return Column(children: [
      SizedBox(
        height: gridH,
        child: PageView.builder(
          padEnds: false,
          onPageChanged: (p) => setState(() => _page = p),
          itemCount: pages.length,
          itemBuilder: (context, pi) {
            final keys = pages[pi];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 106 / 110,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: keys.length,
                itemBuilder: (context, i) {
                  final kd = keys[i];
                  final globalIdx = pi * 6 + i;
                  final color = AppColors.keyColor(globalIdx);
                  // Staggered fade + slide-up entrance.
                  final anim = CurvedAnimation(parent: _stagger,
                    curve: Interval((i * 0.09).clamp(0.0, 0.5), (i * 0.09 + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
                  return AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Opacity(
                      opacity: anim.value.clamp(0.0, 1.0),
                      child: Transform.translate(offset: Offset(0, (1 - anim.value) * 22), child: child),
                    ),
                    child: _KeyCard(keyData: kd, color: color, onTap: () => widget.onKeySelect(kd.key)),
                  );
                },
              ),
            );
          },
        ),
      ),
      if (pages.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _page == i ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _page == i ? Colors.white60 : Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    ]);
  }
}

// ─── KEY CARD ────────────────────────────────────────────────────────────────

class _KeyCard extends StatefulWidget {
  final KeyProgress keyData;
  final Color color;
  final VoidCallback onTap;
  const _KeyCard({required this.keyData, required this.color, required this.onTap});

  @override
  State<_KeyCard> createState() => _KeyCardState();
}

class _KeyCardState extends State<_KeyCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.keyData.totalProgress;
    final color = widget.color;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
        decoration: BoxDecoration(
          color: const Color(0xE62A2438),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha:0.145), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
                Positioned(
                  top: -32, right: -32,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15, tileMode: TileMode.decal),
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Toned down from 50% → ~31%: the cards read as less
                        // saturated / less "acceso".
                        color: color.withAlpha(80),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: NoteText(
                              note: formatNoteForDisplay(widget.keyData.key,
                                  context.select<AppProvider, String>((p) => p.notation)),
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: Colors.white, height: 1),
                            ),
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('${v.round()}%', maxLines: 1, softWrap: false, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                        ),
                      ),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(102),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: Colors.white.withAlpha(13), width: 1.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9999),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: (progress / 100).clamp(0.0, 1.0)),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, child) => FractionallySizedBox(widthFactor: v, child: child),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [BoxShadow(color: color.withAlpha(150), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

// ─── BIG SPECIAL MODE CARD ───────────────────────────────────────────────────

class _BigSpecialCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color borderColor;
  final bool isLocked;
  final VoidCallback onTap;

  const _BigSpecialCard({
    required this.title, required this.subtitle,
    required this.icon, required this.accentColor,
    required this.borderColor, required this.isLocked, required this.onTap,
  });

  @override
  State<_BigSpecialCard> createState() => _BigSpecialCardState();
}

class _BigSpecialCardState extends State<_BigSpecialCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final locked = widget.isLocked;
    final accent = widget.accentColor;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          // Locked: dimmed — clearly not available, but still readable
          // (0.5 was muddy, 0.7 read as unlocked; 0.6 is the sweet spot).
          opacity: locked ? 0.6 : 1.0,
          child: Container(
            height: 180, // web: h-[180px] — both special cards are identical size
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // Locked keeps a whisper of the accent on the border — the card
              // stays rich and inviting; the gold PRO chip signals the lock.
              border: Border.all(color: locked ? accent.withValues(alpha: 0.30) : widget.borderColor, width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(children: [
                // Subtle translucent surface. No BackdropFilter: the real-time
                // blur was invisible over the dark background but re-sampled
                // every frame, stuttering the scroll.
                Positioned.fill(
                  child: Container(color: Colors.white.withValues(alpha:0.055)),
                ),
                // Soft, blurred magical glow from the corners (not a hard dot).
                Positioned(
                  top: -55, right: -55,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34, tileMode: TileMode.decal),
                    child: Container(
                      width: 170, height: 170,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: locked ? 0.16 : 0.24)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -45, left: -45,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30, tileMode: TileMode.decal),
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: locked ? 0.07 : 0.12)),
                    ),
                  ),
                ),
                // Content — icon pinned top, title + subtitle pinned bottom.
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withAlpha(140)),
                          boxShadow: [BoxShadow(color: accent.withValues(alpha:0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(widget.title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: accent, letterSpacing: -0.6, height: 1)),
                              ),
                            ),
                            if (locked) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.lock_rounded, size: 10, color: Colors.white38),
                                  SizedBox(width: 3),
                                  Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1)),
                                ]),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 6),
                          Text(widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(140), height: 1.4)),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LAST SESSION CARD ────────────────────────────────────────────────────────

class _LastSessionCard extends StatelessWidget {
  final Map<String, dynamic>? lastSession;
  final VoidCallback onResume;
  const _LastSessionCard({required this.lastSession, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(children: [
          Positioned(
            top: -32, right: -32,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32, tileMode: TileMode.decal),
              child: Container(
                width: 128, height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E90FF).withAlpha(26),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: lastSession != null ? _WithSession(session: lastSession!, onResume: onResume) : const _EmptyState(),
          ),
        ]),
      ),
    );
  }
}

class _WithSession extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onResume;
  const _WithSession({required this.session, required this.onResume});

  String _quoteFor(int diff) {
    const quotes = [
      "Every master was once a beginner. Let's visualize those first notes!",
      'Halfway to mastery — your instincts are sharpening. Keep pushing!',
      'True mastery lives in the details. Trust your instincts and play!',
    ];
    return quotes[(diff - 1).clamp(0, quotes.length - 1)];
  }

  String _relativeTime(int ts) {
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    final secs = diff ~/ 1000;
    if (secs < 60) return 'Just now';
    final mins = secs ~/ 60;
    if (mins < 60) return '${mins}m ago';
    final hrs = mins ~/ 60;
    if (hrs < 24) return '${hrs}h ago';
    final days = hrs ~/ 24;
    return '${days}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final key = session['key'] as String? ?? '';
    final mode = session['mode'] as String? ?? '';
    final diff = session['difficulty'] as int? ?? 1;
    final ts = session['timestamp'] as int? ?? 0;
    final diffLabels = ['Apprentice', 'Virtuoso', 'Master'];
    final modeLabel = switch (mode) {
      'diatonic' => 'Diatonic',
      'chromatic' => 'Chromatic',
      'note-to-number' => 'Note to Number',
      'custom' => 'Custom',
      _ => mode.isEmpty ? '' : mode[0].toUpperCase() + mode.substring(1),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 6, height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF60A5FA))),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('LAST SESSION • ${_relativeTime(ts)}',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF60A5FA), letterSpacing: 1.5)),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: NoteText(
                    note: '${formatNoteForDisplay(key, context.select<AppProvider, String>((p) => p.notation))} $modeLabel',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(diff > 0 && diff <= 3 ? '${diffLabels[diff - 1]} Difficulty' : '',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(97))),
                ),
              ]),
            ),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: const Icon(Icons.history_rounded, color: Color(0xFF60A5FA), size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('“${_quoteFor(diff)}”',
          style: TextStyle(
            fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(102), height: 1.6,
          )),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onResume,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withAlpha(77), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Resume Session',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(13)),
            ),
            child: Icon(Icons.music_note_rounded, color: Colors.white.withAlpha(77), size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Ready to start?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.45, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Select a key from above',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(102))),
        ]),
      ),
    );
  }
}

// ─── MINI STAT CARD ──────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;
  final bool isAccuracy;
  const _MiniStatCard({required this.label, required this.value, required this.accentColor, required this.icon, required this.isAccuracy});

  @override
  Widget build(BuildContext context) {
    // Corner glow sphere: 64px circle at top -16 / right -16, accent 15%,
    // blur(40px), opacity 0.8 — clipped by the card like web's overflow-hidden.
    const glowSize = 64.0;
    const glowSigma = 30.0;
    const glowPad = glowSigma * 2;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1625),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          top: -16 - glowPad, right: -16 - glowPad,
          child: Opacity(
            opacity: 0.8,
            child: SizedBox(
              width: glowSize + glowPad * 2,
              height: glowSize + glowPad * 2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: glowSigma, sigmaY: glowSigma, tileMode: TileMode.decal),
                child: Center(
                  child: Container(
                    width: glowSize, height: glowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withAlpha(38),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0x80FFFFFF), letterSpacing: 1)),
                  Icon(icon, size: 18, color: accentColor.withAlpha(204)),
                ],
              ),
              const SizedBox(height: 12),
              if (isAccuracy)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                    Text('%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(77))),
                  ],
                )
              else
                Text(value,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── KEY DETAIL ───────────────────────────────────────────────────────────────

class _KeyDetail extends StatefulWidget {
  final void Function([String? reason]) onShowPaywall;
  final void Function(TrainingMode mode) onOpenSetup;
  const _KeyDetail({super.key, required this.onShowPaywall, required this.onOpenSetup});

  @override
  State<_KeyDetail> createState() => _KeyDetailState();
}

class _KeyDetailState extends State<_KeyDetail> with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  String? _lastKey; // keeps rendering during the exit animation after deselect

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.55).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // During the exit animation (right after deselectKey) selectedKey is null
    // while this screen is still fading out — fall back to the last key so it
    // keeps rendering instead of throwing a null-check error (the red screen).
    final keyName = provider.selectedKey ?? _lastKey;
    if (keyName == null) return const SizedBox.shrink();
    _lastKey = keyName;
    final idx = provider.progressData.indexWhere((k) => k.key == keyName);
    final color = AppColors.keyColor(idx.clamp(0, 11));
    final kd = provider.progressData[idx.clamp(0, provider.progressData.length - 1)];
    final isPro = provider.isPro;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            final alpha = (_glowAnim.value * 100).round();
            return Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.2, 0),
                    radius: 1.2,
                    colors: [color.withAlpha(alpha), Colors.transparent],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) {
            final alphaR = ((0.55 - _glowAnim.value) * 100).round().clamp(0, 255);
            return Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.2, 0),
                    radius: 1.2,
                    colors: [color.withAlpha(alphaR), Colors.transparent],
                  ),
                ),
              ),
            );
          },
        ),

        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () { HapticsService.impactLight(); provider.deselectKey(); },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white60, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FittedBox(fit: BoxFit.scaleDown,
                          child: Text('Choose Mode',
                            maxLines: 1, softWrap: false,
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.9))),
                        const Text('Select how you want to train today',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final diatonicCard = _BigModeCard(
                    keyName: keyName,
                    title: 'Diatonic',
                    description: 'Master the 7 notes of the scale.',
                    iconWidget: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF388EF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7BB8FB).withAlpha(120)),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 32),
                    ),
                    accentColor: const Color(0xFF3B82F6),
                    borderColor: const Color(0xFF3B82F6).withAlpha(80),
                    shadowColor: const Color(0xFF3B82F6).withAlpha(25),
                    levels: kd.diatonicLevels,
                    currentDifficulty: provider.diatonicDifficulty,
                    onDifficultyChanged: provider.setDiatonicDifficulty,
                    modeLevel: _getModeLevel(kd.diatonicLevels),
                    isLocked: false,
                    onTap: () { HapticsService.impactMedium(); provider.startMode(TrainingMode.diatonic); },
                );
                final chromaticCard = _BigModeCard(
                    keyName: keyName,
                    title: 'Chromatic',
                    description: 'Challenge yourself with all 12 semitones.',
                    iconWidget: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0084),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF69B4).withAlpha(120)),
                      ),
                      child: const Center(child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ThickGlyph('♯', 30),
                          _ThickGlyph('♭', 36),
                        ],
                      )),
                    ),
                    accentColor: const Color(0xFFA855F7),
                    borderColor: const Color(0xFFA855F7).withAlpha(80),
                    shadowColor: const Color(0xFFA855F7).withAlpha(25),
                    levels: kd.chromaticLevels,
                    currentDifficulty: provider.chromaticDifficulty,
                    onDifficultyChanged: provider.setChromaticDifficulty,
                    modeLevel: _getModeLevel(kd.chromaticLevels),
                    isLocked: !isPro && keyName != 'C',
                    onTap: () {
                      HapticsService.impactMedium();
                      if (!isPro && keyName != 'C') { widget.onShowPaywall(); return; }
                      provider.startMode(TrainingMode.chromatic);
                    },
                );
                // Both cards need ~300dp of content at the narrowest width. If
                // they fit, fill the screen (the reference look); otherwise scroll
                // so nothing is ever clipped on short / high-density screens.
                const cardMinH = 300.0;
                final fits = constraints.maxHeight >= cardMinH * 2 + 16;
                final content = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: fits
                      ? Column(children: [
                          Expanded(child: diatonicCard),
                          const SizedBox(height: 16),
                          Expanded(child: chromaticCard),
                        ])
                      : Column(children: [
                          SizedBox(height: cardMinH, child: diatonicCard),
                          const SizedBox(height: 16),
                          SizedBox(height: cardMinH, child: chromaticCard),
                        ]),
                );
                return fits ? content : SingleChildScrollView(child: content);
              }),
            ),
          ]),
        ),
      ]),
    );
  }

  int _getModeLevel(List<int> levels) {
    final sum = levels[0] + levels[1] + levels[2];
    final pct = sum / 120 * 100;
    if (pct >= 87.5) return 8;
    if (pct >= 75) return 7;
    if (pct >= 62.5) return 6;
    if (pct >= 50) return 5;
    if (pct >= 37.5) return 4;
    if (pct >= 25) return 3;
    if (pct >= 12.5) return 2;
    return 1;
  }
}

// ─── LOCKED LEVEL SHEET ──────────────────────────────────────────────────────

class _LockedSheet extends StatelessWidget {
  final String levelName;
  final String prevName;
  final int currentScore;
  final int neededScore;
  final Color accentColor;

  const _LockedSheet({
    required this.levelName,
    required this.prevName,
    required this.currentScore,
    required this.neededScore,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentScore / neededScore).clamp(0.0, 1.0);
    final remaining = (neededScore - currentScore).clamp(0, neededScore);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF12101E),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha:0.18), blurRadius: 60, spreadRadius: -10),
            BoxShadow(color: Colors.black.withValues(alpha:0.7), blurRadius: 40),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: accentColor.withValues(alpha:0.25), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(children: [
            // Top glow decoration
            Positioned(
              top: -60, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [accentColor.withValues(alpha:0.15), Colors.transparent]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha:0.35), width: 1.5),
                      boxShadow: [BoxShadow(color: accentColor.withValues(alpha:0.25), blurRadius: 24)],
                    ),
                    child: Icon(Icons.lock_rounded, color: accentColor, size: 28),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    '$levelName is Locked',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'Keep training in $prevName mode to unlock this difficulty.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha:0.5),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Progress section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha:0.07)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'YOUR PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha:0.35),
                                letterSpacing: 2,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$currentScore',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $neededScore',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha:0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [accentColor, accentColor.withValues(alpha:0.6)],
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha:0.5), blurRadius: 8)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$remaining more points needed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha:0.35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dismiss button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withValues(alpha:0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: accentColor.withValues(alpha:0.35), blurRadius: 24, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: const Text(
                        'KEEP TRAINING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── BIG MODE CARD (key detail) ──────────────────────────────────────────────

class _BigModeCard extends StatefulWidget {
  final String keyName;
  final String title;
  final String description;
  final Widget iconWidget;
  final Color accentColor;
  final Color borderColor;
  final Color shadowColor;
  final List<int> levels;
  final int currentDifficulty;
  final ValueChanged<int> onDifficultyChanged;
  final int modeLevel;
  final bool isLocked;
  final VoidCallback onTap;

  const _BigModeCard({
    required this.keyName, required this.title, required this.description,
    required this.iconWidget, required this.accentColor, required this.borderColor,
    required this.shadowColor, required this.levels, required this.currentDifficulty,
    required this.onDifficultyChanged, required this.modeLevel,
    required this.isLocked, required this.onTap,
  });

  @override
  State<_BigModeCard> createState() => _BigModeCardState();
}

class _StartButton extends StatefulWidget {
  final bool isLocked;
  final Color accentColor;
  final VoidCallback onTap;
  const _StartButton({required this.isLocked, required this.accentColor, required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
            SizedBox(width: 8),
            Text('PRO ONLY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white38)),
          ],
        ),
      );
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withValues(alpha:0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: widget.accentColor.withValues(alpha:0.38), blurRadius: 28, offset: const Offset(0, 8)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('START', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigModeCardState extends State<_BigModeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showLockedMessage(BuildContext context, int d) {
    final currentScore = widget.levels[d - 2];
    final needed = d == 2 ? 27 : 37;
    final levelName = d == 2 ? 'Virtuoso' : 'Master';
    final prevName = d == 2 ? 'Apprentice' : 'Virtuoso';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LockedSheet(
        levelName: levelName,
        prevName: prevName,
        currentScore: currentScore,
        neededScore: needed,
        accentColor: widget.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caps = [30, 40, 50];
    final diffColors = [const Color(0xFF3B82F6), const Color(0xFFA855F7), const Color(0xFFF43F5E)];
    final diffLabels = ['Apprentice', 'Virtuoso', 'Master'];
    final isLvl2Unlocked = widget.levels[0] >= 27;
    final isLvl3Unlocked = widget.levels[1] >= 37;

    // Best score for the selected difficulty, shown where the level badge was.
    // The cap (max questions) changes per difficulty, so we also show a % —
    // coloured by how strong the record is (grey when never played).
    final bestScore = widget.levels[widget.currentDifficulty - 1];
    final bestCap = caps[widget.currentDifficulty - 1];
    final bestPct = bestCap > 0 ? (bestScore / bestCap * 100).round() : 0;
    final bestColor = bestScore <= 0
        ? Colors.white.withAlpha(80)
        : bestScore >= bestCap
            ? const Color(0xFFfacc15) // perfect → gold
            : bestPct >= 80
                ? const Color(0xFF10B981) // green
                : bestPct >= 50
                    ? const Color(0xFFF59E0B) // amber
                    : const Color(0xFFFB7185); // red/pink

    return Opacity(
      opacity: widget.isLocked ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF21A1625),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: widget.isLocked ? Colors.white10 : widget.borderColor, width: 1.2),
          boxShadow: [BoxShadow(color: widget.isLocked ? Colors.transparent : widget.shadowColor, blurRadius: 40)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
            if (!widget.isLocked)
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [widget.accentColor.withAlpha(50), Colors.transparent]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.iconWidget,
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(children: List.generate(3, (i) {
                            final d = i + 1;
                            final isCurrent = d == widget.currentDifficulty;
                            final canSelect = d == 1 || (d == 2 && isLvl2Unlocked) || (d == 3 && isLvl3Unlocked);
                            final isPerfect = widget.levels[i] >= caps[i];
                            final played = widget.levels[i] > 0; // attempted this level
                            final selColor = isPerfect ? const Color(0xFFfacc15) : diffColors[i];

                            // A note stays coloured once the level has been played
                            // (or perfected); it is dimmed only if never attempted.
                            // The selected one is brighter and larger (below).
                            Widget noteWidget = SizedBox(
                              width: 54, height: 54,
                              child: Center(
                                child: Icon(Icons.music_note_rounded,
                                  color: isPerfect
                                      ? const Color(0xFFfacc15)
                                      : (played ? diffColors[i] : Colors.white.withValues(alpha:0.22)),
                                  size: 32),
                              ),
                            );

                            if (isCurrent) {
                              noteWidget = AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, _) => Transform.scale(
                                  scale: _scaleAnim.value,
                                  child: SizedBox(
                                    width: 54, height: 54,
                                    child: Center(
                                      child: Icon(Icons.music_note_rounded, color: selColor, size: 44),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: widget.isLocked ? null : () {
                                if (canSelect) {
                                  HapticsService.impactLight();
                                  widget.onDifficultyChanged(d);
                                } else {
                                  _showLockedMessage(context, d);
                                }
                              },
                              child: noteWidget,
                            );
                          })),
                          const SizedBox(height: 4),
                          Text(diffLabels[widget.currentDifficulty - 1].toUpperCase(),
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.6,
                              color: widget.levels[widget.currentDifficulty - 1] >= caps[widget.currentDifficulty - 1]
                                  ? const Color(0xFFfacc15) : diffColors[widget.currentDifficulty - 1],
                            )),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            NoteText(
                              note: formatNoteForDisplay(widget.keyName,
                                  context.select<AppProvider, String>((p) => p.notation)),
                              style: const TextStyle(fontSize: 33, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                            const SizedBox(width: 7),
                            Text(widget.title,
                              style: const TextStyle(fontSize: 33, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                          ],
                        ),
                      )),
                      const SizedBox(width: 10),
                      // Best-score badge (replaces the old LEVEL badge): the
                      // record of correct answers for this mode & difficulty,
                      // with a colour-coded percentage.
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$bestPct%',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1, letterSpacing: -0.5, color: bestColor)),
                          const SizedBox(height: 3),
                          Text('$bestScore/$bestCap BEST',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white.withAlpha(90))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(widget.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white60, height: 1.5)),
                  if (widget.isLocked) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_rounded, color: Colors.white38, size: 12),
                        SizedBox(width: 4),
                        Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1)),
                      ]),
                    ),
                  ],
                  const Spacer(flex: 3),
                  _StartButton(
                    isLocked: widget.isLocked,
                    accentColor: widget.accentColor,
                    onTap: widget.onTap,
                  ),
                ],
              ),
            ),
          ]),
        ),
    );
  }
}

/// A single glyph drawn slightly heavier than the max font weight (w900).
/// A thin same-colour stroke is layered under the fill (faux-bold) so the
/// chromatic ♯/♭ symbols read a touch thicker without changing their shape.
class _ThickGlyph extends StatelessWidget {
  final String glyph;
  final double size;
  const _ThickGlyph(this.glyph, this.size);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(glyph, style: TextStyle(
          fontSize: size, fontWeight: FontWeight.w900, height: 1,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white,
        )),
        Text(glyph, style: TextStyle(
          fontSize: size, fontWeight: FontWeight.w900, height: 1, color: Colors.white,
        )),
      ],
    );
  }
}
