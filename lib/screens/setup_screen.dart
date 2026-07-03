import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../widgets/note_text.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NoteToNumberSetup
// ─────────────────────────────────────────────────────────────────────────────

class NoteToNumberSetup extends StatefulWidget {
  final String initialKey;
  final void Function(String key, List<String> degrees, int difficulty) onStart;
  final VoidCallback onCancel;

  const NoteToNumberSetup({
    super.key,
    required this.initialKey,
    required this.onStart,
    required this.onCancel,
  });

  @override
  State<NoteToNumberSetup> createState() => _NoteToNumberSetupState();
}

class _NoteToNumberSetupState extends State<NoteToNumberSetup> {
  late String _key;
  bool _chromatic = false;
  int _diff = 1;

  static const _diffLabels = ['Apprentice', 'Virtuoso', 'Master'];
  static const _accent = Color(0xFF34D399);
  static const _grad = [Color(0xFF34D399), Color(0xFF34D399)]; // monochrome green (START button)

  @override
  void initState() {
    super.initState();
    _key = widget.initialKey;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => widget.onCancel(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _GlowBg(primary: _accent, secondary: const Color(0xFF10B981)),
            SafeArea(
              child: Column(
                children: [
                  // The whole page scrolls — header included.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            title: 'Note to Number',
                            subtitle: 'TRAINING SETUP',
                            // Monochrome title (solid green), not a gradient.
                            gradColors: const [Color(0xFF34D399), Color(0xFF34D399)],
                            onBack: widget.onCancel,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  icon: Icons.music_note_rounded,
                                  title: 'Select Root Key',
                                  subtitle: 'Choose the foundation for your training.',
                                ),
                                const SizedBox(height: 18),
                                _KeyGrid(
                                  selected: _key,
                                  accentColor: _accent,
                                  onSelect: (k) => setState(() => _key = k),
                                ),
                                const SizedBox(height: 36),
                                _SectionTitle(
                                  icon: Icons.bolt_rounded,
                                  title: 'Training Intensity',
                                  subtitle: _chromatic
                                      ? 'Master all 12 chromatic notes in this key.'
                                      : 'Focus on the 7 notes of the major scale.',
                                ),
                                const SizedBox(height: 18),
                                _SlidingPillRow(
                                  opts: const ['Diatonic', 'Chromatic'],
                                  sel: _chromatic ? 'Chromatic' : 'Diatonic',
                                  accentColor: _accent,
                                  onChange: (v) => setState(() => _chromatic = v == 'Chromatic'),
                                ),
                                const SizedBox(height: 36),
                                const _SectionTitle(
                                  icon: Icons.track_changes_rounded,
                                  title: 'Difficulty',
                                  subtitle: 'Higher difficulty means less time to answer.',
                                ),
                                const SizedBox(height: 18),
                                _SlidingPillRow(
                                  opts: _diffLabels,
                                  sel: _diffLabels[_diff - 1],
                                  accentColor: _accent,
                                  onChange: (v) => setState(() => _diff = _diffLabels.indexOf(v) + 1),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _StartBtn(
                    gradColors: _grad,
                    shadowColor: _accent.withValues(alpha:0.4),
                    onTap: () {
                      // Note→Number is reverse: use the split chromatic degrees
                      // (♭3 and ♯2 are trained as distinct degrees).
                      final degrees = _chromatic
                          ? kChromaticDegreesSplit.toList()
                          : ['1', '2', '3', '4', '5', '6', '7'];
                      widget.onStart(_key, degrees, _diff);
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// CustomModeSetup
// ─────────────────────────────────────────────────────────────────────────────

class CustomModeSetup extends StatefulWidget {
  final String initialKey;
  final void Function(
    String key,
    List<String> degrees,
    bool isReverse,
    int difficulty,
    int questions,
  ) onStart;
  final VoidCallback onCancel;

  const CustomModeSetup({
    super.key,
    required this.initialKey,
    required this.onStart,
    required this.onCancel,
  });

  @override
  State<CustomModeSetup> createState() => _CustomModeSetupState();
}

class _CustomModeSetupState extends State<CustomModeSetup> {
  late String _key;
  bool _isReverse = false;
  // web default: ["1","3","5"]; every degree is freely selectable.
  Set<String> _degs = {'1', '3', '5'};
  int _diff = 1;
  int _questions = 15;

  static const _diffLabels = ['Apprentice', 'Virtuoso', 'Master'];
  static const _questionOpts = ['15', '30', '50', '75', '100'];
  static const _accent = Color(0xFFD857EC);
  static const _grad = [Color(0xFFD857EC), Color(0xFFD857EC)]; // monochrome purple (START button)

  @override
  void initState() {
    super.initState();
    _key = widget.initialKey;
  }

  void _setDiatonic() => setState(() => _degs = {'1', '2', '3', '4', '5', '6', '7'});
  void _setAll() => setState(() =>
      _degs = Set.of(_isReverse ? kChromaticDegreesSplit : kChromaticDegrees));

  // Note→Number splits enharmonic degrees (♭3/♯2 → ♭3 + ♯2); Degree→Note keeps
  // the slash form. Convert the current selection when the direction flips so it
  // stays valid for the grid being shown.
  Set<String> _convertDegs(Set<String> degs, bool toReverse) {
    final out = <String>{};
    for (final d in degs) {
      if (toReverse) {
        out.addAll(kDegreeSplitMap[d] ?? [d]);
      } else {
        out.add(kDegreeCollapseMap[d] ?? d);
      }
    }
    return out;
  }

  void _toggleDeg(String deg) {
    setState(() {
      if (_degs.contains(deg)) {
        if (_degs.length > 1) _degs.remove(deg); // keep at least one selected
      } else {
        _degs.add(deg);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => widget.onCancel(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _GlowBg(primary: _accent, secondary: const Color(0xFFA855F7)),
            SafeArea(
              child: Column(
                children: [
                  // The whole page scrolls — header included.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            title: 'Custom Mode',
                            subtitle: 'PERSONALIZED SESSION',
                            // Monochrome title (solid purple), not a gradient.
                            gradColors: const [Color(0xFFD857EC), Color(0xFFD857EC)],
                            onBack: widget.onCancel,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle(
                                  icon: Icons.music_note_rounded,
                                  title: 'Select Root Key',
                                ),
                                const SizedBox(height: 18),
                                _KeyGrid(
                                  selected: _key,
                                  accentColor: _accent,
                                  onSelect: (k) => setState(() => _key = k),
                                ),
                                const SizedBox(height: 36),

                                _SectionTitle(
                                  icon: Icons.track_changes_rounded,
                                  title: 'Direction',
                                  subtitle: _isReverse
                                      ? 'Identify the degree from its note.'
                                      : 'Identify the note from its degree.',
                                ),
                                const SizedBox(height: 18),
                                _SlidingPillRow(
                                  opts: const ['Degree → Note', 'Note → Degree'],
                                  sel: _isReverse ? 'Note → Degree' : 'Degree → Note',
                                  accentColor: _accent,
                                  onChange: (v) => setState(() {
                                    final rev = v == 'Note → Degree';
                                    if (rev != _isReverse) {
                                      _degs = _convertDegs(_degs, rev);
                                      _isReverse = rev;
                                    }
                                  }),
                                ),
                                const SizedBox(height: 36),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      child: _SectionTitle(
                                        icon: Icons.tune_rounded,
                                        title: 'Select Degrees',
                                      ),
                                    ),
                                    _QuickBtn(label: 'DIATONIC', onTap: _setDiatonic),
                                    const SizedBox(width: 8),
                                    _QuickBtn(label: 'ALL', onTap: _setAll),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _DegreeGrid(
                                  selected: _degs,
                                  onToggle: _toggleDeg,
                                  reverse: _isReverse,
                                ),
                                const SizedBox(height: 36),

                                const _SectionTitle(
                                  icon: Icons.track_changes_rounded,
                                  title: 'Difficulty',
                                  subtitle: 'Higher difficulty means less time to answer.',
                                ),
                                const SizedBox(height: 18),
                                _SlidingPillRow(
                                  opts: _diffLabels,
                                  sel: _diffLabels[_diff - 1],
                                  accentColor: _accent,
                                  onChange: (v) => setState(() => _diff = _diffLabels.indexOf(v) + 1),
                                ),
                                const SizedBox(height: 36),

                                const _SectionTitle(
                                  icon: Icons.auto_awesome_rounded,
                                  title: 'Number of Questions',
                                  subtitle: 'How many questions for this session?',
                                ),
                                const SizedBox(height: 18),
                                _QuestionRow(
                                  opts: _questionOpts,
                                  selected: '$_questions',
                                  accentColor: _accent,
                                  onSelect: (v) => setState(() => _questions = int.parse(v)),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _StartBtn(
                    gradColors: _grad,
                    shadowColor: _accent.withValues(alpha:0.4),
                    icon: Icons.bolt_rounded, // web: Zap
                    onTap: () => widget.onStart(
                      _key, _degs.toList(), _isReverse, _diff, _questions,
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBg extends StatelessWidget {
  final Color primary;
  final Color secondary;
  const _GlowBg({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(top: -80, right: -60, child: _blob(280, primary.withValues(alpha:0.13))),
      Positioned(bottom: -60, left: -40, child: _blob(220, secondary.withValues(alpha:0.10))),
      Positioned(top: MediaQuery.of(context).size.height * 0.4, left: -80,
        child: _blob(200, primary.withValues(alpha:0.06))),
    ]);
  }

  Widget _blob(double size, Color color) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
    child: SizedBox(
      width: size + 120, height: size + 120,
      child: Center(child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      )),
    ),
  );
}

// ── Header: back arrow left, title centered, spacer right ───────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradColors;
  final VoidCallback onBack;

  const _Header({required this.title, required this.subtitle, required this.gradColors, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Circular back button (web: w-12 h-12 rounded-full bg-white/5)
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 26),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    shaderCallback: (b) => LinearGradient(colors: gradColors).createShader(b),
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha:0.4),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // mirror of back button
        ],
      ),
    );
  }
}

// ── Section title (icon + title + subtitle) ──────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({required this.icon, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha:0.6)),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
            ),
          ),
        ),
      ]),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha:0.4)),
        ),
      ],
    ],
  );
}


// ── Key Grid ─────────────────────────────────────────────────────────────────

class _KeyGrid extends StatelessWidget {
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onSelect;
  const _KeyGrid({required this.selected, required this.accentColor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Keys in ascending semitone order: C, D♭, D, E♭, E, F, F♯, G, A♭, A, B♭, B.
    final keys = [...kAllKeys]..sort((a, b) => (kNoteToSemitone[a] ?? 0).compareTo(kNoteToSemitone[b] ?? 0));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12, // web: gap-3
        mainAxisSpacing: 12,
        mainAxisExtent: 56 * MediaQuery.textScalerOf(context).scale(1), // web: h-14
      ),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final sel = k == selected;
        final color = sel ? (AppColors.noteColors[k] ?? accentColor) : accentColor;
        return _KeyCell(noteKey: k, displayColor: color, selected: sel, onTap: () => onSelect(k));
      },
    );
  }
}

class _KeyCell extends StatelessWidget {
  final String noteKey;
  final Color displayColor;
  final bool selected;
  final VoidCallback onTap;
  const _KeyCell({required this.noteKey, required this.displayColor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected;
    final c = displayColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // No press/illuminate animation — the key colours instantly on tap.
      child: Container(
        decoration: BoxDecoration(
          // Selected: vivid note colour with a glossy sheen + soft neon glow.
          // Unselected: quiet glass tile with a hairline border.
          color: sel ? null : Colors.white.withValues(alpha:0.045),
          gradient: sel
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(c, Colors.white, 0.18)!, c],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? Colors.white.withValues(alpha:0.20) : Colors.white.withValues(alpha:0.07),
          ),
          boxShadow: sel
              ? [BoxShadow(color: c.withValues(alpha:0.40), blurRadius: 18, offset: const Offset(0, 6), spreadRadius: -4)]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: NoteText(
              note: noteKey,
              style: TextStyle(
                fontSize: 18, // web: text-lg
                fontWeight: FontWeight.w900,
                color: sel ? Colors.white : Colors.white.withValues(alpha:0.5),
                letterSpacing: -0.5,
                shadows: sel
                    ? const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1))]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sliding Pill Row ─────────────────────────────────────────────────────────
// Animated indicator that slides between options (like the bottom nav bar)

class _SlidingPillRow extends StatelessWidget {
  final List<String> opts;
  final String sel;
  final Color accentColor;
  final ValueChanged<String> onChange;

  const _SlidingPillRow({
    required this.opts,
    required this.sel,
    required this.accentColor,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final selIdx = opts.indexOf(sel).clamp(0, opts.length - 1);
    const pad = 6.0; // web: p-1.5

    return LayoutBuilder(builder: (ctx, box) {
      final totalInner = box.maxWidth - pad * 2;
      final itemW = totalInner / opts.length;

      return Container(
        padding: const EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.05), // web: bg-white/5
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          border: Border.all(color: Colors.white.withValues(alpha:0.06)),
        ),
        child: IntrinsicHeight(
          child: Stack(children: [
            // Sliding indicator — solid accent with a soft matching glow.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: selIdx * itemW + 3,
              top: 0,
              bottom: 0,
              width: itemW - 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(accentColor, Colors.white, 0.15)!, accentColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha:0.35), blurRadius: 14, offset: const Offset(0, 4), spreadRadius: -3),
                  ],
                ),
              ),
            ),
            // Labels (web: text-xs font-black uppercase tracking-widest)
          Row(
            children: opts.map((opt) {
              final active = opt == sel;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChange(opt),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Comfortable ≥48dp touch target — the pills were too thin.
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        // Set the family explicitly — AnimatedDefaultTextStyle does
                        // not inherit it, so it would otherwise fall back to Roboto.
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: active ? const Color(0xE6000000) : Colors.white.withValues(alpha:0.45),
                          letterSpacing: 1.5,
                        ),
                        child: Text(
                          opt.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
        ),
      );
    });
  }
}

// ── Quick-select chip (Diatonic / All) ───────────────────────────────────────
// web: text-[10px] uppercase font-black text-white/40 bg-white/5 px-3 py-1.5 rounded-lg

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha:0.4),
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );
}

// ── Number-of-questions row (5 discrete buttons) ─────────────────────────────
// web: flex gap-3, each flex-1 py-3 rounded-xl font-black text-sm

class _QuestionRow extends StatelessWidget {
  final List<String> opts;
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onSelect;
  const _QuestionRow({required this.opts, required this.selected, required this.accentColor, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < opts.length; i++) ...[
          if (i > 0) const SizedBox(width: 12), // gap-3
          Expanded(
            child: _QuestionBtn(
              label: opts[i],
              active: opts[i] == selected,
              accentColor: accentColor,
              onTap: () => onSelect(opts[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;
  const _QuestionBtn({required this.label, required this.active, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12), // py-3
      decoration: BoxDecoration(
        color: active ? accentColor.withValues(alpha:0.2) : Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: active ? accentColor.withValues(alpha:0.5) : Colors.white.withValues(alpha:0.05),
          width: 1,
        ),
        boxShadow: null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 14, // text-sm
            fontWeight: FontWeight.w900,
            color: active ? accentColor : Colors.white.withValues(alpha:0.4),
          ),
        ),
      ),
    ),
  );
}

// ── Degree Grid ──────────────────────────────────────────────────────────────

class _DegreeGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool reverse;

  const _DegreeGrid({required this.selected, required this.onToggle, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    // Note→Number shows each enharmonic degree as two distinct buttons.
    final degrees = reverse ? kChromaticDegreesSplit : kChromaticDegrees;
    const cols = 4;
    const gap = 12.0; // web: gap-3
    final cellH = 48.0 * MediaQuery.textScalerOf(context).scale(1); // web: h-12
    final rows = (degrees.length / cols).ceil();
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cw = (constraints.maxWidth - (cols - 1) * gap) / cols;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                // The incomplete last row (e.g. the 3 leftover split degrees)
                // is centered; full rows fill the width exactly.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int c = 0; c < cols && (r * cols + c) < degrees.length; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    SizedBox(
                      width: cw, height: cellH,
                      child: Builder(builder: (_) {
                        final deg = degrees[r * cols + c];
                        final active = selected.contains(deg);
                        final color = AppColors.degreeColors[deg.split('/')[0]] ?? Colors.white;
                        return _DegreeCell(deg: deg, color: color, active: active, onTap: () => onToggle(deg));
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DegreeCell extends StatelessWidget {
  final String deg;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _DegreeCell({required this.deg, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = active;
    final c = color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // No press/illuminate animation — the degree colours instantly on tap.
      child: Container(
        decoration: BoxDecoration(
          // Selected: vivid degree colour + soft glow; unselected: glass tile.
          color: a ? null : Colors.white.withValues(alpha:0.045),
          gradient: a
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(c, Colors.white, 0.18)!, c],
                )
              : null,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color: a ? Colors.white.withValues(alpha:0.18) : Colors.white.withValues(alpha:0.07),
          ),
          boxShadow: a
              ? [BoxShadow(color: c.withValues(alpha:0.35), blurRadius: 14, offset: const Offset(0, 4), spreadRadius: -3)]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deg,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: deg.length > 3 ? 11 : 14, // web: text-sm
                fontWeight: FontWeight.w900,
                color: a ? Colors.white : Colors.white.withValues(alpha:0.3),
                letterSpacing: -0.2,
                shadows: a ? const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1))] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Start Button ─────────────────────────────────────────────────────────────

class _StartBtn extends StatefulWidget {
  final List<Color> gradColors;
  final Color shadowColor;
  final VoidCallback onTap;
  final IconData icon;

  const _StartBtn({required this.gradColors, required this.shadowColor, required this.onTap, this.icon = Icons.play_arrow_rounded});

  @override
  State<_StartBtn> createState() => _StartBtnState();
}

class _StartBtnState extends State<_StartBtn> {
  bool _pressed = false;

  // Near-black ink on a bright accent: readable on any of the setup accents.
  static const _ink = Color(0xE6000000);

  @override
  Widget build(BuildContext context) {
    final base = widget.gradColors.last;
    final light = Color.lerp(base, Colors.white, 0.22)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 60,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [light, base],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(color: widget.shadowColor, blurRadius: 28, offset: const Offset(0, 10), spreadRadius: -4),
              ],
            ),
            child: Stack(children: [
              // Top-edge highlight, same language as the paywall CTA.
              Positioned(
                top: 0, left: 14, right: 14,
                child: Container(height: 1.3, color: Colors.white.withValues(alpha: 0.5)),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: _ink, size: 24),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'START TRAINING',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: _ink,
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
      ),
    );
  }
}
