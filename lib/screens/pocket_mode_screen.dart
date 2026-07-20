import 'dart:async';
import 'dart:math';
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

class _PocketModeScreenState extends State<PocketModeScreen> {
  static const _accent = Color(0xFF6366F1); // indigo — Pocket Mode's colour

  final TtsService _tts = TtsService();
  final Random _rng = Random();

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
    _tts.warmUp(); // init the audio session/voice before the first question
    // Auto-start: the user already pressed Start on the setup screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _gen++;
    _tts.stop();
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
    final degColor = AppColors.degreeColors[_degree.split('/').first] ?? _accent;
    final noteColor = AppColors.noteColors[_answer] ?? Colors.white;

    final statusText = switch (_phase) {
      1 => 'LISTEN',
      2 => 'YOUR TURN',
      3 => 'ANSWER',
      _ => _finished ? 'DONE' : 'READY',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _exit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(children: [
          // Ambient glow
          Positioned(top: -80, right: -60, child: _blob(280, _accent.withValues(alpha: 0.16))),
          Positioned(bottom: -70, left: -50, child: _blob(240, const Color(0xFF8B5CF6).withValues(alpha: 0.12))),
          SafeArea(
            child: Column(children: [
              // Top bar
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
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                  const Expanded(
                    child: Text('POCKET MODE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      total == 0 ? '∞' : '${_index.clamp(0, total)}/$total',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ]),
              ),

              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(statusText,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 2)),
                    ),
                    const SizedBox(height: 36),

                    // Question: "[degree] of [key]" — shows the name being asked
                    // (base number or its extension), coloured by the base degree.
                    if (_presented.isNotEmpty) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                        NoteText(note: _presented.split('/').first,
                            style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: degColor, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('of', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.4))),
                        ),
                        NoteText(note: _key,
                            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                      ]),
                    ] else
                      Text('Get ready…', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5))),

                    const SizedBox(height: 44),

                    // Answer slot: reserved height so nothing jumps when revealed.
                    SizedBox(
                      height: 150,
                      child: Center(
                        child: _phase == 3 && _answer.isNotEmpty
                            // Big, unmistakable answer card in the note's colour.
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                                decoration: BoxDecoration(
                                  color: noteColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: noteColor.withValues(alpha: 0.55), width: 2),
                                  boxShadow: [BoxShadow(color: noteColor.withValues(alpha: 0.30), blurRadius: 34, spreadRadius: -6)],
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text('ANSWER',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 4)),
                                  const SizedBox(height: 4),
                                  NoteText(note: _answer,
                                      style: TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: noteColor, height: 1.05)),
                                ]),
                              )
                            : _phase == 2
                                ? Text(
                                    '${(_countdownMs / 1000).ceil()}',
                                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.22), height: 1),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ]),
                ),
              ),

              // Play / pause
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 12 + MediaQuery.of(context).padding.bottom),
                child: Column(children: [
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(width: 6),
                    Text('Keeps playing with the screen off',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.35))),
                  ]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _blob(double size, Color color) => IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        ),
      );
}
