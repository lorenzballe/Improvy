import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/key_progress.dart';
import '../constants/app_colors.dart';
import '../constants/levels.dart';
import '../widgets/note_text.dart';
import '../widgets/animal_icon.dart';

class SessionSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final List<KeyProgress> progressData;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final void Function(int newDiff) onNextDifficulty;

  const SessionSummaryScreen({
    super.key,
    required this.sessionData,
    required this.progressData,
    required this.onRetry,
    required this.onBack,
    required this.onNextDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final key     = sessionData['key']        as String? ?? 'C';
    final mode    = sessionData['mode']       as String? ?? 'diatonic';
    final correct = sessionData['correct']    as int?    ?? 0;
    final total   = sessionData['total']      as int?    ?? 0;
    final time    = sessionData['time']       as int?    ?? 0;
    final diff    = sessionData['difficulty'] as int?    ?? 1;
    final errors  = total - correct;
    final acc     = total > 0 ? (correct / total * 100).round() : 0;
    final passed  = errors <= 3;
    final perfect = errors == 0;
    final hasNext = diff < 3;
    final isCustom = mode == 'custom' || mode == 'note-to-number';
    final isDiat  = mode == 'diatonic';

    final diffLabels = ['Apprentice', 'Virtuoso', 'Maestro'];
    final modeLabel  = isDiat ? 'Diatonic' : (mode == 'chromatic' ? 'Chromatic' : mode);

    // Accent colour: gold > green > red
    final accentColor = perfect
        ? const Color(0xFFEAB308)
        : passed
            ? const Color(0xFF10B981)
            : const Color(0xFFF43F5E);
    final modeColor = isDiat ? const Color(0xFF3B82F6) : const Color(0xFFA855F7);

    // Mastery
    final keyData  = progressData.firstWhere((k) => k.key == key, orElse: () => KeyProgress(key: key));
    final modePct  = (isDiat ? keyData.diatonicProgress : keyData.chromaticProgress).toDouble();
    final animal   = getAnimalLevel(modePct);

    // Time formatting
    final mins = time ~/ 60;
    final secs = (time % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Background atmosphere
        Positioned(
          top: -120, left: -80,
          child: _Blob(size: 320, color: accentColor.withOpacity(0.07)),
        ),
        Positioned(
          bottom: -60, right: -60,
          child: _Blob(size: 240, color: modeColor.withOpacity(0.06)),
        ),

        SafeArea(
          child: Column(children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                _BackBtn(onTap: onBack),
                Expanded(
                  child: Column(children: [
                    Text(
                      'SESSION COMPLETE',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.35), letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NoteText(
                          note: key,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.7)),
                        ),
                        Text(
                          ' · $modeLabel · ${diffLabels[(diff - 1).clamp(0, 2)]}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(width: 40),
              ]),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(children: [
                  const SizedBox(height: 36),

                  // ── Hero: accuracy ───────────────────────────────────
                  ShaderMask(
                    shaderCallback: (b) {
                      if (perfect) {
                        return const LinearGradient(
                          colors: [Color(0xFFEAB308), Color(0xFFFBBF24)],
                        ).createShader(b);
                      }
                      if (passed) {
                        return const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                        ).createShader(b);
                      }
                      return const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
                      ).createShader(b);
                    },
                    child: Text(
                      '$acc',
                      style: const TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -5,
                        height: 1,
                      ),
                    ),
                  ),
                  Text(
                    'ACCURACY %',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.3), letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Result badge ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
                      boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          perfect ? Icons.auto_awesome_rounded
                              : passed ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: accentColor, size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          perfect ? 'PERFECT SCORE'
                              : passed
                                  ? (isCustom || !hasNext ? 'COMPLETED' : 'LEVEL PASSED')
                                  : 'NOT YET — KEEP GOING',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900,
                            color: accentColor, letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Stats row ─────────────────────────────────────────
                  Row(children: [
                    Expanded(child: _StatTile(
                      label: 'CORRECT',
                      value: '$correct/$total',
                      icon: Icons.check_rounded,
                      color: accentColor,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(
                      label: 'ERRORS',
                      value: '$errors',
                      icon: Icons.close_rounded,
                      color: errors == 0
                          ? const Color(0xFF10B981)
                          : errors <= 3
                              ? const Color(0xFFEAB308)
                              : const Color(0xFFF43F5E),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(
                      label: 'TIME',
                      value: '$mins:$secs',
                      icon: Icons.timer_outlined,
                      color: Colors.white.withOpacity(0.5),
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // ── Mastery card ──────────────────────────────────────
                  if (!isCustom)
                    _MasteryCard(
                      animal: animal,
                      modeProgress: modePct,
                      modeColor: modeColor,
                      passed: passed,
                      hasNext: hasNext,
                      difficulty: diff,
                    ),

                  const SizedBox(height: 32),
                ]),
              ),
            ),

            // ── Bottom actions ────────────────────────────────────────────
            _BottomActions(
              passed: passed,
              hasNext: hasNext,
              isCustom: isCustom,
              modeColor: modeColor,
              accentColor: accentColor,
              difficulty: diff,
              onRetry: onRetry,
              onBack: onBack,
              onNextDifficulty: onNextDifficulty,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Background blob ────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: SizedBox(
          width: size + 140,
          height: size + 140,
          child: Center(
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ),
      );
}

// ── Back button ────────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
        ),
      );
}

// ── Stat tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.3), letterSpacing: 1.5),
            ),
          ],
        ),
      );
}

// ── Mastery card ───────────────────────────────────────────────────────────────

class _MasteryCard extends StatelessWidget {
  final AnimalLevel animal;
  final double modeProgress;
  final Color modeColor;
  final bool passed;
  final bool hasNext;
  final int difficulty;
  const _MasteryCard({
    required this.animal, required this.modeProgress, required this.modeColor,
    required this.passed, required this.hasNext, required this.difficulty,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: animal.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: animal.color.withOpacity(0.3)),
                ),
                child: Center(child: AnimalIcon(name: animal.name, color: animal.color, size: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODE MASTERY',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.3), letterSpacing: 2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      animal.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
              Text(
                '${modeProgress.round()}%',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: animal.color, letterSpacing: -0.5),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(99),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (modeProgress / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [animal.color, animal.color.withOpacity(0.6)]),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [BoxShadow(color: animal.color.withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Bottom actions ─────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool passed;
  final bool hasNext;
  final bool isCustom;
  final Color modeColor;
  final Color accentColor;
  final int difficulty;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final void Function(int) onNextDifficulty;

  const _BottomActions({
    required this.passed, required this.hasNext, required this.isCustom,
    required this.modeColor, required this.accentColor, required this.difficulty,
    required this.onRetry, required this.onBack, required this.onNextDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          // Primary: next difficulty (if passed and applicable)
          if (passed && hasNext && !isCustom) ...[
            _PrimaryBtn(
              label: 'PLAY NEXT DIFFICULTY',
              icon: Icons.arrow_forward_rounded,
              gradColors: [modeColor, modeColor.withOpacity(0.7)],
              shadowColor: modeColor.withOpacity(0.4),
              onTap: () => onNextDifficulty(difficulty + 1),
            ),
            const SizedBox(height: 10),
          ],
          // Secondary row: Retry + Back
          Row(children: [
            Expanded(child: _SecondaryBtn(label: 'RETRY', icon: Icons.replay_rounded, onTap: onRetry)),
            const SizedBox(width: 10),
            Expanded(child: _SecondaryBtn(label: 'HOME', icon: Icons.home_rounded, onTap: onBack)),
          ]),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradColors;
  final Color shadowColor;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.icon, required this.gradColors, required this.shadowColor, required this.onTap});

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradColors, begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: widget.shadowColor, blurRadius: 28, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                const SizedBox(width: 10),
                Icon(widget.icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      );
}

class _SecondaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryBtn({required this.label, required this.icon, required this.onTap});

  @override
  State<_SecondaryBtn> createState() => _SecondaryBtnState();
}

class _SecondaryBtnState extends State<_SecondaryBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white.withOpacity(0.5), size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      );
}
