import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_provider.dart';
import '../models/training_mode.dart';
import '../constants/levels.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'trainer_screen.dart';
import 'session_summary_screen.dart';
import 'onboarding_screen.dart';
import 'setup_screen.dart';
import '../widgets/paywall_modal.dart';
import '../widgets/level_up_modal.dart';
import '../constants/app_colors.dart';
import '../services/purchase_service.dart';
import '../services/analytics_service.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentTab = 0;
  Map<String, dynamic>? _finishedSession;
  bool _showPaywall = false;
  TrainingMode? _pendingSetup; // which setup screen to show

  // Rainbow frame-glow flag: true for one 3s colour cycle after a PERFECT
  // session, driving the [_RainbowGlowOverlay] that haloes the screen edges.
  bool _perfectGlow = false;

  // Stable bottom inset: on some devices/emulators the system gesture bar
  // toggles, making MediaQuery.padding.bottom oscillate and the floating nav
  // jump. We latch the largest value seen so the nav stays put.
  double _stableBottomInset = 0;

  // Level-up
  AnimalLevel? _prevLevel;
  AnimalLevel? _levelUpLevel; // set when level-up detected

  // Confetti — kept separate from _levelUpLevel so the burst keeps falling in
  // the animal colour even after the modal is dismissed ("Awesome").
  late final ConfettiController _confettiCtrl;
  Color? _confettiColor;

  // Rainbow rain for a PERFECT session (correct == total) — like the web app:
  // an initial centre burst plus confetti raining from the top for 3 seconds.
  late final ConfettiController _perfectCtrl;

  // Swipeable tabs — Home / Stats / Settings. State (incl. scroll position) is
  // preserved by keep-alive pages, so returning to a tab resumes where you left.
  final PageController _pageController = PageController();

  // Provider listener for debug-button level-up detection
  AppProvider? _observedProvider;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _perfectCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  static const _tabNames = ['home', 'stats', 'settings'];
  void _trackTab(int i) {
    if (i >= 0 && i < _tabNames.length) {
      AnalyticsService.instance.capture('screen_view', {'name': _tabNames[i]});
    }
  }

  void _switchTab(int i) {
    if (i == _currentTab) return;
    setState(() => _currentTab = i);
    _trackTab(i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (_observedProvider == provider) return;
    _observedProvider?.removeListener(_onProviderUpdate);
    _observedProvider = provider;
    _prevLevel ??= provider.animalLevel;
    provider.addListener(_onProviderUpdate);
  }

  void _onProviderUpdate() {
    final provider = _observedProvider;
    if (provider == null || !mounted) return;
    // Detect level-ups while on the home screen (triggered by debug buttons)
    if (provider.activeMode == null && _finishedSession == null) {
      final current = provider.animalLevel;
      if (_prevLevel != null && current.level > _prevLevel!.level) {
        setState(() { _levelUpLevel = current; _confettiColor = current.color; });
        AnalyticsService.instance.capture('level_up', {'level': current.level, 'animal': current.name});
        // Emit after the rebuild so the confetti overlay already has the new
        // animal colour (otherwise the first burst comes out white).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _confettiCtrl.play();
        });
      }
      _prevLevel = current;
    }
  }

  @override
  void dispose() {
    _observedProvider?.removeListener(_onProviderUpdate);
    _pageController.dispose();
    _confettiCtrl.dispose();
    _perfectCtrl.dispose();
    super.dispose();
  }

  void _showPaywallSheet([String? reason]) {
    AnalyticsService.instance.capture('paywall_shown', {'reason': ?reason});
    setState(() => _showPaywall = true);
  }

  void _showPurchaseError(PurchaseOutcome outcome) {
    final detail = PurchaseService.instance.lastPurchaseError;
    final (title, message) = switch (outcome) {
      PurchaseOutcome.noProducts => (
        'Store not ready',
        'No product is available for purchase right now. Please try again in a '
            'few minutes.',
      ),
      PurchaseOutcome.noEntitlement => (
        'Almost there',
        'Your payment went through but PRO could not be activated automatically. '
            'Use "Restore" in a moment — you will not be charged twice.',
      ),
      PurchaseOutcome.notConfigured => (
        'Billing unavailable',
        'In-app purchases are not available on this device.',
      ),
      _ => (
        'Purchase failed',
        'Something went wrong while contacting the store. Please try again.',
      ),
    };
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1625),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.5)),
            if (detail != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(detail,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11.5,
                        height: 1.4)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openSetup(TrainingMode mode) {
    AnalyticsService.instance.capture('setup_opened', {'mode': mode.storageKey});
    setState(() => _pendingSetup = mode);
  }

  void _handleFinishSession(Map<String, dynamic> data, AppProvider provider) {
    // Detect level-up
    final newLevel = provider.animalLevel;
    if (_prevLevel != null && newLevel.level > _prevLevel!.level) {
      setState(() { _levelUpLevel = newLevel; _confettiColor = newLevel.color; });
      AnalyticsService.instance.capture('level_up', {'level': newLevel.level, 'animal': newLevel.name});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiCtrl.play();
      });
    }
    AnalyticsService.instance.capture('session_finished');
    // Update _prevLevel now so the provider listener won't double-trigger
    // when exitTrainer() fires after the user leaves the summary screen.
    _prevLevel = newLevel;

    provider.finishSession();
    setState(() => _finishedSession = data);

    // Perfect session → rainbow confetti rain + frame-glow over the summary
    // (web parity). Fires on EVERY zero-error session, regardless of whether the
    // level had already been mastered before — it only looks at this run.
    final correct = (data['correct'] as num?)?.toInt() ?? 0;
    final total = (data['total'] as num?)?.toInt() ?? 0;
    if (total > 0 && correct == total) {
      AnalyticsService.instance.capture('perfect_session', {'mode': data['mode'], 'key': data['key']});
      _triggerPerfectCelebration();
    }
  }

  /// Fires the rainbow frame-glow + confetti burst. Shared by real perfect
  /// sessions and the debug "simulate" button, so both look identical.
  void _triggerPerfectCelebration() {
    setState(() => _perfectGlow = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _perfectCtrl.play();
    });
    // Hold the glow for one full 3s spectrum cycle, then fade it out.
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _perfectGlow = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Latch the largest bottom inset so a flickering system gesture bar can't
    // make the floating nav jump up and down.
    final rawBottom = MediaQuery.of(context).viewPadding.bottom;
    if (rawBottom > _stableBottomInset) _stableBottomInset = rawBottom;

    if (!provider.tutorialCompleted) {
      return OnboardingScreen(onComplete: () {
        // The PageView remounts at page 0 when the main scaffold returns; reset
        // the nav index to match so the indicator and the page can't desync
        // (e.g. Training shown while the bar still highlights Settings).
        _currentTab = 0;
        AnalyticsService.instance.capture('onboarding_completed');
        provider.completeTutorial();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) _pageController.jumpToPage(0);
        });
      });
    }

    // Setup screens (overlay before entering trainer)
    if (_pendingSetup != null && provider.activeMode == null) {
      final key = provider.selectedKey ?? 'C';
      if (_pendingSetup == TrainingMode.custom) {
        return CustomModeSetup(
          initialKey: key,
          onCancel: () { provider.deselectKey(); setState(() => _pendingSetup = null); },
          onStart: (selKey, degrees, reverse, difficulty, questions) {
            setState(() => _pendingSetup = null);
            provider.startCustomMode(
              degrees: degrees,
              reverse: reverse,
              difficulty: difficulty,
              questions: questions,
              overrideKey: selKey,
            );
          },
        );
      } else if (_pendingSetup == TrainingMode.noteToNumber) {
        return NoteToNumberSetup(
          initialKey: key,
          onCancel: () { provider.deselectKey(); setState(() => _pendingSetup = null); },
          onStart: (selKey, degrees, difficulty) {
            setState(() => _pendingSetup = null);
            provider.startNoteToNumberMode(
              degrees: degrees,
              difficulty: difficulty,
              overrideKey: selKey,
            );
          },
        );
      }
    }

    if (provider.activeMode != null) {
      if (_finishedSession != null) {
        return Stack(
          children: [
            SessionSummaryScreen(
              sessionData: _finishedSession!,
              progressData: provider.progressData,
              onRetry: () => setState(() { _finishedSession = null; _perfectGlow = false; }),
              onBack: () {
                final mode = provider.activeMode;
                final isSpecial = mode == TrainingMode.noteToNumber || mode == TrainingMode.custom;
                setState(() { _finishedSession = null; _perfectGlow = false; });
                if (isSpecial) provider.deselectKey();
                provider.exitTrainer();
              },
              onNextDifficulty: (newDiff) {
                setState(() { _finishedSession = null; _perfectGlow = false; });
                final mode = provider.activeMode!;
                if (mode == TrainingMode.diatonic) {
                  provider.setDiatonicDifficulty(newDiff);
                } else {
                  provider.setChromaticDifficulty(newDiff);
                }
              },
            ),
            _RainbowGlowOverlay(visible: _perfectGlow),
            _PerfectRainOverlay(controller: _perfectCtrl),
            if (_levelUpLevel != null)
              Positioned.fill(
                child: LevelUpModal(
                  key: ValueKey(_levelUpLevel!.level),
                  animal: _levelUpLevel!,
                  onClose: () => setState(() => _levelUpLevel = null),
                ),
              ),
            _ConfettiOverlay(
              controller: _confettiCtrl,
              color: _levelUpLevel?.color ?? Colors.white,
            ),
          ],
        );
      }

      return TrainerScreen(
        mode: provider.activeMode!,
        selectedKey: provider.selectedKey ?? 'C',
        difficulty: provider.activeMode == TrainingMode.diatonic
            ? provider.diatonicDifficulty
            : (provider.customDifficulty ?? provider.chromaticDifficulty),
        numberOfQuestions: provider.customQuestions,
        customDegrees: provider.customDegrees,
        isReverse: provider.isReverse,
        adaptiveDifficulty: provider.adaptiveDifficulty,
        sessionHistory: provider.stats.sessionHistory,
        notation: provider.notation,
        keyboardFromTonic: provider.keyboardFromTonic,
        onExit: () {
          final mode = provider.activeMode;
          final isSpecial = mode == TrainingMode.noteToNumber || mode == TrainingMode.custom;
          if (isSpecial) provider.deselectKey();
          provider.exitTrainer();
        },
        onAnswer: (isCorrect, rt, details) {
          provider.recordAnswer(
            isCorrect: isCorrect,
            responseTime: rt,
            answerDetails: details,
          );
        },
        onFinish: (data) => _handleFinishSession(data, provider),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            // Swipe is enabled only on the top-level tabs — disabled while a
            // key is selected (Choose Mode) or the paywall is up.
            physics: (provider.selectedKey == null && !provider.viewingKeyStats && !_showPaywall)
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (i) {
              if (i != _currentTab) { setState(() => _currentTab = i); _trackTab(i); }
            },
            children: [
              _KeepAlivePage(child: HomeScreen(onShowPaywall: _showPaywallSheet, onOpenSetup: _openSetup)),
              _KeepAlivePage(child: StatsScreen(onShowPaywall: _showPaywallSheet)),
              _KeepAlivePage(child: SettingsScreen(onShowPaywall: _showPaywallSheet, onSimulatePerfect: _triggerPerfectCelebration)),
            ],
          ),
          if (_showPaywall)
            Positioned.fill(
              child: PaywallModal(
                onClose: () => setState(() => _showPaywall = false),
                onPurchase: () async {
                  final outcome = await PurchaseService.instance.purchasePro();
                  if (!mounted) return;
                  if (outcome == PurchaseOutcome.success) {
                    provider.setIsPro(true);
                    setState(() => _showPaywall = false);
                  } else if (outcome != PurchaseOutcome.cancelled) {
                    // Keep the paywall open and tell the user what went wrong —
                    // a silent dead button is the worst possible outcome.
                    _showPurchaseError(outcome);
                  }
                },
              ),
            ),
          if (provider.selectedKey == null && !provider.viewingKeyStats && !_showPaywall)
            Positioned(
              bottom: 24 + _stableBottomInset,
              left: 0,
              right: 0,
              child: _FloatingNav(
                currentIndex: _currentTab,
                onTap: _switchTab,
              ),
            ),
          if (_levelUpLevel != null)
            Positioned.fill(
              child: LevelUpModal(
                key: ValueKey(_levelUpLevel!.level),
                animal: _levelUpLevel!,
                onClose: () => setState(() => _levelUpLevel = null),
              ),
            ),
          // Perfect-session celebration also renders here so it can fire from the
          // home/settings tabs (real perfect runs show it on the summary screen).
          _RainbowGlowOverlay(visible: _perfectGlow),
          _PerfectRainOverlay(controller: _perfectCtrl),
          _ConfettiOverlay(
            controller: _confettiCtrl,
            color: _confettiColor ?? Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Keeps a PageView child mounted (and its scroll position) when swiped away,
/// so each tab resumes exactly where it was left.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Perfect-session celebration, mirroring the web app: one big centre burst
/// plus confetti raining down from the top on both sides for ~3 seconds,
/// in rainbow colours.
class _PerfectRainOverlay extends StatelessWidget {
  final ConfettiController controller;
  const _PerfectRainOverlay({required this.controller});

  // Web palette: brand burst colours + canvas-confetti rainbow defaults.
  static const _rainbow = [
    Color(0xFFEF4444), // red
    Color(0xFFF97316), // orange
    Color(0xFFFACC15), // yellow
    Color(0xFF22C55E), // green
    Color(0xFF388EF8), // blue
    Color(0xFFA855F7), // purple
    Color(0xFFFF0084), // pink
  ];

  @override
  Widget build(BuildContext context) {
    Widget emitter({
      required Alignment alignment,
      required double frequency,
      required int particles,
      required double maxForce,
      required double minForce,
      required double gravity,
    }) {
      return IgnorePointer(
        child: Align(
          alignment: alignment,
          child: ConfettiWidget(
            confettiController: controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: frequency,
            numberOfParticles: particles,
            maxBlastForce: maxForce,
            minBlastForce: minForce,
            gravity: gravity,
            shouldLoop: false,
            colors: _rainbow,
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Stack(children: [
        // One modest centre burst — the frame-glow carries the celebration now,
        // so the confetti stays light instead of burying the screen.
        emitter(alignment: const Alignment(0, 0.2), frequency: 0.02,
            particles: 16, maxForce: 42, minForce: 14, gravity: 0.3),
        // Light rain from the two top corners.
        emitter(alignment: const Alignment(-0.7, -1.05), frequency: 0.3,
            particles: 4, maxForce: 22, minForce: 7, gravity: 0.25),
        emitter(alignment: const Alignment(0.7, -1.05), frequency: 0.3,
            particles: 4, maxForce: 22, minForce: 7, gravity: 0.25),
        // A few streamers from the left & right edges.
        emitter(alignment: const Alignment(-1.05, -0.3), frequency: 0.25,
            particles: 3, maxForce: 24, minForce: 7, gravity: 0.28),
        emitter(alignment: const Alignment(1.05, -0.3), frequency: 0.25,
            particles: 3, maxForce: 24, minForce: 7, gravity: 0.28),
      ]),
    );
  }
}

/// Rainbow frame-glow for a PERFECT session — a fixed overlay that haloes the
/// screen edges with a doubled inset glow (strong inner + soft outer band),
/// cycling through the full spectrum every 3 seconds. Hand-rolled with edge
/// gradients (no native inset-shadow support needed), so it stays cheap and
/// composites in a single layer. Mirrors the old web app's animated box-shadow.
class _RainbowGlowOverlay extends StatefulWidget {
  final bool visible;
  const _RainbowGlowOverlay({required this.visible});

  @override
  State<_RainbowGlowOverlay> createState() => _RainbowGlowOverlayState();
}

class _RainbowGlowOverlayState extends State<_RainbowGlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _render = false; // whether the overlay is mounted at all
  double _opacity = 0; // AnimatedOpacity target — fades in on show, out on hide

  // Inner (strong, 50%) spectrum — one full loop back to the start.
  static const _inner = [
    Color(0x80FF0000), Color(0x80FFFF00), Color(0x8000FF00), Color(0x800000FF),
    Color(0x804B0082), Color(0x809400D3), Color(0x80FF0000),
  ];
  // Outer (soft, 30%) spectrum, offset a step for a two-tone frame.
  static const _outer = [
    Color(0x4DFF7F00), Color(0x4D00FF00), Color(0x4D00FFFF), Color(0x4D4B0082),
    Color(0x4D9400D3), Color(0x4DFF0080), Color(0x4DFF7F00),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (widget.visible) _show();
  }

  void _show() {
    _c
      ..reset()
      ..repeat();
    _render = true;
    _opacity = 0;
    // Fade in on the next frame so AnimatedOpacity animates 0 → 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.visible) setState(() => _opacity = 1);
    });
  }

  @override
  void didUpdateWidget(_RainbowGlowOverlay old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      setState(_show);
    } else if (!widget.visible && old.visible) {
      // Fade out smoothly; the colour cycle keeps running until the fade ends.
      setState(() => _opacity = 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static Color _lerp(List<Color> colors, double t) {
    final segs = colors.length - 1;
    final scaled = t * segs;
    final i = scaled.floor().clamp(0, segs - 1);
    return Color.lerp(colors[i], colors[i + 1], scaled - i)!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_render) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _opacity,
          // Quick fade-in, slower graceful fade-out (no abrupt cut).
          duration: Duration(milliseconds: _opacity == 1 ? 350 : 750),
          curve: Curves.easeOut,
          onEnd: () {
            // Once the fade-out completes, unmount and stop the colour cycle.
            if (_opacity == 0 && mounted) {
              _c.stop();
              setState(() => _render = false);
            }
          },
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final inner = _lerp(_inner, _c.value);
              final outer = _lerp(_outer, _c.value);
              return Stack(children: [
                // Soft outer band first (wider, atmospheric)…
                ..._frame(outer, 96),
                // …then the strong inner band on top (narrower, vivid).
                ..._frame(inner, 52),
              ]);
            },
          ),
        ),
      ),
    );
  }

  // Four edge gradients (top/bottom/left/right) fading inward to transparent,
  // together reading as an inset glow that frames the whole screen.
  List<Widget> _frame(Color color, double thickness) => [
        Positioned(top: 0, left: 0, right: 0, height: thickness,
          child: _grad(color, Alignment.topCenter, Alignment.bottomCenter)),
        Positioned(bottom: 0, left: 0, right: 0, height: thickness,
          child: _grad(color, Alignment.bottomCenter, Alignment.topCenter)),
        Positioned(top: 0, bottom: 0, left: 0, width: thickness,
          child: _grad(color, Alignment.centerLeft, Alignment.centerRight)),
        Positioned(top: 0, bottom: 0, right: 0, width: thickness,
          child: _grad(color, Alignment.centerRight, Alignment.centerLeft)),
      ];

  Widget _grad(Color color, Alignment begin, Alignment end) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: begin, end: end,
              colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class _ConfettiOverlay extends StatelessWidget {
  final ConfettiController controller;
  final Color color;
  const _ConfettiOverlay({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        // Re-create the widget when the colour changes so the particle system
        // re-initialises with the new colours (it caches them on first build,
        // which otherwise kept the confetti white).
        key: ValueKey(color),
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: 40,
        maxBlastForce: 55,
        minBlastForce: 20,
        emissionFrequency: 0.06,
        gravity: 0.3,
        // Match the web app: the level/animal colour mixed with white.
        colors: [
          color,
          color,
          Colors.white,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.fitness_center_rounded, 'Training'),
      (Icons.bar_chart_rounded, 'Stats'),
      (Icons.settings_rounded, 'Settings'),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth * 0.9 < 360 ? screenWidth * 0.9 : 360.0;
    final indicatorWidth = (navWidth - 12) / 3;

    return Center(
      child: Container(
        width: navWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 20)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Frosted translucent pill — the ONLY clipped layer.
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xB31A1625),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0x0DFFFFFF)),
                    ),
                  ),
                ),
              ),
            ),
            // Indicator + buttons are NOT clipped, so the active pill keeps its
            // full rounded ends and glow on every tab (the Settings tab used to
            // get its right side clipped by the outer pill clip).
            Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Sliding gradient indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: currentIndex * indicatorWidth,
                    top: 0,
                    bottom: 0,
                    width: indicatorWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x664F46E5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nav buttons row
                  Row(
                  children: List.generate(items.length, (i) {
                    final (icon, label) = items[i];
                    final isActive = currentIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
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
