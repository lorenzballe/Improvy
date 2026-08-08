import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/haptics_service.dart';
import 'note_text.dart';

/// What a tap on the Question widget opens.
///
/// The widget deliberately withholds the answer — that unresolved question is
/// the whole reason it earns a place on a home screen. This is where it
/// resolves: the question restated, the answer revealed on a beat, and a way
/// straight into training that key. Anything less would make the tap feel like
/// a bait.
class QuizRevealModal extends StatefulWidget {
  final String question;
  final String answer;
  final String musicalKey;
  final VoidCallback onClose;
  final VoidCallback onTrainKey;

  const QuizRevealModal({
    super.key,
    required this.question,
    required this.answer,
    required this.musicalKey,
    required this.onClose,
    required this.onTrainKey,
  });

  @override
  State<QuizRevealModal> createState() => _QuizRevealModalState();
}

class _QuizRevealModalState extends State<QuizRevealModal>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFCD34D);

  late final AnimationController _enter;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
    // A held beat before the answer lands: long enough that the eye reads the
    // question first and actually tries to answer it, short enough not to nag.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _revealed = true);
        HapticsService.success();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  bool _closing = false;

  /// Rewinds the entrance so leaving reads as the reverse of arriving instead
  /// of snapping away. Both exits — the backdrop and the button — go through
  /// here, so they leave identically; the flag swallows a second tap during
  /// the wind-back.
  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _enter.animateBack(0.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInCubic);
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: _dismiss,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.62)),
          ),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _enter,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF221830), Color(0xFF141020)],
                  ),
                  border: Border.all(color: _gold.withValues(alpha: 0.32)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20)),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('FROM YOUR HOME SCREEN',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: _goldSoft)),
                  const SizedBox(height: 18),
                  NoteText(
                    note: widget.question,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.62)),
                  ),
                  const SizedBox(height: 10),
                  // The answer arrives on its own beat — before it does, the
                  // space is already reserved, so nothing jumps.
                  SizedBox(
                    height: 74,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 340),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                              scale: Tween<double>(begin: 0.86, end: 1.0)
                                  .animate(CurvedAnimation(
                                      parent: anim, curve: Curves.easeOutBack)),
                              child: child),
                        ),
                        child: _revealed
                            ? NoteText(
                                key: const ValueKey('answer'),
                                note: widget.answer,
                                style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1),
                              )
                            : Text('?',
                                key: const ValueKey('hidden'),
                                style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.14))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      HapticsService.impactMedium();
                      widget.onTrainKey();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFCE7A6), Color(0xFFF7C955), Color(0xFFE8A22B)],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Train ',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2A1B04))),
                            NoteText(
                              note: widget.musicalKey,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2A1B04)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _dismiss,
                    child: Text('Not now',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.45))),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
