import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../l10n/l10n.dart';
import '../providers/app_provider.dart';
import '../services/haptics_service.dart';
import '../utils/music_engine.dart';
import '../widgets/note_text.dart';

/// The three screens between the poster and the app.
///
/// The poster promises "every note is a number" and used to drop the reader
/// straight onto twelve keys and a daily challenge — without ever saying what
/// the number *was*. Someone who already thinks in degrees does not need this;
/// someone who arrived from an advert does, and would otherwise close the app
/// on the first ♭3.
///
/// These do not explain in prose. They show a keyboard with the numbers on it,
/// let you move the key and watch the numbers stay put, and then hand you a
/// real question to answer. Three screens is the whole of the theory this app
/// needs, and the last of them means nobody reaches the home screen without
/// having played once.
///
/// Each page is the poster's anatomy: a colour field across the top that holds
/// the title and the demonstration and ends, in a 44-point curve, where the
/// explanation starts on the dark base. The field walks the spectrum — gold,
/// violet, cyan — so turning the page is visibly progress.
class ExplainerScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ExplainerScreen({super.key, required this.onDone});

  @override
  State<ExplainerScreen> createState() => _ExplainerScreenState();
}

/// One page's colours: the field, the light pooled in its lower-left corner,
/// and the ink that reads on it.
class _Look {
  final List<Color> field;
  final List<double> stops;
  final Color glow;
  final Color ink;
  final Color pill;
  const _Look(this.field, this.stops, this.glow, this.ink, this.pill);
}

class _ExplainerScreenState extends State<ExplainerScreen> {
  final _pages = PageController();
  int _index = 0;

  /// Page 2's key. Page 1 is always C — one idea at a time.
  String _key = 'C';

  static const _base = Color(0xFF12081C);

  static const _looks = [
    // Gold carries dark ink: white on yellow is the one pairing that fails.
    _Look([Color(0xFFFDE68A), Color(0xFFF5B52A), Color(0xFFC4620F)], [0, 0.46, 1],
        Color(0x61FFFFFF), Color(0xFF2A1B04), Color(0x292A1B04)),
    _Look([Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF4338CA)], [0, 0.48, 1],
        Color(0x6622D3EE), Colors.white, Color(0x38FFFFFF)),
    _Look([Color(0xFF22D3EE), Color(0xFF0EA5E9), Color(0xFF2563EB)], [0, 0.42, 1],
        Color(0x66A3E635), Colors.white, Color(0x38FFFFFF)),
  ];

  /// The three keys page 2 offers. C, G and F: one sharp and one flat away
  /// from home, so the letters visibly move without the reader having to know
  /// what a signature is.
  static const _keyChoices = ['C', 'G', 'F'];

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
        duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final l = context.l10n;
    final look = _looks[_index];
    // Room the fixed controls take at the bottom — the pages scroll clear of it.
    final controlsH = pad.bottom + 24 + 60 + 20 + 6 + 20;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark clock and battery on the gold page, light on the others.
      value: _index == 0 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _base,
        body: Stack(children: [
          PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              // 1 — the claim, drawn. A keyboard in C with the numbers on it.
              _Page(
                look: _looks[0],
                top: pad.top,
                bottom: controlsH,
                step: l.explainerStep(1),
                title: l.explainer1Title,
                body: l.explainer1Body,
                demo: const _Keyboard(musicalKey: 'C'),
              ),
              // 2 — the same keyboard, and the key in the reader's hands.
              _Page(
                look: _looks[1],
                top: pad.top,
                bottom: controlsH,
                step: l.explainerStep(2),
                title: l.explainer2Title,
                body: l.explainer2Body,
                demo: Column(
                  children: [
                    _Keyboard(musicalKey: _key),
                    const SizedBox(height: 16),
                    _KeyPicker(
                      keys: _keyChoices,
                      selected: _key,
                      onSelect: (k) {
                        HapticsService.impactLight();
                        setState(() => _key = k);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(l.explainerTapKey,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              // 3 — a real question, before the home screen ever appears.
              _Page(
                look: _looks[2],
                top: pad.top,
                bottom: controlsH,
                step: l.explainerStep(3),
                title: l.explainer3Title,
                body: l.explainer3Body,
                demo: const _TryIt(),
              ),
            ],
          ),

          // The header stays put while the pages slide under it; its ink
          // follows the page, dark on gold and white after.
          Positioned(
            top: pad.top + 26,
            left: 30,
            right: 30,
            child: Row(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  // Merged, not replaced: the animated style would otherwise
                  // drop the app's font along with the old colour.
                  style: Theme.of(context).textTheme.bodyMedium!.merge(TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                      color: look.ink.withValues(alpha: _index == 0 ? 0.7 : 0.75))),
                  child: Text(l.explainerEyebrow),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onDone,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: look.pill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: Theme.of(context).textTheme.bodyMedium!.merge(TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w500, color: look.ink)),
                      child: Text(l.skip),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dots and the button sit on the dark base, over a short fade so a
          // page scrolled under them on a small phone goes quietly.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(30, 20, 30, pad.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_base.withValues(alpha: 0), _base, _base],
                  stops: const [0, 0.22, 1],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i == _index ? 0.9 : 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_index == 2 ? l.letsGo : l.next,
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w600,
                                  color: _base)),
                          const SizedBox(width: 9),
                          const Icon(Icons.arrow_forward_rounded, size: 21, color: _base),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final _Look look;
  final double top;
  final double bottom;
  final String step;
  final String title;
  final String body;
  final Widget demo;
  const _Page({
    required this.look,
    required this.top,
    required this.bottom,
    required this.step,
    required this.title,
    required this.body,
    required this.demo,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        // Scrolls only when the phone is too short for the page — an SE with
        // the quiz open — and otherwise sits still.
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The field: the step, the title and the demonstration, ending in
            // a curve where the explanation begins.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // 160°, as drawn: from the top-left, a little off vertical.
                    begin: const Alignment(-0.34, -1),
                    end: const Alignment(0.34, 1),
                    colors: look.field,
                    stops: look.stops,
                  ),
                ),
                child: Stack(
                  children: [
                    // The pool of light in the lower-left corner.
                    Positioned(
                      left: -80,
                      bottom: -120,
                      child: Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [look.glow, look.glow.withValues(alpha: 0)],
                            stops: const [0, 0.7],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      // Clear of the status bar and of the fixed header.
                      padding: EdgeInsets.fromLTRB(30, top + 26 + 28 + 26, 30, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.4,
                                  color: look.ink.withValues(alpha: 0.6))),
                          const SizedBox(height: 12),
                          Text(title,
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 44,
                                  fontWeight: FontWeight.w600,
                                  height: 0.98,
                                  letterSpacing: -1.8,
                                  color: look.ink)),
                          const SizedBox(height: 22),
                          demo,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 22, 30, 0),
              child: Text(body,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.82))),
            ),
          ],
        ),
      );
}

/// One octave of a real keyboard, with each scale degree written on the key it
/// falls on — in the reader's own note names — and the five notes between them
/// on the black keys.
///
/// The whole app rests on the claim that a note and a number are the same
/// thing. A bar chart says it; a keyboard with the numbers sitting on the keys
/// *is* it, and it is the same keyboard the trainer shows later.
class _Keyboard extends StatelessWidget {
  final String musicalKey;

  /// A degree to light up — the one just answered correctly. Null the rest of
  /// the time.
  final String? litDegree;

  const _Keyboard({required this.musicalKey, this.litDegree});

  /// The black key after each of these white keys, and the degree it plays.
  static const _black = [(0, '♭2'), (1, '♭3'), (3, '♯4'), (4, '♭6'), (5, '♭7')];

  @override
  Widget build(BuildContext context) {
    final notation = context.select<AppProvider, String>((p) => p.notation);
    final scale = calculateMajorScale(musicalKey);

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1826),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0xCC000000), blurRadius: 50, spreadRadius: -18, offset: Offset(0, 24)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          child: LayoutBuilder(builder: (context, c) {
            final kw = c.maxWidth / 7;
            final bw = kw * 0.64;
            return Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _WhiteKey(
                          degree: '${i + 1}',
                          note: scale[i],
                          notation: notation,
                          divider: i > 0,
                          lit: litDegree == '${i + 1}',
                        ),
                      ),
                  ],
                ),
                for (final (after, degree) in _black)
                  Positioned(
                    left: kw * (after + 1) - bw / 2,
                    top: 0,
                    width: bw,
                    height: 118,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2433),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                        boxShadow: [BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 6))],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: NoteText(
                          note: formatNoteForDisplay(
                              getNoteFromChromaticDegree(degree, scale, musicalKey), notation),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.degreeColors[degree] ?? Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final String degree;
  final String note;
  final String notation;
  final bool divider;
  final bool lit;
  const _WhiteKey({
    required this.degree,
    required this.note,
    required this.notation,
    required this.divider,
    this.lit = false,
  });

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.degreeColors[degree] ?? Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        // The answered key takes a wash of its degree's own colour — the same
        // colour the number has worn since page one.
        color: lit ? Color.lerp(Colors.white, colour, 0.28) : Colors.white,
        border: divider
            ? const Border(left: BorderSide(color: Color(0xFFD9D6E0)))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(degree,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  // The 5's blue is the one fill dark ink cannot sit on.
                  color: degree == '5' ? Colors.white : const Color(0xFF1B1826),
                )),
          ),
          const SizedBox(height: 10),
          // The letter changes with the key; the number never does. Animating
          // only the letter is what makes page 2 land.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: FittedBox(
              key: ValueKey(note),
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: NoteText(
                  note: formatNoteForDisplay(note, notation),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colour),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyPicker extends StatelessWidget {
  final List<String> keys;
  final String selected;
  final ValueChanged<String> onSelect;
  const _KeyPicker({
    required this.keys,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final notation = context.select<AppProvider, String>((p) => p.notation);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final k in keys) ...[
          GestureDetector(
            onTap: () => onSelect(k),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 56),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k == selected
                    ? (AppColors.noteColors[k] ?? Colors.white)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: k == selected
                      ? (AppColors.noteColors[k] ?? Colors.white)
                      : Colors.white.withValues(alpha: 0.16),
                ),
                boxShadow: k == selected
                    ? [
                        BoxShadow(
                          color: (AppColors.noteColors[k] ?? Colors.white).withValues(alpha: 0.8),
                          blurRadius: 24,
                          spreadRadius: -10,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: NoteText(
                note: formatNoteForDisplay(k, notation),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: k == selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          if (k != keys.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

/// One real question, played before the home screen has ever been seen.
///
/// Deliberately the app's own game rather than a picture of it: three answers,
/// the right one lights, the wrong one says so and lets you try again. Nobody
/// arrives at the home screen without having done this once.
class _TryIt extends StatefulWidget {
  const _TryIt();

  @override
  State<_TryIt> createState() => _TryItState();
}

class _TryItState extends State<_TryIt> {
  // Three easy questions, in order. Each is a key and a degree whose answer is
  // a natural note, so the first thing anyone ever answers is not an accidental.
  static const _questions = [
    ('C', '5'),
    ('G', '3'),
    ('F', '2'),
  ];

  /// The degree in the question. Gold rather than the degree's own colour:
  /// the 5's blue would vanish into the blue field around it.
  static const _accent = Color(0xFFFFDB4D);

  int _q = 0;
  String? _picked;

  ({String key, String degree, String answer, List<String> options}) get _current {
    final (key, degree) = _questions[_q];
    final scale = calculateMajorScale(key);
    final answer = scale[int.parse(degree) - 1];
    // Two neighbours from the same scale: wrong, but plausibly so — a random
    // note from anywhere would make the question easier than the real thing.
    final idx = int.parse(degree) - 1;
    final options = <String>{
      answer,
      scale[(idx + 1) % 7],
      scale[(idx + 5) % 7],
    }.toList()
      ..sort((a, b) => (kNoteToSemitone[a] ?? 0).compareTo(kNoteToSemitone[b] ?? 0));
    return (key: key, degree: degree, answer: answer, options: options);
  }

  void _pick(String note) {
    if (_picked == _current.answer) return; // already solved
    setState(() => _picked = note);
    if (note == _current.answer) {
      HapticsService.success();
    } else {
      HapticsService.error();
    }
  }

  void _again() {
    setState(() {
      _q = (_q + 1) % _questions.length;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final notation = context.select<AppProvider, String>((p) => p.notation);
    final q = _current;
    final solved = _picked == q.answer;

    return Column(
      children: [
        // The same keyboard as the first two pages, in the question's key. Get
        // it right and the key lights: the number, the letter and the sound of
        // "that's it" land on one object.
        _Keyboard(musicalKey: q.key, litDegree: solved ? q.degree : null),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(
                      fontSize: 15.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9)),
                  children: _questionSpans(
                      l.explainerQuestion(formatNoteForDisplay(q.key, notation), q.degree),
                      q.degree),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final n in q.options) ...[
                    Expanded(
                        child: _AnswerButton(
                      note: n,
                      notation: notation,
                      state: _picked == null
                          ? _AnswerState.idle
                          : n == q.answer && (solved || _picked == n)
                              ? _AnswerState.right
                              : _picked == n
                                  ? _AnswerState.wrong
                                  : _AnswerState.idle,
                      onTap: () => _pick(n),
                    )),
                    if (n != q.options.last) const SizedBox(width: 12),
                  ],
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _picked == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: solved
                            ? GestureDetector(
                                onTap: _again,
                                behavior: HitTestBehavior.opaque,
                                // Scaled, not clipped: "Esatto." plus "Un'altra"
                                // is already wider than a narrow phone, and some
                                // translations are wider still.
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 16, color: Color(0xFFBBF7D0)),
                                      const SizedBox(width: 7),
                                      Text('${l.explainerRight}  ',
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFBBF7D0))),
                                      Text(l.explainerAgain,
                                          maxLines: 1,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                              decorationColor:
                                                  Colors.white.withValues(alpha: 0.5),
                                              color: Colors.white.withValues(alpha: 0.75))),
                                    ],
                                  ),
                                ),
                              )
                            : Text(l.explainerWrong,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFECDD3))),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Colours the degree where it appears in the sentence, wherever the
  /// translation happens to put it.
  static List<InlineSpan> _questionSpans(String sentence, String degree) {
    final i = sentence.lastIndexOf(degree);
    if (i < 0) return [TextSpan(text: sentence)];
    return [
      TextSpan(text: sentence.substring(0, i)),
      TextSpan(
          text: degree,
          style: const TextStyle(
              fontFamily: 'Outfit', color: _accent, fontWeight: FontWeight.w700)),
      TextSpan(text: sentence.substring(i + degree.length)),
    ];
  }
}

enum _AnswerState { idle, right, wrong }

class _AnswerButton extends StatelessWidget {
  final String note;
  final String notation;
  final _AnswerState state;
  final VoidCallback onTap;
  const _AnswerButton({
    required this.note,
    required this.notation,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _AnswerState.right => (
          const Color(0xFF34D399),
          const Color(0xFF04301F),
          const Color(0xFF34D399)
        ),
      _AnswerState.wrong => (
          const Color(0x40F43F5E),
          Colors.white,
          const Color(0x99FB7185)
        ),
      _AnswerState.idle => (
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.16)
        ),
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: NoteText(
          note: formatNoteForDisplay(note, notation),
          style: TextStyle(
              fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}
