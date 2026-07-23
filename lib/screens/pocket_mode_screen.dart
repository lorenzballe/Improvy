import 'dart:async';
import 'dart:math' show Random, min;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../services/tts_service.dart';
import '../services/haptics_service.dart';
import '../utils/music_engine.dart';
import '../widgets/note_text.dart';

/// Everything Pocket Mode needs to run, chosen on its setup screen.
class PocketConfig {
  final String key; // ignored when [shuffleKeys] is true
  final List<String> degrees; // chromatic-degree strings, e.g. '1','♭3','♯4'
  final int delayMs; // pause between the question and its spoken answer
  final int questions; // 0 = continuous (loop until the user stops)
  final bool shuffleKeys; // pick a random key for every question

  const PocketConfig({
    required this.key,
    required this.degrees,
    required this.delayMs,
    required this.questions,
    required this.shuffleKeys,
  });
}

/// Hands-free audio trainer. A voice says a degree ("flat three of C"), waits a
/// few seconds, then speaks the answer ("E flat"), looping. Built to keep going
/// with the screen locked (iOS playback audio session + background audio mode).
class PocketModeScreen extends StatefulWidget {
  final PocketConfig config;
  final String notation; // app's note-naming setting, for the key badge
  final VoidCallback onExit;
  const PocketModeScreen({super.key, required this.config, this.notation = 'CDE', required this.onExit});

  @override
  State<PocketModeScreen> createState() => _PocketModeScreenState();
}

class _PocketModeScreenState extends State<PocketModeScreen> with TickerProviderStateMixin {
  static const _accent = Color(0xFF6366F1); // indigo — Pocket Mode's colour

  final TtsService _tts = TtsService();
  final Random _rng = Random();
  late final AnimationController _pulse;    // slow ambient breathing behind the stage
  late final AnimationController _reveal;   // one-shot bloom when the answer lands
  late final AnimationController _countdown; // smooth 1→0 sweep for the thinking ring

  // A monotonically increasing token: bumping it invalidates any loop iteration
  // still awaiting, so pause / exit stop cleanly mid-utterance or mid-wait.
  int _gen = 0;
  bool _playing = false;
  bool _finished = false;

  int _index = 0; // questions completed
  int _phase = 0; // 0 idle · 1 asking · 2 thinking (countdown) · 3 answering
  String _key = '';
  String _degree = ''; // base degree — drives the answer note + colour
  String _presented = ''; // label actually spoken/shown (may be the extension)
  String _answer = '';
  String? _prevDegree;
  String _spokenKey = ''; // last key the voice named, to avoid repeating it

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _countdown = AnimationController(vsync: this, duration: const Duration(seconds: 1), value: 0);
    _tts.warmUp(); // init the audio session/voice before the first question
    // Auto-start: the user already pressed Start on the setup screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _gen++;
    _tts.stop();
    _pulse.dispose();
    _reveal.dispose();
    _countdown.dispose();
    super.dispose();
  }

  // ── Speech text ────────────────────────────────────────────────────────────

  static const _numberWords = {
    '1': 'one', '2': 'two', '3': 'three', '4': 'four',
    '5': 'five', '6': 'six', '7': 'seven',
    '9': 'nine', '11': 'eleven', '13': 'thirteen',
  };

  // A degree and the upper-structure extension that names the SAME note an
  // octave up (2↔9, 4↔11, 6↔13, plus the altered ♭9/♯9/♯11/♭13). In-game the
  // voice asks either name at random, so both must feel familiar; the answer
  // note is identical either way, so it's always computed from the base degree.
  static const _extensionOf = {
    '♭2': '♭9', '2': '9', '♭3/♯2': '♯9',
    '4': '11', '♯4/♭5': '♯11', '♭6/♯5': '♭13', '6': '13',
  };

  // Notes are named in the app's chosen notation (C D E… or Do Re Mi…) for
  // both the voice and the screen, then accidentals become spoken words.
  String _spokenNote(String n) => formatNoteForDisplay(n, widget.notation)
      .replaceAll('♭', ' flat')
      .replaceAll('♯', ' sharp')
      .trim();

  String _spokenDegree(String d) {
    var s = d.split('/').first;
    final flat = s.contains('♭');
    final sharp = s.contains('♯');
    s = s.replaceAll('♭', '').replaceAll('♯', '');
    final word = _numberWords[s] ?? s;
    return '${flat ? 'flat ' : sharp ? 'sharp ' : ''}$word';
  }

  String _questionSpeech(String degree, String key) =>
      '${_spokenDegree(degree)} of ${_spokenNote(key)}';

  // ── Loop control ───────────────────────────────────────────────────────────

  String _pickDegree() {
    final degs = widget.config.degrees;
    if (degs.length == 1) return degs.first;
    String d;
    do {
      d = degs[_rng.nextInt(degs.length)];
    } while (d == _prevDegree);
    return d;
  }

  void _togglePlay() {
    HapticsService.impactLight();
    if (_playing) {
      _pause();
    } else {
      if (_finished) {
        setState(() { _finished = false; _index = 0; });
      }
      _play();
    }
  }

  void _play() {
    setState(() => _playing = true);
    final gen = ++_gen;
    _loop(gen);
  }

  void _pause() {
    _gen++; // invalidate the running loop
    _tts.stop();
    _countdown.stop();
    _spokenKey = ''; // re-announce the key on the first question after resuming
    setState(() { _playing = false; _phase = 0; });
  }

  void _exit() {
    _gen++;
    _tts.stop();
    widget.onExit();
  }

  // Generous estimate of how long an utterance takes at the configured rate.
  // The loop paces itself off this instead of waiting for the engine to report
  // completion — some web/TTS engines never fire that event, which would freeze
  // the loop. Better a touch long (a natural pause) than cut off.
  int _speechMs(String phrase) {
    final n = phrase.split(' ').where((w) => w.isNotEmpty).length;
    return 500 + n * 480;
  }

  Future<void> _loop(int gen) async {
    final total = widget.config.questions;
    while (mounted && gen == _gen && (total == 0 || _index < total)) {
      final key = widget.config.shuffleKeys ? kAllKeys[_rng.nextInt(kAllKeys.length)] : widget.config.key;
      final degree = _pickDegree();
      // For degrees with an octave-up name (6/13, 2/9, …) the voice asks either
      // form at random; the answer note is the same, computed from the base.
      final ext = _extensionOf[degree];
      final presented = (ext != null && _rng.nextBool()) ? ext : degree;
      final scale = calculateMajorScale(key);
      final answer = getNoteFromChromaticDegree(degree, scale, key);
      if (gen != _gen || !mounted) return;

      // Ask. On a fixed key the voice names the key only when it changes (the
      // first question, or after a resume) and then speaks just the degree, so
      // it isn't repeating "of C" every time. Shuffling always names the key.
      final sameKeyContext = !widget.config.shuffleKeys && key == _spokenKey;
      final qText = sameKeyContext ? _spokenDegree(presented) : _questionSpeech(presented, key);
      _spokenKey = key;
      // Speech is fired without awaiting completion; _wait drives the pace so
      // the loop can never stall on an engine that never reports "done".
      setState(() { _key = key; _degree = degree; _presented = presented; _answer = ''; _phase = 1; });
      _tts.speak(qText);
      if (!await _wait(_speechMs(qText), gen)) return;

      // Think — a smooth 1→0 ring sweep over the delay (60fps, not stepped).
      setState(() => _phase = 2);
      _countdown.duration = Duration(milliseconds: widget.config.delayMs);
      _countdown.reverse(from: 1.0);
      if (!await _wait(widget.config.delayMs, gen)) return;

      // Reveal on screen + speak the answer.
      final aText = _spokenNote(answer);
      setState(() { _answer = answer; _phase = 3; });
      _reveal.forward(from: 0); // bloom ripple
      HapticsService.impactLight();
      _tts.speak(aText);
      if (!await _wait(_speechMs(aText) + 800, gen)) return;

      _prevDegree = degree;
      if (mounted) setState(() => _index++);
    }
    if (mounted && gen == _gen) {
      _tts.speak('Session complete.');
      setState(() { _playing = false; _finished = true; _phase = 0; });
    }
  }

  /// Interruptible pace timer: waits [ms] but bails the moment the generation
  /// token changes (pause/exit). Visuals are driven by the animation
  /// controllers, so this no longer calls setState. Returns false if interrupted.
  Future<bool> _wait(int ms, int gen) async {
    var left = ms;
    const step = 60;
    while (left > 0) {
      if (gen != _gen || !mounted) return false;
      await Future<void>.delayed(const Duration(milliseconds: step));
      left -= step;
    }
    return gen == _gen && mounted;
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = widget.config.questions;
    final noteColor = AppColors.noteColors[_answer] ?? Colors.white;
    final degColor = AppColors.degreeColors[_degree.split('/').first] ?? _accent;
    // The mode's live accent: indigo while asking/thinking, the note's colour
    // on the reveal — it tints the ambient wash.
    final live = _phase == 3 ? noteColor : _accent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _exit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(children: [
          // Phase-reactive ambient wash: a soft radial glow behind the stage.
          // The gradient is painted once (per phase) and only its opacity
          // breathes, so it isn't regenerated/repainted every frame.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Opacity(opacity: 0.62 + 0.38 * Curves.easeInOut.transform(_pulse.value), child: child),
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.25),
                      radius: 0.95,
                      colors: [live.withValues(alpha: 0.16), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: -90, right: -70, child: _blob(300, _accent.withValues(alpha: 0.10))),
          Positioned(bottom: -80, left: -60, child: _blob(260, live.withValues(alpha: 0.10))),
          SafeArea(
            child: Column(children: [
              // ── Top bar (same as every training screen) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: _exit,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10, width: 1.2),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                  const Expanded(
                    child: Text('POCKET MODE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                  ),
                  _keyBadge(),
                ]),
              ),
              const SizedBox(height: 12),
              // ── Session card — the app's signature frosted card: a gradient
              // progress bar over a stat row, exactly like the trainer's. ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: const Color(0x1A1A1625),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white10, width: 1.2),
                  ),
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LayoutBuilder(builder: (ctx, bc) => Stack(children: [
                        Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                        Container(
                          height: 6,
                          width: total == 0 ? bc.maxWidth : bc.maxWidth * (_index / total).clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: total == 0
                                  ? [const Color(0x2260A5FA), const Color(0x22EC4899)]
                                  : const [Color(0xFF60A5FA), Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            boxShadow: total == 0 ? null : const [BoxShadow(color: Color(0x66A855F7), blurRadius: 12)],
                          ),
                        ),
                      ])),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _stat('DEGREES', '${widget.config.degrees.length}')),
                      Container(width: 1, height: 28, color: Colors.white10),
                      Expanded(child: _stat('DELAY', '${(widget.config.delayMs / 1000).round()}s')),
                      Container(width: 1, height: 28, color: Colors.white10),
                      Expanded(child: _stat('SESSION', total == 0 ? '∞' : '${_index.clamp(0, total)}/$total')),
                    ]),
                  ]),
                ),
              ),

              // ── Question: the big degree number, like the trainer's ──
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _questionArea(degColor, noteColor),
                  ),
                ),
              ),

              // ── Answer board: the in-game piano; the answer key lights up. ──
              _keyboard(),

              const SizedBox(height: 12),

              // ── Playback bar (glass, app-style) ──
              _playBar(),
              SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
            ]),
          ),
        ]),
      ),
    );
  }

  // The 12 chromatic roots, shown as the answer board.

  Widget _questionArea(Color degColor, Color noteColor) {
    final statusText = switch (_phase) {
      1 => 'LISTEN',
      2 => 'YOUR TURN',
      3 => 'ANSWER',
      _ => _finished ? 'SESSION COMPLETE' : 'READY',
    };
    final statusColor = _phase == 3 ? noteColor : _accent;
    return LayoutBuilder(builder: (ctx, c) {
      // Fit the ring to whatever room the Expanded gives us: never wider than
      // the stage, never taller than the space left under the status label, and
      // capped so it stays elegant on big screens. Adapts to every screen size.
      final ring = min(280.0, min(c.maxWidth, (c.maxHeight - 44).clamp(120.0, 320.0)));
      return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(statusText,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: statusColor.withValues(alpha: 0.9), letterSpacing: 5)),
      const SizedBox(height: 20),
      SizedBox(
        width: ring,
        height: ring,
        child: Stack(alignment: Alignment.center, children: [
          // Contour ring in the number's colour; the countdown sweeps it round
          // while thinking, otherwise it sits full.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _countdown,
              builder: (_, __) {
                final progress = _phase == 2 ? _countdown.value.clamp(0.0, 1.0) : 1.0;
                return CustomPaint(size: Size(ring, ring), painter: _NumberRingPainter(progress: progress, color: degColor));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ring * 0.18),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _presented.isNotEmpty
                  ? NoteText(note: _presented.split('/').first,
                      style: TextStyle(fontSize: 112, fontWeight: FontWeight.w900, color: degColor, height: 1,
                          shadows: [Shadow(color: degColor.withValues(alpha: 0.45), blurRadius: 34)]))
                  : Text('…', style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.25))),
            ),
          ),
        ]),
      ),
    ]);
    });
  }

  // Pitch class (0..11, C=0) → the white-key natural letter / the black-key name.
  static const _pcNatural = {0: 'C', 2: 'D', 4: 'E', 5: 'F', 7: 'G', 9: 'A', 11: 'B'};
  static const _pcBlack = {1: 'D♭', 3: 'E♭', 6: 'G♭', 8: 'A♭', 10: 'B♭'};

  // One octave that BEGINS on the exercise note (root → its octave, 13 semitones)
  // so the keyboard reads in the exercise's context and every one of the 12 notes
  // is present — the answer always lights up. Works for flat/sharp keys too: a
  // black-note key (B♭, E♭, F♯…) becomes the leftmost key, exactly as asked.
  Widget _keyboard() {
    final rootKey = widget.config.shuffleKeys ? 'C' : (widget.config.key.isNotEmpty ? widget.config.key : 'C');
    final rootPc = kNoteToSemitone[rootKey] ?? 0;
    final notes = <({String name, bool black, int off})>[];
    for (int s = 0; s <= 12; s++) {
      final pc = (rootPc + s) % 12;
      if (_pcNatural.containsKey(pc)) {
        notes.add((name: _pcNatural[pc]!, black: false, off: s));
      } else {
        // Name the octave's own endpoints with the exercise key's spelling.
        notes.add((name: (s == 0 || s == 12) ? rootKey : _pcBlack[pc]!, black: true, off: s));
      }
    }
    final whites = [for (final k in notes) if (!k.black) k];
    final blacks = [for (final k in notes) if (k.black) k];
    final nW = whites.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: SizedBox(
          height: 124,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04)),
              child: LayoutBuilder(builder: (ctx, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                final whiteW = w / nW;
                final blackW = whiteW * 0.62;
                final blackH = h * 0.62;
                return Stack(children: [
                  for (int j = 0; j < nW; j++)
                    Positioned(left: j * whiteW, top: 0, width: whiteW, height: h, child: _pianoKey(whites[j].name, false)),
                  for (int j = 1; j < nW; j++)
                    Positioned(left: j * whiteW - 0.5, top: 0, width: 1, height: h, child: const ColoredBox(color: Color(0xFFCBD5E1))),
                  // Each black key sits after however many white keys precede it;
                  // clamped so a root black key at either end stays fully visible.
                  for (final b in blacks)
                    Positioned(
                      left: (whites.where((wk) => wk.off < b.off).length * whiteW - blackW / 2).clamp(0.0, w - blackW),
                      top: 0, width: blackW, height: blackH,
                      child: _pianoKey(b.name, true),
                    ),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pianoKey(String name, bool black) {
    final nc = AppColors.noteColors[name] ?? Colors.white;
    final isAns = _phase == 3 && _answer.isNotEmpty && areEnharmonicEquivalent(name, _answer);
    final bg = isAns ? nc : (black ? const Color(0xFF1E293B) : Colors.white);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: black ? const BorderRadius.vertical(bottom: Radius.circular(6)) : null,
        border: black ? Border.all(color: Colors.white.withValues(alpha: 0.10)) : null,
        boxShadow: isAns
            ? [BoxShadow(color: nc.withValues(alpha: 0.6), blurRadius: 22, spreadRadius: -2)]
            : (black ? const [BoxShadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 4))] : null),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        NoteText(
          note: formatNoteForDisplay(name, widget.notation),
          style: TextStyle(fontSize: black ? 11 : 15, fontWeight: FontWeight.w900, color: isAns ? Colors.white : nc),
        ),
        SizedBox(height: black ? 9 : 12),
      ]),
    );
  }

  Widget _playBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0x1A1A1625),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10, width: 1.2),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_finished ? 'SESSION COMPLETE' : (_playing ? 'PLAYING' : 'PAUSED'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _accent, letterSpacing: 2)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white.withValues(alpha: 0.38)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('Keeps playing with the screen off',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.38))),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: _accent, // flat single colour — no gradient
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -4)],
              ),
              child: Icon(
                _finished ? Icons.replay_rounded : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                color: Colors.white, size: 32,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // Training-key badge, matching the other modes' top-right badge exactly.
  // On a fixed key it's that key; while shuffling it tracks the current key
  // (a shuffle glyph before the first question), tinted by the key's colour.
  Widget _keyBadge() {
    final shuffle = widget.config.shuffleKeys;
    final key = _key.isNotEmpty ? _key : (shuffle ? '' : widget.config.key);
    // Neutral (uncoloured) badge, exactly like Diatonic / Chromatic — white
    // hairline border, no tint, no glow.
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: Colors.white10,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(51), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('KEY', maxLines: 1, softWrap: false,
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 1.5)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: (shuffle && key.isEmpty)
                ? const Icon(Icons.shuffle_rounded, size: 15, color: Colors.white)
                : NoteText(
                    note: formatNoteForDisplay(key, widget.notation),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                  ),
          ),
        ],
      ),
    );
  }

  // Stat cell for the session card — matches the trainer's _StatItem.
  Widget _stat(String label, String value) => Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, softWrap: false,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 2)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, softWrap: false,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      );

  Widget _blob(double size, Color color) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      );
}

/// A contour ring around the big degree number. [progress] (1→0) is swept by
/// the countdown while the user is thinking; the rest of the time it sits full.
class _NumberRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _NumberRingPainter({required this.progress, required this.color});

  static const _twoPi = 6.283185307179586;
  static const _quarter = 1.5707963267948966; // start at 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Faint full track underneath.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Soft glow, then the crisp coloured arc on top.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    final sweep = _twoPi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -_quarter, sweep, false, glow);
    canvas.drawArc(rect, -_quarter, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_NumberRingPainter old) => old.progress != progress || old.color != color;
}
