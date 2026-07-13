import 'dart:async';
import 'dart:math' show Random, min;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/training_mode.dart';
import '../models/stats.dart';
import '../constants/app_colors.dart';
import '../constants/music_constants.dart';
import '../utils/music_engine.dart';
import '../services/haptics_service.dart';
import '../widgets/note_text.dart';

class TrainerScreen extends StatefulWidget {
  final TrainingMode mode;
  final String selectedKey;
  final int difficulty;
  final int? numberOfQuestions;
  final List<String>? customDegrees;
  final bool? isReverse;
  final bool adaptiveDifficulty;
  final List<dynamic> sessionHistory;
  final String notation;
  final bool keyboardFromTonic;
  final VoidCallback onExit;
  final void Function(bool isCorrect, int responseTime, AnswerRecord details) onAnswer;
  final void Function(Map<String, dynamic> data) onFinish;

  const TrainerScreen({
    super.key,
    required this.mode,
    required this.selectedKey,
    required this.difficulty,
    this.numberOfQuestions,
    this.customDegrees,
    this.isReverse,
    required this.adaptiveDifficulty,
    required this.sessionHistory,
    required this.notation,
    this.keyboardFromTonic = false,
    required this.onExit,
    required this.onAnswer,
    required this.onFinish,
  });

  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> with TickerProviderStateMixin {
  late String _currentKey;
  late List<String> _scale;
  String _degreeLabel = '1';
  String _fullDegree = '1'; // logical degree incl. slash (for de-dup); shown label may be a single spelling
  String _correctAnswer = '';
  int _correct = 0;
  int _attempts = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _showFeedback = false;
  bool _isCorrectFeedback = false;
  String? _lastSelected;
  bool _pianoMode = false;

  Timer? _autoTimer;
  Timer? _feedbackTimer;
  Timer? _timerTick;
  DateTime _questionStart = DateTime.now();
  final DateTime _sessionStart = DateTime.now();
  int _remainingMs = 6000;

  late AnimationController _haloController;
  late Animation<double> _haloAnim;
  bool _haloCorrect = false;

  // Adaptive difficulty tracking
  final List<AnswerRecord> _sessionAnswers = [];

  bool get _actualIsReverse =>
      widget.mode == TrainingMode.noteToNumber ||
      (widget.mode == TrainingMode.custom && (widget.isReverse ?? false));

  int get _questionsPerKey =>
      widget.numberOfQuestions ??
      (widget.difficulty == 1 ? 30 : widget.difficulty == 2 ? 40 : 50);

  int get _timeLimit =>
      widget.difficulty == 1 ? 6000 : widget.difficulty == 2 ? 4000 : 2000;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.selectedKey;
    _scale = calculateMajorScale(_currentKey);
    _remainingMs = _timeLimit;

    _haloController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _haloAnim = CurvedAnimation(parent: _haloController, curve: Curves.easeOut);

    _generateChallenge();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _feedbackTimer?.cancel();
    _timerTick?.cancel();
    _haloController.dispose();
    super.dispose();
  }

  List<NoteItem> get _notesToShow {
    if (_actualIsReverse) {
      final degrees = widget.customDegrees?.isNotEmpty == true
          ? widget.customDegrees!
          : kChromaticDegreesSplit.toList();
      return degrees.map((d) => NoteItem(label: d, note: d)).toList();
    }
    if (widget.mode == TrainingMode.diatonic) {
      final items = _scale.map((n) => NoteItem(label: n, rawLabel: n, note: n)).toList();
      items.sort((a, b) => (kNoteToSemitone[a.note] ?? 0) - (kNoteToSemitone[b.note] ?? 0));
      return items;
    }
    final buttons = getChromaticButtons(_scale, _currentKey);
    if (widget.mode == TrainingMode.custom && widget.customDegrees != null) {
      return buttons.map((b) {
        final matching = kChromaticDegrees.where((d) =>
            areEnharmonicEquivalent(getNoteFromChromaticDegree(d, _scale, _currentKey), b.note));
        final disabled = !matching.any((d) => widget.customDegrees!.contains(d));
        return NoteItem(label: b.label, rawLabel: b.rawLabel, note: b.note, disabled: disabled);
      }).toList();
    }
    return buttons;
  }

  void _generateChallenge() {
    _autoTimer?.cancel();
    _timerTick?.cancel();

    final possibleDegrees = widget.mode == TrainingMode.diatonic
        ? ['1', '2', '3', '4', '5', '6', '7']
        : (widget.customDegrees?.isNotEmpty == true
            ? widget.customDegrees!
            : (_actualIsReverse ? kChromaticDegreesSplit : kChromaticDegrees).toList());

    final currentDeg = _actualIsReverse ? _correctAnswer : _fullDegree;
    String next;

    // Adaptive picking kicks in as soon as there is enough recorded data for
    // this key+mode (see _pickAdaptiveDegree) — a returning player gets a
    // personalised question 1, not five warm-up randoms every session.
    if (widget.adaptiveDifficulty) {
      next = _pickAdaptiveDegree(possibleDegrees, currentDeg);
    } else {
      final available = possibleDegrees.where((d) => d != currentDeg).toList();
      if (available.isEmpty) available.addAll(possibleDegrees);
      next = available[Random().nextInt(available.length)];
    }
    // Each chromatic degree is a single canonical name (no slash, no 9/11/13
    // extensions) so the question always asks for exactly one degree, and every
    // note keeps an equal 1-in-12 chance of being chosen.

    setState(() {
      _showFeedback = false;
      _lastSelected = null;
      _remainingMs = _timeLimit;
      _fullDegree = next; // logical degree (incl. slash) — used for de-dup
      if (_actualIsReverse) {
        _degreeLabel = getNoteFromChromaticDegree(next, _scale, _currentKey);
        _correctAnswer = next;
      } else if (widget.mode == TrainingMode.diatonic) {
        _degreeLabel = next;
        final idx = int.tryParse(next);
        _correctAnswer = idx != null && idx >= 1 && idx <= 7 ? _scale[idx - 1] : _scale[0];
      } else {
        // Chromatic forward: the QUESTION asks a single spelling — never the
        // "♭3/♯2" slash form. The two enharmonic spellings split the degree's
        // probability; the enharmonic note button still shows both names.
        _degreeLabel = _singleSpelling(next);
        _correctAnswer = getNoteFromChromaticDegree(next, _scale, _currentKey);
      }
    });

    _questionStart = DateTime.now();
    _startTimers();
  }

  // Pick one enharmonic spelling (e.g. '♭3/♯2' → '♭3' or '♯2') so the asked
  // degree never shows a slash; 50/50 between the two spellings.
  String _singleSpelling(String deg) {
    if (!deg.contains('/')) return deg;
    final parts = deg.split('/');
    return parts[Random().nextInt(parts.length)];
  }

  // Leftmost white-key semitone for the in-game keyboard. With the
  // "keyboard from tonic" setting on it's the tonic's own white key — or the
  // white key just below the tonic when the tonic is a black key. Otherwise C.
  int get _keyboardStartSemitone {
    if (!widget.keyboardFromTonic) return 0;
    final tonic = kNoteToSemitone[_currentKey] ?? 0;
    const whites = {0, 2, 4, 5, 7, 9, 11};
    return whites.contains(tonic) ? tonic : tonic - 1;
  }

  // True when a recorded answer's degree is (one spelling of) [candidate].
  // Forward-chromatic candidates keep the slash form ('♭3/♯2') while answers
  // record the single spelling actually asked ('♭3' or '♯2'), so the match
  // must try every spelling — comparing the raw strings never matched, which
  // left the three enharmonic degrees permanently "never seen" and over-asked.
  static bool _isSameDegree(String recorded, String candidate) {
    final r = normalizeExtension(recorded);
    return candidate.split('/').any((p) => normalizeExtension(p) == r);
  }

  String _pickAdaptiveDegree(List<String> possible, String currentDeg) {
    // Only this key's history: the same degree lands on different piano keys
    // in different tonalities (♭3 in C is a black key, in F♯ it's white), so
    // struggling with a degree in one key says little about it in another.
    // Built in TRUE chronological order — sessionHistory is newest-first, so
    // it must be reversed (answers inside a session are already oldest→newest)
    // with the current session appended. The recent-accuracy slice, the
    // correct-streak walk and questions-since-last-asked below all read the
    // tail of this list as "most recent" and silently rot if the order lies.
    final allAnswers = [
      for (final s in widget.sessionHistory.reversed)
        ...((s.answers ?? []) as List)
            .where((a) => a.mode == widget.mode.storageKey && a.tonality == _currentKey)
            .map(_normalizedAnswer),
      ..._sessionAnswers,
    ];

    // Not enough data to be smart about this key yet → uniform random,
    // exactly like non-adaptive play (no immediate repeat).
    if (allAnswers.length < 8) {
      final available = possible.where((d) => d != currentDeg).toList();
      if (available.isEmpty) available.addAll(possible);
      return available[Random().nextInt(available.length)];
    }

    final targetTime = widget.difficulty == 1 ? 5000.0 : widget.difficulty == 2 ? 3000.0 : 1500.0;

    final weights = possible.map((deg) {
      if (deg == currentDeg && possible.length > 1) return 0.0;

      final degAnswers = allAnswers.where((a) => _isSameDegree(a.degree, deg)).toList();
      if (degAnswers.isEmpty) return 100.0; // never asked in this key → top priority

      // Mastery: accuracy over the most recent 15 asks, blended with the
      // current correct-streak. Low mastery → high weight (asked more often).
      final recent = degAnswers.length > 15 ? degAnswers.sublist(degAnswers.length - 15) : degAnswers;
      final correctRecent = recent.where((a) => a.isCorrect).toList();
      final globalAccuracy = correctRecent.length / recent.length;

      int streakCount = 0;
      for (int j = degAnswers.length - 1; j >= 0; j--) {
        if (degAnswers[j].isCorrect) streakCount++; else break;
      }

      final masteryBoost = (streakCount / 5).clamp(0.0, 1.0);
      final mastery = globalAccuracy * 0.6 + masteryBoost * 0.4;
      double weight = 60 - mastery * 50;

      // Speed: knowing it slowly is not knowing it — slow-but-correct answers
      // keep a degree in rotation even at 100% accuracy.
      if (correctRecent.length >= 3) {
        final last3 = correctRecent.sublist(correctRecent.length - 3);
        final avg = last3.fold<double>(0, (s, a) => s + a.responseTime) / 3;
        if (avg > targetTime) {
          weight += ((avg - targetTime) / targetTime).clamp(0.0, 1.5) * 45;
        } else {
          weight *= 0.7;
        }
      } else {
        weight += 40;
      }

      // Spaced repetition: resurface degrees that haven't been asked for a
      // while, so mastered ones still come back for review now and then.
      final lastIdx = allAnswers.lastIndexWhere((a) => _isSameDegree(a.degree, deg));
      final qSinceSeen = allAnswers.length - lastIdx;
      if (qSinceSeen > possible.length * 3) {
        final decay = ((qSinceSeen - possible.length * 3) / (possible.length * 12)).clamp(0.0, 1.0);
        weight += decay * 40;
      }

      // Session variety: soften what was asked 2–3 questions ago so two weak
      // degrees can't ping-pong back and forth for a whole session.
      final n = _sessionAnswers.length;
      if (n >= 2 && _isSameDegree(_sessionAnswers[n - 2].degree, deg)) {
        weight *= 0.45;
      } else if (n >= 3 && _isSameDegree(_sessionAnswers[n - 3].degree, deg)) {
        weight *= 0.7;
      }

      weight += Random().nextDouble() * 5;
      return weight.clamp(5.0, 200.0);
    }).toList();

    final totalWeight = weights.reduce((a, b) => a + b);
    var random = Random().nextDouble() * totalWeight;
    for (int i = 0; i < weights.length; i++) {
      if (random < weights[i]) return possible[i];
      random -= weights[i];
    }
    return possible[0];
  }

  AnswerRecord _normalizedAnswer(dynamic a) => AnswerRecord(
    degree: a.degree ?? '',
    note: a.note ?? '',
    selectedNote: a.selectedNote ?? '',
    tonality: a.tonality ?? '',
    mode: a.mode ?? '',
    isReverse: a.isReverse ?? false,
    difficulty: a.difficulty ?? 1,
    responseTime: a.responseTime ?? 0,
    isCorrect: a.isCorrect ?? false,
    timestamp: a.timestamp ?? 0,
  );

  void _startTimers() {
    // Auto-fail timer
    _autoTimer = Timer(Duration(milliseconds: _timeLimit), () {
      if (!_showFeedback) _handleAnswer('');
    });

    // Visual countdown
    _timerTick = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (_showFeedback) { t.cancel(); return; }
      final elapsed = DateTime.now().difference(_questionStart).inMilliseconds;
      setState(() => _remainingMs = (_timeLimit - elapsed).clamp(0, _timeLimit));
    });
  }

  void _handleAnswer(String selected) {
    if (_showFeedback) return;
    _autoTimer?.cancel();
    _timerTick?.cancel();

    final responseTime = DateTime.now().difference(_questionStart).inMilliseconds;
    final isCorrect = _actualIsReverse
        ? selected.split('/').any((p) => _correctAnswer.split('/').contains(p))
        : areEnharmonicEquivalent(selected, _correctAnswer);

    final currentDegree = _actualIsReverse ? _correctAnswer : _degreeLabel;

    final record = AnswerRecord(
      degree: currentDegree,
      note: _actualIsReverse ? _degreeLabel : _correctAnswer,
      selectedNote: selected,
      tonality: _currentKey,
      mode: widget.mode.storageKey,
      isReverse: _actualIsReverse,
      difficulty: widget.difficulty,
      responseTime: responseTime,
      isCorrect: isCorrect,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _sessionAnswers.add(record);

    setState(() {
      _showFeedback = true;
      _isCorrectFeedback = isCorrect;
      _lastSelected = selected;
      _attempts++;
      if (isCorrect) {
        _correct++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        HapticsService.success();
      } else {
        _streak = 0;
        HapticsService.error();
      }
      _haloCorrect = isCorrect;
    });

    // Schedule the next question FIRST so nothing below (feedback effects or
    // stats recording) can ever block advancing to the next degree.
    // Correct answers advance faster (shorter "CORRECT" flash) so the game
    // feels snappier; wrong answers stay up long enough to read the solution.
    _feedbackTimer = Timer(Duration(milliseconds: isCorrect ? 380 : 1800), () {
      if (_attempts >= _questionsPerKey) {
        _finishSession();
      } else {
        _generateChallenge();
      }
    });

    _haloController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _haloController.reverse();
      });
    });

    // Recording stats must never break the game loop.
    try {
      widget.onAnswer(isCorrect, responseTime, record);
    } catch (_) {}
  }

  // X button / system back. Mid-run, confirm before throwing the game away —
  // an accidental edge-swipe shouldn't kill a 40-question streak. The clock is
  // paused while the dialog is up and restarts fresh on "keep playing".
  void _requestExit() {
    if (_attempts == 0 || _attempts >= _questionsPerKey) {
      widget.onExit();
      return;
    }
    _autoTimer?.cancel();
    _timerTick?.cancel();
    _feedbackTimer?.cancel();
    HapticsService.impactLight();
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1625),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withAlpha(26)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 34),
              const SizedBox(height: 14),
              const Text('End this session?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('You are $_attempts/$_questionsPerKey in — the run ends here if you leave.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white.withAlpha(150))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('KEEP PLAYING',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('QUIT',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5,
                        color: Colors.white.withAlpha(120))),
              ),
            ],
          ),
        ),
      ),
    ).then((quit) {
      if (!mounted) return;
      if (quit == true) {
        widget.onExit();
        return;
      }
      // Resume where we paused: mid-feedback → advance; mid-question → fresh clock.
      if (_showFeedback) {
        if (_attempts >= _questionsPerKey) {
          _finishSession();
        } else {
          _generateChallenge();
        }
      } else {
        _questionStart = DateTime.now();
        setState(() => _remainingMs = _timeLimit);
        _startTimers();
      }
    });
  }

  void _finishSession() {
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    widget.onFinish({
      'key': _currentKey,
      'mode': widget.mode.storageKey,
      'accuracy': _attempts > 0 ? (_correct / _attempts * 100).round() : 0,
      'correct': _correct,
      'total': _attempts,
      'time': elapsed,
      'difficulty': widget.difficulty,
    });
  }

  Color _streakColor() {
    if (_streak == 0) return const Color(0xFF06B6D4);
    if (_streak >= 10) return const Color(0xFFfacc15);
    final t = (_streak / 10).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF06B6D4), const Color(0xFFF97316), t)!;
  }

  Color _accuracyColor() {
    // 0 attempts = white (matches web: rgba(255,255,255,0.7))
    if (_attempts == 0) return Colors.white70;
    final ratio = _correct / _attempts;
    if (ratio < 0.5) {
      return Color.lerp(const Color(0xFFEF4444), const Color(0xFFfacc15), ratio * 2)!;
    } else {
      return Color.lerp(const Color(0xFFfacc15), const Color(0xFF22C55E), (ratio - 0.5) * 2)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notesToShow;
    // Note-to-Number chromatic shows 12 answer buttons, which sit low; lift the
    // cluster slightly (mirrors the web's isNoteToNumberChromatic offset).
    final isN2NChromatic = widget.mode == TrainingMode.noteToNumber && notes.length > 7;
    final progress = _questionsPerKey > 0 ? _attempts / _questionsPerKey : 0.0;
    final timerPct = _remainingMs / _timeLimit;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    // Single reserved height for the input zone — identical for the grid and the
    // piano keyboard, so the buttons/keys sit at the exact same place in every mode.
    final inputH = (sh * 0.35).clamp(120.0, 330.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _requestExit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Layer 1 — base solid #0F0A1A
            Container(color: const Color(0xFF0F0A1A)),
            // Layer 1b — four corner radial gradients (slate TL, indigo TR, violet BR, dark BL)
            Positioned.fill(child: Container(decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1e293b), Colors.transparent],
              ),
            ))),
            Positioned.fill(child: Container(decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [Color(0xFF312e81), Colors.transparent],
              ),
            ))),
            Positioned.fill(child: Container(decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.5,
                colors: [Color(0xFF4c1d95), Colors.transparent],
              ),
            ))),
            // Layer 2 — bg-black/25 contrast overlay
            Container(color: const Color(0x40000000)),
            // Layer 3 — ambient glows with real ImageFilter.blur (sigma=60 ≈ blur-80px mobile)
            Positioned(
              top: sh * 0.2 - 120,
              right: -(sw * 0.1 + 120),
              child: _glow((sw * 0.6).clamp(0.0, 400.0), const Color(0x26EC4899)),
            ),
            Positioned(
              bottom: sh * 0.2 - 120,
              left: -(sw * 0.1 + 120),
              child: _glow((sw * 0.6).clamp(0.0, 400.0), const Color(0x2614B8A6)),
            ),
            Positioned(
              top: sh / 2 - (sw * 0.4).clamp(0.0, 256.0) - 120,
              left: sw / 2 - (sw * 0.4).clamp(0.0, 256.0) - 120,
              child: _glow((sw * 0.8).clamp(0.0, 512.0), const Color(0x1A3B82F6)),
            ),
            // Feedback halo
            AnimatedBuilder(
              animation: _haloAnim,
              builder: (_, __) {
                final opacity = _haloAnim.value;
                if (opacity <= 0) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            (_haloCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withAlpha((opacity * 50).round()),
                            Colors.transparent,
                          ],
                          radius: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    onExit: _requestExit,
                    progress: progress,
                    timerPct: timerPct,
                    timeLimit: _timeLimit,
                    currentKey: _currentKey,
                    notation: widget.notation,
                    correct: _correct,
                    total: _questionsPerKey,
                    accuracy: _attempts > 0 ? (_correct / _attempts * 100).round() : 0,
                    streak: _streak,
                    streakColor: _streakColor(),
                    accuracyColor: _accuracyColor(),
                    showFeedback: _showFeedback,
                  ),
                  // Question — fills the top, keeping the input pinned low.
                  // Fades out under the minimal feedback so they don't overlap.
                  Expanded(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showFeedback ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 140),
                        // Scale the whole question down if the screen is short
                        // (e.g. the 15-button reverse grid on a small phone) so
                        // the big note/number can never overlap the answer area.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _QuestionDisplay(
                            label: _degreeLabel,
                            isReverse: _actualIsReverse,
                            notation: widget.notation,
                            streak: _streak,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Input area — sits at the bottom, just above the toggle
                  if (_pianoMode && !_actualIsReverse)
                    // The keyboard widget adds ~32px of its own padding, so the
                    // keys area is inputH-32 → total ≈ inputH (same as the grid zone).
                    _PianoKeyboard(
                      notes: notes,
                      showFeedback: _showFeedback,
                      correctAnswer: _correctAnswer,
                      lastSelected: _lastSelected,
                      notation: widget.notation,
                      height: inputH - 32,
                      startWhiteSemitone: _keyboardStartSemitone,
                      chromaticTonic:
                          widget.mode == TrainingMode.chromatic ? _currentKey : null,
                      onSelect: _handleAnswer,
                    )
                  else
                    // Same reserved height as the keyboard; buttons centered so the
                    // grid sits at the exact same vertical position in every mode.
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: inputH),
                      child: Center(
                        child: _AnswerGrid(
                          notes: notes,
                          isReverse: _actualIsReverse,
                          showFeedback: _showFeedback,
                          correctAnswer: _correctAnswer,
                          lastSelected: _lastSelected,
                          notation: widget.notation,
                          onSelect: _handleAnswer,
                        ),
                      ),
                    ),
                  // Input-mode toggle — only for note-answer modes.
                  // Extra bottom padding lifts the whole input cluster (buttons +
                  // keyboard + toggle) off the bottom edge for a balanced layout.
                  if (!_actualIsReverse)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticsService.impactLight();
                            setState(() => _pianoMode = !_pianoMode);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(26),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withAlpha(51)),
                                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 30, offset: const Offset(0, -10))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(_pianoMode ? 'GRID VIEW' : 'PIANO KEYBOARD',
                                          maxLines: 1,
                                          softWrap: false,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(_pianoMode ? Icons.grid_view_rounded : Icons.piano_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: isN2NChromatic ? 64 : 30),
                ],
              ),
            ),
            // Feedback overlay — full-screen Stack layer matching web's fixed inset-0 pb-[35vh] z-[9999]
            if (_showFeedback)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: Center(
                      child: _buildFeedbackCard(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tonal colour of the correct answer (note in forward mode, degree in reverse).
  Color _answerColor() {
    if (_actualIsReverse) {
      return AppColors.degreeColors[_correctAnswer.split('/')[0]] ?? Colors.white;
    }
    return AppColors.noteColors[_correctAnswer] ?? Colors.white;
  }

  Widget _buildFeedbackCard() {
    final correct = _isCorrectFeedback;
    final accent = correct ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    // A contained frosted-glass card: refined icon badge, status word, and —
    // when wrong — the correct answer. Cleaner and calmer than a bare circle.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final ct = t.clamp(0.0, 1.0);
        return Opacity(opacity: ct, child: Transform.scale(scale: 0.86 + 0.14 * t, child: child));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(34, 26, 34, 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(32),
              // Soft hairline border in the app's style; the accent lives in the
              // badge + glow rather than a hard coloured outline.
              border: Border.all(color: Colors.white.withValues(alpha:0.12), width: 1),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha:0.18), blurRadius: 56, spreadRadius: -8),
                BoxShadow(color: Colors.black.withValues(alpha:0.4), blurRadius: 30, offset: const Offset(0, 16)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon badge — moderate, lit from the top-left.
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: [Color.lerp(accent, Colors.white, 0.35)!, accent],
                    ),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha:0.55), blurRadius: 24, spreadRadius: -2)],
                  ),
                  child: Icon(correct ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    correct ? 'CORRECT' : 'WRONG',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4, color: accent),
                  ),
                ),
                if (!correct) ...[
                  const SizedBox(height: 16),
                  Container(height: 1, width: 64, color: Colors.white.withValues(alpha:0.1)),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CORRECT ANSWER',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white.withValues(alpha:0.45)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: NoteText(
                      note: formatNoteForDisplay(_correctAnswer, widget.notation),
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, color: _answerColor()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) {
    const sigma = 60.0;
    const pad = sigma * 2.0;
    final total = size + pad * 2;
    return SizedBox(
      width: total,
      height: total,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onExit;
  final double progress;
  final double timerPct;
  final int timeLimit;
  final String currentKey;
  final String notation;
  final int correct;
  final int total;
  final int accuracy;
  final int streak;
  final Color streakColor;
  final Color accuracyColor;
  final bool showFeedback;

  const _TopBar({
    required this.onExit,
    required this.progress,
    required this.timerPct,
    required this.timeLimit,
    required this.currentKey,
    required this.notation,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.streak,
    required this.streakColor,
    required this.accuracyColor,
    required this.showFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onExit,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    const Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('PROGRESS', maxLines: 1, softWrap: false, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 4)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Progress bar — gradient fill like web app
                    LayoutBuilder(builder: (ctx, box) {
                      final filled = (box.maxWidth * progress.clamp(0.0, 1.0));
                      return Container(
                        height: 6,
                        width: box.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.white.withAlpha(13), width: 1.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 6,
                              width: filled,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF60A5FA), Color(0xFFA855F7), Color(0xFFEC4899)],
                                ),
                                boxShadow: const [BoxShadow(color: Color(0x66A855F7), blurRadius: 12)],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
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
                      child: Text('KEY', maxLines: 1, softWrap: false, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 1.5)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: NoteText(
                        note: formatNoteForDisplay(currentKey, notation),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0x1A1A1625),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10, width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(child: _StatItem(label: 'CORRECT', value: '$correct/$total', valueColor: Colors.white)),
                Container(width: 1, height: 30, color: Colors.white10),
                Expanded(child: _StatItem(label: 'ACCURACY', value: '$accuracy%', valueColor: accuracyColor)),
                Container(width: 1, height: 30, color: Colors.white10),
                Expanded(child: _StatItem(
                  label: 'STREAK',
                  value: streak >= 10 ? '🔥$streak' : '$streak',
                  valueColor: streakColor,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatItem({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, softWrap: false, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 2)),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        // Tabular figures: digits share one width, so 0/30 → 1/30 doesn't
        // make the value wobble sideways on every answer.
        child: Text(value, maxLines: 1, softWrap: false,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    ],
  );
}

class _QuestionDisplay extends StatelessWidget {
  final String label;
  final bool isReverse;
  final String notation;
  final int streak;

  const _QuestionDisplay({
    required this.label,
    required this.isReverse,
    required this.notation,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final display = isReverse ? formatNoteForDisplay(label, notation) : label;
    // Match web: clamp(6rem, min(45vw, 22vh), 12rem)
    final sz = MediaQuery.of(context).size;
    final fontSize = min(sz.width * 0.45, sz.height * 0.22).clamp(88.0, 192.0);

    final Widget numberCore = isReverse
        ? NoteText(
            note: display,
            style: TextStyle(
              fontSize: fontSize * 0.88,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 80, offset: Offset(0, 20))],
            ),
          );
    // Keep wide labels (e.g. "♭5/♯4") inside the screen — scale down to fit width.
    final bigNumber = ConstrainedBox(
      // Reserve the two badge slots when the streak shows, so the centred number
      // never overflows the screen.
      constraints: BoxConstraints(maxWidth: sz.width - 64 - (streak > 4 ? 96 : 0)),
      child: FittedBox(fit: BoxFit.scaleDown, child: numberCore),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isReverse ? 'NOTE' : 'DEGREE',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withAlpha(204),
              letterSpacing: 7.2,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Big number with optional streak badge to the right
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          // Remove the outgoing number instantly so the previous value never
          // flashes for a frame when the question reappears after feedback.
          reverseDuration: Duration.zero,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Row(
            key: ValueKey(label),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invisible mirror of the badge on the left keeps the number
              // itself centred while the streak sits to its right.
              if (streak > 4) Opacity(opacity: 0, child: _streakBadge()),
              bigNumber,
              if (streak > 4) _streakBadge(),
            ],
          ),
        ),
      ],
    );
  }

  // The streak chip — rendered to the right of the number, and mirrored
  // invisibly on the left so the number stays centred.
  Widget _streakBadge() => Transform.translate(
    offset: const Offset(-2, 0),
    child: Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: streak >= 10
              ? const [Color(0xFFfacc15), Color(0xFFf97316), Color(0xFFdc2626)]
              : const [Color(0xFF22c55e), Color(0xFF10b981)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: streak >= 10 ? const Color(0x66f97316) : const Color(0x6622c55e),
            blurRadius: 15,
          ),
        ],
      ),
      child: Text(
        'x$streak',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: streak >= 10 ? Colors.white : Colors.black,
        ),
      ),
    ),
  );
}

class _AnswerGrid extends StatelessWidget {
  final List<NoteItem> notes;
  final bool isReverse;
  final bool showFeedback;
  final String correctAnswer;
  final String? lastSelected;
  final String notation;
  final void Function(String) onSelect;

  const _AnswerGrid({
    required this.notes,
    required this.isReverse,
    required this.showFeedback,
    required this.correctAnswer,
    required this.lastSelected,
    required this.notation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visible = notes.where((n) => !n.disabled).toList();
    final count = visible.length;

    // Diatonic 7-note: 4+3 layout — all 7 buttons same size, bottom row centered
    if (count == 7) {
      const gap = 12.0; // web: gap-3 = 12px
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final bw = (constraints.maxWidth - 3 * gap) / 4;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: 4 equal buttons
                Row(
                  children: [
                    for (int i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: bw, height: bw,
                        child: _NoteButton(
                          item: visible[i],
                          isReverse: isReverse,
                          showFeedback: showFeedback,
                          correctAnswer: correctAnswer,
                          isLastSelected: lastSelected == visible[i].note,
                          notation: notation,
                          onTap: () => onSelect(visible[i].note),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: gap),
                // Row 2: 3 buttons same width, centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: bw, height: bw,
                        child: _NoteButton(
                          item: visible[4 + i],
                          isReverse: isReverse,
                          showFeedback: showFeedback,
                          correctAnswer: correctAnswer,
                          isLastSelected: lastSelected == visible[4 + i].note,
                          notation: notation,
                          onTap: () => onSelect(visible[4 + i].note),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    final cols = count <= 4 ? 2 : count <= 6 ? 3 : 4;
    const cgap = 12.0; // match the web's gap-3 (and the diatonic layout)

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final bw = (constraints.maxWidth - (cols - 1) * cgap) / cols;
          final rowsCount = (count / cols).ceil();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int r = 0; r < rowsCount; r++) ...[
                if (r > 0) const SizedBox(height: cgap),
                Row(
                  // An incomplete last row (e.g. the 3 leftover degrees of the
                  // 15-button reverse grid) is centered; full rows fill exactly.
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int c = 0; c < cols && (r * cols + c) < count; c++) ...[
                      if (c > 0) const SizedBox(width: cgap),
                      SizedBox(
                        width: bw,
                        height: bw,
                        child: _NoteButton(
                          item: visible[r * cols + c],
                          isReverse: isReverse,
                          showFeedback: showFeedback,
                          correctAnswer: correctAnswer,
                          isLastSelected: lastSelected == visible[r * cols + c].note,
                          notation: notation,
                          onTap: () => onSelect(visible[r * cols + c].note),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoteButton extends StatefulWidget {
  final NoteItem item;
  final bool isReverse;
  final bool showFeedback;
  final String correctAnswer;
  final bool isLastSelected;
  final String notation;
  final VoidCallback onTap;

  const _NoteButton({
    required this.item,
    required this.isReverse,
    required this.showFeedback,
    required this.correctAnswer,
    required this.isLastSelected,
    required this.notation,
    required this.onTap,
  });

  @override
  State<_NoteButton> createState() => _NoteButtonState();
}

class _NoteButtonState extends State<_NoteButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _fb;
  late final Animation<double> _bounce;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _fb = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    // Correct → a single, smooth up-and-down (no double hop).
    _bounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -16.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -16.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _fb, curve: Curves.easeInOut));
    // Wrong → a quick horizontal tremble.
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _fb, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _NoteButton old) {
    super.didUpdateWidget(old);
    // Fire the reaction the instant feedback appears for the pressed button.
    if (widget.showFeedback && !old.showFeedback && widget.isLastSelected) {
      _fb.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fb.dispose();
    super.dispose();
  }

  bool get _isCorrectAnswer => widget.isReverse
      ? widget.item.note.split('/').any((p) => widget.correctAnswer.split('/').contains(p))
      : areEnharmonicEquivalent(widget.item.note, widget.correctAnswer);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isReverse = widget.isReverse;
    final showFeedback = widget.showFeedback;
    final isLastSelected = widget.isLastSelected;
    final notation = widget.notation;
    final noteColor = isReverse
        ? (AppColors.degreeColors[item.note.split('/')[0]] ?? Colors.white)
        : (AppColors.noteColors[item.note] ?? Colors.white);
    final isActive = !showFeedback;

    // The web buttons have NO border in any state (borderWidth 0); colour comes
    // entirely from the fill. We mirror that exactly.
    Color textColor;
    Color? bgSolid;
    List<BoxShadow>? shadows;

    if (showFeedback && _isCorrectAnswer && isLastSelected) {
      // Correct answer: solid white fill, dark label, white glow.
      bgSolid = Colors.white;
      textColor = const Color(0xFF020617);
      shadows = [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 50)];
    } else if (showFeedback && _isCorrectAnswer && !isLastSelected) {
      // Reveal the correct answer after a wrong guess: a FULL green fill
      // (web rgba(16,185,129,0.5)), white label, green glow — no outline.
      bgSolid = const Color(0xFF10B981).withValues(alpha: 0.5);
      textColor = Colors.white;
      shadows = [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 40)];
    } else if (showFeedback && isLastSelected && !_isCorrectAnswer) {
      // Wrong selection: solid red fill, white label, red glow.
      bgSolid = const Color(0xFFF43F5E);
      textColor = Colors.white;
      shadows = [BoxShadow(color: const Color(0xFFF43F5E).withValues(alpha: 0.7), blurRadius: 50)];
    } else {
      // Default: subtle white fill + a note-colour tint (below), no border.
      bgSolid = Colors.white.withValues(alpha: 0.05);
      textColor = noteColor;
      shadows = const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8))];
    }

    final button = GestureDetector(
      onTapDown: isActive ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isActive ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
      onTapCancel: isActive ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: (_pressed && isActive) ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bgSolid,
          borderRadius: BorderRadius.circular(24),
          boxShadow: shadows,
        ),
        child: Stack(
          children: [
            // Inner note color tint — shown unless this specific button has a feedback style
            if (!(showFeedback && (_isCorrectAnswer || isLastSelected)))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: (isReverse
                        ? (AppColors.degreeColors[item.note.split('/')[0]] ?? Colors.white)
                        : (AppColors.noteColors[item.note] ?? Colors.white)).withAlpha(26),
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // The label starts large and only shrinks as much as needed to fit
                // the square — long enharmonic labels (e.g. "E♭/D♯") scale down,
                // single notes stay big.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isReverse
                      ? NoteText(
                          note: item.label,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor))
                      : NoteText(
                          note: formatNoteForDisplay(item.label, notation),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );

    // Bounce (correct) / shake (wrong) on the button the user actually pressed.
    final animated = AnimatedBuilder(
      animation: _fb,
      builder: (_, child) {
        if (!(widget.showFeedback && widget.isLastSelected)) return child!;
        final dx = _isCorrectAnswer ? 0.0 : _shake.value;
        final dy = _isCorrectAnswer ? _bounce.value : 0.0;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: button,
    );

    // Green checkmark badge when this is the correct answer after a wrong guess
    if (showFeedback && _isCorrectAnswer && !isLastSelected) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x5010B981), blurRadius: 10)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      );
    }

    return animated;
  }
}

// ─── PIANO KEYBOARD ──────────────────────────────────────────────────────────
// 3D single-octave piano (C..B). White keys flex equally; black keys overlap the
// joints (9% width, centered on the boundaries). A key is "active" when its
// pitch is one of the current answer options — inactive keys are dimmed.

class _KeyDef {
  final String name;
  final int semitone;
  final bool black;
  final double frac; // center position (fraction of width) for black keys
  const _KeyDef(this.name, this.semitone, this.black, [this.frac = 0]);
}

class _PianoKeyboard extends StatelessWidget {
  final List<NoteItem> notes;
  final bool showFeedback;
  final String correctAnswer;
  final String? lastSelected;
  final String notation;
  final double height;
  final int startWhiteSemitone; // semitone of the leftmost white key (0 = C)
  // Non-null in CHROMATIC mode: key labels are then spelled by relative degree
  // (1 ♭2 2 ♭3 3 4 ♯4 5 ♭6 6 ♭7 7 of this tonic) instead of the button names.
  final String? chromaticTonic;
  final void Function(String) onSelect;

  const _PianoKeyboard({
    required this.notes,
    required this.showFeedback,
    required this.correctAnswer,
    required this.lastSelected,
    required this.notation,
    required this.height,
    this.startWhiteSemitone = 0,
    this.chromaticTonic,
    required this.onSelect,
  });

  // Build one octave of keys whose leftmost white key has semitone [startSemi].
  // Yields 7 white keys + all applicable black keys (normally 5, or 6 if needed).
  // When the starting white is not C, the rightmost black key (e.g., F♯ when
  // starting from G) is rendered at the octave boundary without adding a duplicate white.
  // scaleNames overrides the default flat names for black keys that are diatonic in
  // the current key (e.g. semitone 8 → 'G♯' in A major instead of 'A♭').
  static (List<_KeyDef>, List<_KeyDef>) _buildKeys(int startSemi, Map<int, String> scaleNames) {
    const order = [
      ('C', 0), ('D', 2), ('E', 4), ('F', 5), ('G', 7), ('A', 9), ('B', 11),
    ];
    const blackDefault = {1: 'C♯', 3: 'E♭', 6: 'F♯', 8: 'A♭', 10: 'B♭'};
    var s = order.indexWhere((e) => e.$2 == startSemi);
    if (s < 0) s = 0;
    final whites = [
      for (var k = 0; k < 7; k++)
        _KeyDef(order[(s + k) % 7].$1, order[(s + k) % 7].$2, false),
    ];
    final blacks = <_KeyDef>[];
    for (var k = 0; k < 6; k++) {
      final cur = whites[k].semitone, nxt = whites[k + 1].semitone;
      if ((nxt - cur + 12) % 12 == 2) {
        final bs = (cur + 1) % 12;
        final name = scaleNames[bs] ?? blackDefault[bs]!;
        blacks.add(_KeyDef(name, bs, true, (k + 1) / 7));
      }
    }
    // Check if there's a black key between the last white key and the first white of the next octave.
    // E.g., when starting from G, the last white is F(5), and the next octave's first white is G(7) —
    // F♯(6) should be included. Render it to the right of F, properly positioned.
    final last = whites.last.semitone;
    final nextOctaveFirst = (whites.first.semitone + 12) % 12;
    if ((nextOctaveFirst - last + 12) % 12 == 2) {
      final bs = (last + 1) % 12;
      final name = scaleNames[bs] ?? blackDefault[bs]!;
      blacks.add(_KeyDef(name, bs, true, 6.75 / 7));
    }
    return (whites, blacks);
  }

  @override
  Widget build(BuildContext context) {
    // Chromatic mode spells keys by relative degree of the tonic; other modes
    // take the names straight from the answer buttons (diatonic spelling).
    final scaleNames = chromaticTonic != null
        ? chromaticKeyboardNoteNames(chromaticTonic!)
        : <int, String>{
            for (final n in notes)
              if (kNoteToSemitone[n.note] != null) kNoteToSemitone[n.note]!: n.note,
          };
    final (whites, blacks) = _buildKeys(startWhiteSemitone, scaleNames);
    // Which semitones are valid answer options right now
    final active = <int>{};
    for (final n in notes) {
      if (n.disabled) continue;
      final s = kNoteToSemitone[n.note];
      if (s != null) active.add(s);
    }
    final correctSemi = kNoteToSemitone[correctAnswer];
    final selectedSemi = lastSelected != null ? kNoteToSemitone[lastSelected!] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(51), // bg-black/20
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(26)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13), // bg-white/5 base (visible as the 3D lip)
                    border: Border.all(color: Colors.white.withAlpha(26)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(
                    builder: (ctx, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      final whiteW = w / 7;
                      final blackW = whiteW * 0.62;
                      final blackH = h * 0.65;
                      return Stack(
                        children: [
                          // White keys (bottom layer) — positioned so each fills full height
                          for (int i = 0; i < whites.length; i++)
                            Positioned(
                              left: i * whiteW,
                              top: 0,
                              width: whiteW,
                              height: h,
                              child: _PianoKey(
                                def: whites[i],
                                active: active.contains(whites[i].semitone),
                                isCorrect: correctSemi == whites[i].semitone,
                                isSelected: selectedSemi == whites[i].semitone,
                                showFeedback: showFeedback,
                                notation: notation,
                                onTap: () => onSelect(whites[i].name),
                              ),
                            ),
                          // Thin separators between adjacent white keys (real-piano look)
                          for (int i = 1; i < whites.length; i++)
                            Positioned(
                              left: i * whiteW - 0.5,
                              top: 0,
                              width: 1,
                              height: h,
                              child: const ColoredBox(color: Color(0xFFCBD5E1)),
                            ),
                          // Black keys (top layer)
                          for (final k in blacks)
                            Positioned(
                              left: k.frac * w - blackW / 2,
                              top: 0,
                              width: blackW,
                              height: blackH,
                              child: _PianoKey(
                                def: k,
                                active: active.contains(k.semitone),
                                isCorrect: correctSemi == k.semitone,
                                isSelected: selectedSemi == k.semitone,
                                showFeedback: showFeedback,
                                notation: notation,
                                onTap: () => onSelect(k.name),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PianoKey extends StatefulWidget {
  final _KeyDef def;
  final bool active;
  final bool isCorrect;
  final bool isSelected;
  final bool showFeedback;
  final String notation;
  final VoidCallback onTap;

  const _PianoKey({
    required this.def,
    required this.active,
    required this.isCorrect,
    required this.isSelected,
    required this.showFeedback,
    required this.notation,
    required this.onTap,
  });

  @override
  State<_PianoKey> createState() => _PianoKeyState();
}

class _PianoKeyState extends State<_PianoKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isBlack = widget.def.black;
    final noteColor = AppColors.noteColors[widget.def.name] ?? Colors.white;
    final tappable = widget.active && !widget.showFeedback;

    Color bg;
    Color labelColor;
    List<BoxShadow> shadows = const [];
    final inScale = widget.active;

    if (widget.showFeedback && widget.isCorrect) {
      // Correct pitch — fill with its tonal color + neon glow
      bg = noteColor;
      labelColor = Colors.white;
      shadows = [BoxShadow(color: noteColor.withAlpha(136), blurRadius: 30)]; // color88
    } else if (widget.showFeedback && widget.isSelected && !widget.isCorrect) {
      // Wrong pick — red
      bg = const Color(0xFFF43F5E);
      labelColor = Colors.white;
      shadows = const [BoxShadow(color: Color(0xB3F43F5E), blurRadius: 30)];
    } else {
      // Idle key — identical background whether the note is in the scale or not.
      // Only the LABEL colour distinguishes them: tonal colour for scale notes,
      // grey for the rest. No transparency / dimming on the key itself.
      bg = isBlack ? const Color(0xFF1E293B) : Colors.white;
      labelColor = inScale
          ? noteColor // pure tonal color on the label, like the web app
          : (isBlack ? const Color(0xFF64748B) : const Color(0xFF94A3B8)); // grey
      if (isBlack) {
        shadows = const [BoxShadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 6))];
      }
    }

    final dy = _pressed ? (isBlack ? 6.0 : 10.0) : 0.0;

    return GestureDetector(
      onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: tappable ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
      onTap: tappable
          ? () { HapticsService.impactLight(); widget.onTap(); }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, dy, 0),
        decoration: BoxDecoration(
          color: bg,
          // White keys are seamless — outer corners come from the container clip.
          borderRadius: isBlack
              ? const BorderRadius.vertical(bottom: Radius.circular(6))
              : null,
          border: isBlack ? Border.all(color: Colors.white.withAlpha(26)) : null,
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            NoteText(
              note: formatNoteForDisplay(widget.def.name, widget.notation),
              style: TextStyle(
                fontSize: isBlack ? 12 : 16,
                fontWeight: FontWeight.w900,
                color: labelColor,
              ),
            ),
            SizedBox(height: isBlack ? 10 : 16),
          ],
        ),
      ),
    );
  }
}
