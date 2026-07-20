import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
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
  final VoidCallback onExit;
  const PocketModeScreen({super.key, required this.config, required this.onExit});

  @override
  State<PocketModeScreen> createState() => _PocketModeScreenState();
}

class _PocketModeScreenState extends State<PocketModeScreen> with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF6366F1); // indigo — Pocket Mode's colour

  final TtsService _tts = TtsService();
  final Random _rng = Random();
  late final AnimationController _pulse; // slow ambient breathing behind the stage

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
  int _countdownMs = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _tts.warmUp(); // init the audio session/voice before the first question
    // Auto-start: the user already pressed Start on the setup screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _gen++;
    _tts.stop();
    _pulse.dispose();
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

  String _spokenNote(String n) =>
      n.replaceAll('♭', ' flat').replaceAll('♯', ' sharp').trim();

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
    _spokenKey = ''; // re-announce the key on the first question after resuming
    setState(() { _playing = false; _phase = 0; _countdownMs = 0; });
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

      // Think.
      setState(() => _phase = 2);
      if (!await _wait(widget.config.delayMs, gen)) return;

      // Reveal on screen + speak the answer.
      final aText = _spokenNote(answer);
      setState(() { _answer = answer; _phase = 3; });
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

  /// Waits [ms], updating the countdown, but bails the moment the generation
  /// token changes (pause/exit). Returns false if it was interrupted.
  Future<bool> _wait(int ms, int gen) async {
    var left = ms;
    const step = 100;
    while (left > 0) {
      if (gen != _gen || !mounted) return false;
      setState(() => _countdownMs = left);
      await Future<void>.delayed(const Duration(milliseconds: step));
      left -= step;
    }
    if (mounted) setState(() => _countdownMs = 0);
    return gen == _gen && mounted;
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = widget.config.questions;
    final noteColor = AppColors.noteColors[_answer] ?? Colors.white;
    // The mode's live accent: indigo while asking/thinking, the note's colour
    // on the reveal — it tints the glow, the ring and the progress bar together.
    final live = _phase == 3 ? noteColor : _accent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _exit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(children: [
          // Ambient glow — the bottom blob picks up the live colour.
          Positioned(top: -90, right: -70, child: _blob(300, _accent.withValues(alpha: 0.14))),
          Positioned(bottom: -80, left: -60, child: _blob(260, live.withValues(alpha: 0.12))),
          SafeArea(
            child: Column(children: [
              // ── Top bar + session progress ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: _exit,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    ),
                  ),
                  const Expanded(
                    child: Text('POCKET MODE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                  ),
                  const SizedBox(width: 44),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Stack(children: [
                      Container(height: 5, color: Colors.white.withValues(alpha: 0.07)),
                      if (total > 0)
                        FractionallySizedBox(
                          widthFactor: (_index / total).clamp(0.0, 1.0),
                          child: Container(
                            height: 5,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      total == 0 ? 'ENDLESS' : '${_index.clamp(0, total)} / $total',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1.5),
                    ),
                  ),
                ]),
              ),

              // ── Central animated stage ──
              Expanded(
                child: Center(
                  child: LayoutBuilder(builder: (ctx, c) {
                    final size = math.min(c.maxWidth - 48, 320.0).clamp(220.0, 320.0);
                    return _stage(size.toDouble(), noteColor);
                  }),
                ),
              ),

              // ── Play / pause ──
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 14 + MediaQuery.of(context).padding.bottom),
                child: Column(children: [
                  GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 82, height: 82,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 12), spreadRadius: -4)],
                      ),
                      child: Icon(
                        _finished ? Icons.replay_rounded : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        color: Colors.white, size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: Colors.white.withValues(alpha: 0.32)),
                    const SizedBox(width: 6),
                    Text('Keeps playing with the screen off',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.32))),
                  ]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // The circular centrepiece: breathing glow, a countdown ring, and the
  // question/answer content that cross-fades as the round progresses.
  Widget _stage(double size, Color noteColor) {
    final degColor = AppColors.degreeColors[_degree.split('/').first] ?? _accent;
    final delayMs = widget.config.delayMs;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);

        double progress;
        Color ringColor;
        double glow;
        switch (_phase) {
          case 1: // listening — soft breathing ring
            progress = 1.0;
            ringColor = _accent.withValues(alpha: 0.30 + 0.45 * t);
            glow = 0.3 + 0.5 * t;
          case 2: // thinking — countdown depletes
            progress = delayMs == 0 ? 0 : (_countdownMs / delayMs).clamp(0.0, 1.0);
            ringColor = _accent;
            glow = 0.25;
          case 3: // answer — full ring in the note's colour
            progress = 1.0;
            ringColor = noteColor;
            glow = 0.5 + 0.3 * t;
          default:
            progress = 0;
            ringColor = _accent;
            glow = 0;
        }
        final glowColor = _phase == 3 ? noteColor : _accent;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, children: [
            // breathing halo
            Container(
              width: size * 0.86,
              height: size * 0.86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.10 + 0.12 * t), blurRadius: 55 + 25 * t, spreadRadius: 6)],
              ),
            ),
            // glass disc
            Container(
              width: size - 42,
              height: size - 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.015)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            // ring
            CustomPaint(size: Size(size, size), painter: _StageRingPainter(progress: progress, color: ringColor, glow: glow)),
            // content
            Padding(
              padding: EdgeInsets.all(size * 0.16),
              child: _stageContent(degColor, noteColor),
            ),
          ]),
        );
      },
    );
  }

  Widget _stageContent(Color degColor, Color noteColor) {
    if (_finished) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: _accent, size: 56),
        const SizedBox(height: 14),
        const Text('Session\ncomplete', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15)),
      ]);
    }

    final statusText = switch (_phase) {
      1 => 'LISTEN',
      2 => 'YOUR TURN',
      3 => 'ANSWER',
      _ => 'GET READY',
    };
    final statusColor = _phase == 3 ? noteColor : _accent;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(statusText,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor.withValues(alpha: 0.9), letterSpacing: 3)),
      const SizedBox(height: 16),
      // Question "[degree] of [key]"
      if (_presented.isNotEmpty)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
            NoteText(note: _presented.split('/').first,
                style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: degColor, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('of', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.4))),
            ),
            NoteText(note: _key,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
          ]),
        )
      else
        Text('…', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.3))),
      const SizedBox(height: 12),
      // Answer reveal / countdown — fixed slot so the layout never jumps.
      SizedBox(
        height: 66,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)), child: child),
          ),
          child: _phase == 3 && _answer.isNotEmpty
              ? NoteText(
                  key: ValueKey('a$_answer$_index'),
                  note: _answer,
                  style: TextStyle(fontSize: 58, fontWeight: FontWeight.w900, color: noteColor, height: 1,
                      shadows: [Shadow(color: noteColor.withValues(alpha: 0.5), blurRadius: 24)]),
                )
              : _phase == 2
                  ? Text('${(_countdownMs / 1000).ceil()}',
                      key: ValueKey('c${(_countdownMs / 1000).ceil()}'),
                      style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.22), height: 1))
                  : const SizedBox.shrink(),
        ),
      ),
    ]);
  }

  Widget _blob(double size, Color color) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      );
}

// Countdown / status ring drawn around the stage: a faint full track with a
// coloured arc sweeping from the top. During the answer phase it's a full
// glowing circle in the note's colour.
class _StageRingPainter extends CustomPainter {
  final double progress; // 0..1 of the circle, from 12 o'clock clockwise
  final Color color;
  final double glow; // 0..1 blur intensity

  _StageRingPainter({required this.progress, required this.color, this.glow = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (glow > 0) arc.maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glow);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_StageRingPainter old) =>
      old.progress != progress || old.color != color || old.glow != glow;
}
