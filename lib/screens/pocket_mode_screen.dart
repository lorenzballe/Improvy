import 'dart:async';
import 'dart:math' show Random, min;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../services/voice_service.dart';
import '../services/keep_alive_audio.dart';
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
  /// One standard name per pitch class instead of key-correct spelling.
  final bool simpleNotes;
  /// Reports how many questions were actually spoken, so a drill that ran
  /// counts as practice for the day while opening and immediately leaving does
  /// not. Pocket Mode asks for no answers, so there is nothing to score — but
  /// a day spent training hands-free is still a day trained.
  final void Function(int questionsHeard) onExit;
  const PocketModeScreen({super.key, required this.config, this.notation = 'CDE',
      this.simpleNotes = false, required this.onExit});

  @override
  State<PocketModeScreen> createState() => _PocketModeScreenState();
}

class _PocketModeScreenState extends State<PocketModeScreen> with TickerProviderStateMixin {
  static const _accent = Color(0xFF6366F1); // indigo — Pocket Mode's colour

  final VoiceService _voice = VoiceService();
  // Runs for as long as the session is playing: without audio actually flowing
  // iOS suspends the app during the silent gaps and the loop stops dead.
  final KeepAliveAudio _keepAlive = KeepAliveAudio();
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

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _countdown = AnimationController(vsync: this, duration: const Duration(seconds: 1), value: 0);
    _voice.warmUp(); // spin the decoder up before the first question
    // Auto-start: the user already pressed Start on the setup screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _gen++;
    _voice.dispose();
    _keepAlive.dispose();
    _pulse.dispose();
    _reveal.dispose();
    _countdown.dispose();
    super.dispose();
  }

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
    _keepAlive.start(); // before the first utterance, so the gaps are covered
    final gen = ++_gen;
    _loop(gen);
  }

  void _pause() {
    _gen++; // invalidate the running loop
    _voice.stop();
    _keepAlive.stop(); // paused means idle: let iOS suspend us and save battery
    _countdown.stop();
    setState(() { _playing = false; _phase = 0; });
  }

  void _exit() {
    _gen++;
    _voice.stop();
    _keepAlive.stop();
    widget.onExit(_index);
  }

  /// One speakable question: the key, the degree, the name to ask it by, and
  /// the answer note.
  ///
  /// The voice asks by one of the degree's names at random — an enharmonic
  /// spelling or its upper-structure form (6/13, ♯4/♯11, …) — exactly as the
  /// tap trainer does. The answer is always computed from the base degree, so
  /// it is the same note whichever name was drawn.
  ///
  /// Splitting the degrees widened what the mode can reach: ask for the ♭5 of
  /// D♭ and the correct spelling of the answer is A𝄫, which has no recording.
  /// Rather than say the wrong name — the mistake that put "sharp four" on a
  /// ♭5 question in a shipped build — an unspeakable draw is discarded and
  /// another taken. Bounded, so a selection where nothing can be said ends the
  /// session instead of spinning.
  (String, String, String, String)? _drawQuestion() {
    for (var attempt = 0; attempt < 40; attempt++) {
      final key = widget.config.shuffleKeys
          ? kAllKeys[_rng.nextInt(kAllKeys.length)]
          : widget.config.key;
      final degree = _pickDegree();
      final names = chromaticDegreeNames(degree);
      final presented = names[_rng.nextInt(names.length)];
      final answer = _spell(
          getNoteFromChromaticDegree(degree, calculateMajorScale(key), key));
      if (VoiceService.degreeClip(presented) == null) continue;
      if (VoiceService.noteClip(answer) == null) continue;
      if (widget.config.shuffleKeys && VoiceService.noteClip(key) == null) continue;
      return (key, degree, presented, answer);
    }
    return null;
  }

  /// How the answer is written and said, honouring "Simple Note Names".
  ///
  /// With the setting on, the promise is one spelling per pitch everywhere in
  /// the app — and Pocket Mode was the one place still breaking it, saying
  /// "F flat" and "E double flat" out loud to someone who had asked never to
  /// see them. Same source as the rest of the app, so the voice, the screen
  /// and the keyboard cannot disagree.
  ///
  /// Key-correct spelling is untouched when the setting is off: that is the
  /// default, and it is the more musical answer.
  String _spell(String note) =>
      widget.simpleNotes ? simplifySpelling(note) : note;

  /// The breath between hearing the answer and the next question starting.
  ///
  /// It was a flat 800ms, which is a whole beat of nothing — long enough that
  /// a fast drill stopped feeling like one. It now follows the answer delay the
  /// user chose: someone on 0.3s wants the questions to come at them, someone
  /// on eight seconds is working slowly and would find a snap transition
  /// jarring. Floored so the answer never runs straight into the next number,
  /// capped so it never drags.
  int get _afterAnswerMs => (widget.config.delayMs ~/ 3).clamp(220, 700);

  /// Shows what the audio session actually is, right now, on this device.
  ///
  /// The lock-screen problem cannot be reproduced anywhere it can be watched:
  /// a simulator does not lock, and iOS never suspends an app with a debugger
  /// attached, so a debug build always looks fine. This is the only way to see
  /// whether the session is `playback`, whether it is the app that owns it,
  /// and whether the keep-alive tone is actually running.
  Future<void> _showAudioDiagnostics() async {
    final text = await KeepAliveAudio.describe();
    if (!mounted) return;
    HapticsService.impactLight();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141020),
        title: const Text('Audio session',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SelectableText(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loop(int gen) async {
    final total = widget.config.questions;
    while (mounted && gen == _gen && (total == 0 || _index < total)) {
      final q = _drawQuestion();
      // Nothing in this selection can be spoken — one key and one degree whose
      // answer has no recording, say ♯2 in F♯. Break rather than return, so it
      // finishes the session properly instead of leaving the screen sitting on
      // a Play button that has apparently done nothing.
      if (q == null) break;
      final (key, degree, presented, answer) = q;
      if (gen != _gen || !mounted) return;

      // On a fixed key the voice never names it — not even on the first
      // question: the user chose that key and it is shown on screen, so
      // announcing it only delays the start. Shuffling picks a new key every
      // question, so there the key must always be spoken ("flat three · C").
      final qClips = <String?>[
        VoiceService.degreeClip(presented),
        if (widget.config.shuffleKeys) VoiceService.noteClip(key),
      ];
      // Speech is fired without awaiting completion; _wait drives the pace so
      // the loop can never stall on an engine that never reports "done".
      setState(() { _key = key; _degree = degree; _presented = presented; _answer = ''; _phase = 1; });
      _voice.say(qClips);
      if (!await _wait(VoiceService.phraseMs(qClips), gen)) return;

      // Think — a smooth 1→0 ring sweep over the delay (60fps, not stepped).
      setState(() => _phase = 2);
      _countdown.duration = Duration(milliseconds: widget.config.delayMs);
      _countdown.reverse(from: 1.0);
      if (!await _wait(widget.config.delayMs, gen)) return;

      // Reveal on screen + speak the answer.
      final aClips = <String?>[VoiceService.noteClip(answer)];
      setState(() { _answer = answer; _phase = 3; });
      _reveal.forward(from: 0); // bloom ripple
      HapticsService.impactLight();
      _voice.say(aClips);
      if (!await _wait(VoiceService.phraseMs(aClips) + _afterAnswerMs, gen)) return;

      _prevDegree = degree;
      if (mounted) setState(() => _index++);
    }
    if (mounted && gen == _gen) {
      // The recorded voice only knows degrees and notes, so the session ends on
      // the screen and a haptic rather than a spoken line.
      HapticsService.impactMedium();
      setState(() { _playing = false; _finished = true; _phase = 0; });
      _keepAlive.stop();
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
                    // Long-press the stats to read the real audio session.
                    // Deliberately unlabelled and deliberately present in
                    // release: whether this mode survives the lock screen is
                    // only observable on a real device in a real build, and
                    // two attempts at fixing it were spent guessing because
                    // nothing could be seen from here.
                    GestureDetector(
                      onLongPress: _showAudioDiagnostics,
                      behavior: HitTestBehavior.opaque,
                      child: Row(children: [
                        Expanded(child: _stat('DEGREES', '${widget.config.degrees.length}')),
                        Container(width: 1, height: 28, color: Colors.white10),
                        Expanded(child: _stat('DELAY', widget.config.delayMs % 1000 == 0
                            ? '${widget.config.delayMs ~/ 1000}s'
                            : '${(widget.config.delayMs / 1000).toStringAsFixed(1)}s')),
                        Container(width: 1, height: 28, color: Colors.white10),
                        Expanded(child: _stat('SESSION', total == 0 ? '∞' : '${_index.clamp(0, total)}/$total')),
                      ]),
                    ),
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

  // One octave that BEGINS on the exercise note: 12 semitones, so all 12 notes
  // are present exactly once — the answer always lights up, and the root is NOT
  // repeated at the right edge (same as the in-game keyboard, which lays out a
  // single octave of 7 whites). Works for flat/sharp keys too: a black-note key
  // (B♭, E♭, F♯…) becomes the leftmost key.
  Widget _keyboard() {
    final rootKey = widget.config.shuffleKeys ? 'C' : (widget.config.key.isNotEmpty ? widget.config.key : 'C');
    final rootPc = kNoteToSemitone[rootKey] ?? 0;
    // Every key is named as that note is spelled IN THIS KEY — F♯ major reads
    // F♯ G♯ A♯ B C♯ D♯ E♯, not the generic flats. Same source the in-game
    // chromatic keyboard uses, so the two never disagree about a note's name.
    final keyNames =
        chromaticKeyboardNoteNames(rootKey, simpleNames: widget.simpleNotes);
    final notes = <({String name, String label, bool black, int off})>[];
    for (int s = 0; s < 12; s++) {
      final pc = (rootPc + s) % 12;
      final natural = _pcNatural.containsKey(pc);
      // The generic name still drives the colour and the answer match; only
      // what is printed on the key follows the key's own spelling.
      final generic = natural ? _pcNatural[pc]! : (s == 0 ? rootKey : _pcBlack[pc]!);
      notes.add((
        name: generic,
        label: keyNames[pc] ?? generic,
        black: !natural,
        off: s,
      ));
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
                // A black key at either end (a black tonic starts the octave, a
                // black 7th ends it) gets a slot of its own, exactly as the
                // in-game keyboard does. Clamping it against the rim instead
                // squashed it out of position; here the whites give up ~5% on
                // that side and the key sits on the true octave boundary.
                const edgeInset = 4.0;
                final hasLead = notes.first.black;
                final hasTrail = notes.last.black;
                final sides = (hasLead ? 1 : 0) + (hasTrail ? 1 : 0);
                final whiteW = (w - sides * edgeInset) / (nW + 0.31 * sides);
                final blackW = whiteW * 0.62;
                final blackH = h * 0.62;
                final leadReserve = hasLead ? edgeInset + blackW / 2 : 0.0;
                final whiteAreaRight = leadReserve + nW * whiteW;
                return Stack(children: [
                  // The sliver of the cut-off white key an edge black rests on.
                  // Not a key — nothing here can be played; it only keeps the
                  // black key off the dark rim.
                  if (hasLead)
                    Positioned(left: 0, top: 0, width: leadReserve, height: h,
                        child: const ColoredBox(color: Colors.white)),
                  if (hasTrail)
                    Positioned(left: whiteAreaRight, top: 0, width: w - whiteAreaRight, height: h,
                        child: const ColoredBox(color: Colors.white)),
                  for (int j = 0; j < nW; j++)
                    Positioned(
                        left: leadReserve + j * whiteW, top: 0, width: whiteW, height: h,
                        child: _pianoKey(whites[j].name, whites[j].label, false)),
                  for (int j = 1; j < nW; j++)
                    Positioned(left: leadReserve + j * whiteW - 0.5, top: 0, width: 1, height: h,
                        child: const ColoredBox(color: Color(0xFFCBD5E1))),
                  if (hasLead)
                    Positioned(left: leadReserve - 0.5, top: 0, width: 1, height: h,
                        child: const ColoredBox(color: Color(0xFFCBD5E1))),
                  if (hasTrail)
                    Positioned(left: whiteAreaRight - 0.5, top: 0, width: 1, height: h,
                        child: const ColoredBox(color: Color(0xFFCBD5E1))),
                  // Each black key sits after however many white keys precede it.
                  for (final b in blacks)
                    Positioned(
                      left: leadReserve +
                          whites.where((wk) => wk.off < b.off).length * whiteW -
                          blackW / 2,
                      top: 0, width: blackW, height: blackH,
                      child: _pianoKey(b.name, b.label, true),
                    ),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pianoKey(String name, String label, bool black) {
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
          note: formatNoteForDisplay(label, widget.notation),
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
