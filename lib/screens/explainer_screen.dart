import 'package:flutter/material.dart';
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
class ExplainerScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ExplainerScreen({super.key, required this.onDone});

  @override
  State<ExplainerScreen> createState() => _ExplainerScreenState();
}

class _ExplainerScreenState extends State<ExplainerScreen> {
  final _pages = PageController();
  int _index = 0;

  /// Page 2's key. Page 1 is always C — one idea at a time.
  String _key = 'C';

  static const _bg = Color(0xFF0F0A1A);

  /// One colour field per page, in the poster's own idiom: a four-stop
  /// diagonal wash with a warm pool of light bleeding in from a corner.
  ///
  /// The poster hands over on a red-to-violet field and these three used to
  /// drop straight onto flat near-black, so the handover read as the app
  /// failing to load rather than as three more pages of the same piece. Each
  /// walks the spectrum further round — red-violet, violet-blue, blue-green —
  /// so turning the page is visibly progress.
  static const _fields = [
    LinearGradient(
      begin: Alignment(-0.584, -1.105),
      end: Alignment(0.584, 1.105),
      colors: [Color(0xFFFF6B5A), Color(0xFFE23B7B), Color(0xFF9333EA), Color(0xFF5B21B6)],
      stops: [0.0, 0.38, 0.74, 1.0],
    ),
    LinearGradient(
      begin: Alignment(-0.584, -1.105),
      end: Alignment(0.584, 1.105),
      colors: [Color(0xFFA855F7), Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF1E3A8A)],
      stops: [0.0, 0.36, 0.72, 1.0],
    ),
    // Cool all the way down, with no green in it: the third page is the one
    // with a green "that's it" on it, and a green field underneath took the
    // punch out of the only moment on these three screens that is a reward.
    LinearGradient(
      begin: Alignment(-0.584, -1.105),
      end: Alignment(0.584, 1.105),
      colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9), Color(0xFF4F46E5), Color(0xFF1E1B4B)],
      stops: [0.0, 0.34, 0.7, 1.0],
    ),
  ];

  /// The corner light, one per field: gold under the warm page, cyan under
  /// the cool one, chartreuse under the green.
  static const _glows = [
    Color(0xFFFFDB4D),
    Color(0xFF67E8F9),
    Color(0xFF5EEAD4),
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
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // Crossfaded rather than switched: the page slides under the reader's
        // thumb, and a hard cut between two fields mid-drag reads as a flash.
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: _ColourField(
              key: ValueKey(_index),
              gradient: _fields[_index],
              glow: _glows[_index],
            ),
          ),
        ),
        Column(
          children: [
          SizedBox(height: pad.top + 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                    Text(l.explainerEyebrow,
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
                        child: Text(l.skip,
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
                    // 1 — the claim, drawn. A keyboard in C with the numbers on it.
                    _Page(
                      eyebrow: l.explainerStep(1),
                      title: l.explainer1Title,
                      body: l.explainer1Body,
                      demo: const _Keyboard(musicalKey: 'C'),
                    ),
                    // 2 — the same keyboard, and the key in the reader's hands.
                    _Page(
                      eyebrow: l.explainerStep(2),
                      title: l.explainer2Title,
                      body: l.explainer2Body,
                      demo: Column(
                        children: [
                          _Keyboard(musicalKey: _key),
                          const SizedBox(height: 18),
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
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white.withValues(alpha: 0.3))),
                        ],
                      ),
                    ),
                    // 3 — a real question, before the home screen ever appears.
                    _Page(
                      eyebrow: l.explainerStep(3),
                      title: l.explainer3Title,
                      body: l.explainer3Body,
                      demo: const _TryIt(),
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
                            Text(_index == 2 ? l.letsGo : l.next,
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
      ]),
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          // Centred in the space it has, and scrollable when it runs out: a
          // short page used to leave a third of the screen empty under the
          // text, which read as something failing to load.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(eyebrow,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.35))),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    height: 1.04,
                    letterSpacing: -1.4,
                    color: Colors.white)),
            const SizedBox(height: 26),
            demo,
            const SizedBox(height: 26),
            Text(body,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w300,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    ),
  );
}

/// One octave of a real keyboard, with each scale degree written on the key it
/// falls on — in the reader's own note names.
///
/// The whole app rests on the claim that a note and a number are the same
/// thing. A bar chart says it; a keyboard with the numbers sitting on the keys
/// *is* it, and it is the same keyboard the trainer will show later.
class _Keyboard extends StatelessWidget {
  final String musicalKey;

  /// A degree to light up — the one just answered correctly. Null the rest of
  /// the time.
  final String? litDegree;

  const _Keyboard({required this.musicalKey, this.litDegree});

  /// Where the five black keys sit, as a fraction of the seven white ones.
  static const _blackAfter = [0, 1, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final notation = context.select<AppProvider, String>((p) => p.notation);
    final scale = calculateMajorScale(musicalKey);

    return LayoutBuilder(builder: (context, c) {
      // The keys sit in a rounded bed rather than running off the edges: the
      // corners read as an instrument instead of a sawn-off rectangle.
      const h = 132.0;
      const pad = 6.0;
      const whiteCount = 7;
      final inner = c.maxWidth - pad * 2;
      final kw = inner / whiteCount;
      final kh = h - pad * 2;
      final bw = kw * 0.62;

      return SizedBox(
        height: h,
        child: Container(
          padding: const EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: const Color(0xFF17131F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < whiteCount; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == whiteCount - 1 ? 0 : 3),
                        child: _WhiteKey(
                          degree: '${i + 1}',
                          note: scale[i],
                          notation: notation,
                          lit: litDegree == '${i + 1}',
                        ),
                      ),
                    ),
                ],
              ),
              // Black keys carry no degree here: the seven of the scale are the
              // idea, and five unlabelled keys are exactly the right amount of
              // "there is more later".
              for (final i in _blackAfter)
                Positioned(
                  left: kw * (i + 1) - bw / 2 - 1.5,
                  top: 0,
                  width: bw,
                  height: kh * 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF241E31),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                        bottom: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.55)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _WhiteKey extends StatelessWidget {
  final String degree;
  final String note;
  final String notation;
  final bool lit;
  const _WhiteKey({
    required this.degree,
    required this.note,
    required this.notation,
    this.lit = false,
  });

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.degreeColors[degree] ?? Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        // The answered key takes its degree's own colour — the same colour the
        // number has worn since page one.
        color: lit ? colour : const Color(0xFFF4F1F8),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
          bottom: Radius.circular(10),
        ),
        boxShadow: lit
            ? [BoxShadow(color: colour.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: -2)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
              child: NoteText(
                note: formatNoteForDisplay(note, notation),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: lit ? const Color(0xFF12081C) : const Color(0xFF6C6580),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
                color: lit ? Colors.white : colour, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(degree,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF12081C),
                )),
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: k == selected
                    ? (AppColors.noteColors[k] ?? Colors.white)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: k == selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: NoteText(
                note: formatNoteForDisplay(k, notation),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: k == selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          if (k != keys.last) const SizedBox(width: 10),
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
    final colour = AppColors.degreeColors[q.degree] ?? Colors.white;

    return Column(
      children: [
        // The same keyboard as the first two pages, in the question's key. Get
        // it right and the key lights: the number, the letter and the sound of
        // "that's it" land on one object.
        _Keyboard(musicalKey: q.key, litDegree: solved ? q.degree : null),
        const SizedBox(height: 18),
        Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // The question, in words, with the degree carrying its own colour —
          // the same colour it wears on the keyboard above and in the game.
          Text.rich(
            TextSpan(
              style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75)),
              children: _questionSpans(
                  l.explainerQuestion(formatNoteForDisplay(q.key, notation), q.degree),
                  q.degree,
                  colour),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final n in q.options) ...[
                Expanded(child: _AnswerButton(
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
                if (n != q.options.last) const SizedBox(width: 10),
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
                                      size: 16, color: Color(0xFF34D399)),
                                  const SizedBox(width: 7),
                                  Text('${l.explainerRight}  ',
                                      maxLines: 1,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF34D399))),
                                  Text(l.explainerAgain,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              Colors.white.withValues(alpha: 0.4),
                                          color: Colors.white.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          )
                        : Text(l.explainerWrong,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFB7185))),
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
  static List<InlineSpan> _questionSpans(String sentence, String degree, Color c) {
    final i = sentence.indexOf(degree);
    if (i < 0) return [TextSpan(text: sentence)];
    return [
      TextSpan(text: sentence.substring(0, i)),
      TextSpan(
          text: degree,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w900, fontSize: 17)),
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
          const Color(0x33F43F5E),
          const Color(0xFFFB7185),
          const Color(0x66F43F5E)
        ),
      _AnswerState.idle => (
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.1)
        ),
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: NoteText(
          note: formatNoteForDisplay(note, notation),
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }
}

/// The poster's colour field, reused: a four-stop diagonal wash with a soft
/// pool of warm light in one corner, rounded off at the bottom the way the
/// poster's is.
class _ColourField extends StatelessWidget {
  final Gradient gradient;
  final Color glow;
  const _ColourField({super.key, required this.gradient, required this.glow});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            // Bottom-left, as on the poster: it lifts the corner the content
            // does not use and keeps the field from reading as flat colour.
            Positioned(
              left: -90,
              bottom: -140,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glow.withValues(alpha: 0.4), glow.withValues(alpha: 0)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // A wash of the page's own darkness over the lower half: the body
            // text and the white button need somewhere quiet to sit, and the
            // bare field left them fighting the gradient.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F0A1A).withValues(alpha: 0.10),
                      const Color(0xFF0F0A1A).withValues(alpha: 0.62),
                      const Color(0xFF0F0A1A).withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
