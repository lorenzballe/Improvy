import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

import '../constants/app_colors.dart';
import '../widgets/note_text.dart';

/// Three screens between the poster and the app: what a degree is, why the
/// same numbers work in every key, and what the game asks.
///
/// The poster promises "every note is a number" and then, until this
/// existed, dropped the reader onto twelve keys and a daily challenge without
/// ever saying what the number *was*. Someone who already thinks in degrees
/// does not need these; someone who arrived from an advert does, and would
/// otherwise close the app on the first ♭3.
///
/// Swipe or tap through; nothing here is required knowledge to skip.
class ExplainerScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ExplainerScreen({super.key, required this.onDone});

  @override
  State<ExplainerScreen> createState() => _ExplainerScreenState();
}

class _ExplainerScreenState extends State<ExplainerScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _bg = Color(0xFF0F0A1A);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= 2) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          SizedBox(height: pad.top + 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(context.l10n.explainerEyebrow,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        color: Colors.white.withValues(alpha: 0.4))),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onDone,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(context.l10n.skip,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _Page(
                  eyebrow: context.l10n.explainerStep(1),
                  title: context.l10n.explainer1Title,
                  body: context.l10n.explainer1Body,
                  demo: const _ScaleDemo(root: 'C'),
                ),
                _Page(
                  eyebrow: context.l10n.explainerStep(2),
                  title: context.l10n.explainer2Title,
                  body: context.l10n.explainer2Body,
                  demo: const _ScaleDemo(root: 'G'),
                ),
                _Page(
                  eyebrow: context.l10n.explainerStep(3),
                  title: context.l10n.explainer3Title,
                  body: context.l10n.explainer3Body,
                  demo: const _QuestionDemo(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, pad.bottom + 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: i == _index ? 0.9 : 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    height: 58,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_index == 2 ? context.l10n.letsGo : context.l10n.next,
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 17.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF12081C))),
                        const SizedBox(width: 9),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 21, color: Color(0xFF12081C)),
                      ],
                    ),
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

class _Page extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Widget demo;
  const _Page({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.35))),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    height: 1.02,
                    letterSpacing: -1.6,
                    color: Colors.white)),
            const SizedBox(height: 28),
            demo,
            const SizedBox(height: 28),
            Text(body,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
      );
}

/// The seven degrees of a major scale as the coloured strip the poster uses,
/// with the letter under each — so the number and the name sit together.
class _ScaleDemo extends StatelessWidget {
  final String root;
  const _ScaleDemo({required this.root});

  static const _cMajor = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _gMajor = ['G', 'A', 'B', 'C', 'D', 'E', 'F♯'];
  static const _heights = [44.0, 54.0, 64.0, 72.0, 88.0, 66.0, 50.0];

  @override
  Widget build(BuildContext context) {
    final letters = root == 'G' ? _gMajor : _cMajor;
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: _heights[i],
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 9),
                    decoration: BoxDecoration(
                      color: AppColors.degreeColors['${i + 1}'] ?? Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF12081C))),
                  ),
                  const SizedBox(height: 8),
                  // NoteText, not Text: the UI font has no ♯, and F♯ is the one
                  // letter on this page that makes the point.
                  NoteText(
                      note: letters[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One question, drawn the way the trainer draws it.
class _QuestionDemo extends StatelessWidget {
  const _QuestionDemo();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(context.l10n.explainerKeyOf,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.45))),
                NoteText(
                    note: 'E♭',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.45))),
              ],
            ),
            const SizedBox(height: 8),
            Text('5',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 72,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: AppColors.degreeColors['5'])),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final n in ['A♭', 'B♭', 'C']) ...[
                  Expanded(
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: n == 'B♭'
                            ? (AppColors.degreeColors['5'] ?? Colors.white)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: n == 'B♭' ? 0.25 : 0.08)),
                      ),
                      child: NoteText(
                          note: n,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: n == 'B♭'
                                  ? const Color(0xFF12081C)
                                  : Colors.white.withValues(alpha: 0.55))),
                    ),
                  ),
                  if (n != 'C') const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      );
}
