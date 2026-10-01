import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import '../l10n/l10n.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_info.dart';
import '../models/daily_challenge.dart';
import '../models/training_mode.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../services/haptics_service.dart';
import '../constants/app_colors.dart';
import '../widgets/note_text.dart';
import '../constants/app_scroll.dart';

/// Result screen for the Daily Challenge — the once-a-day moment, so it gets
/// its own stage instead of the standard session summary: verdict + score,
/// the answer grid, the challenge streak with its month calendar, and
/// the share button (Wordle-style text grid — pasteable anywhere).
///
/// No "retry": one attempt per day is the whole point.
class DailyResultsScreen extends StatefulWidget {
  final VoidCallback onDone;
  const DailyResultsScreen({super.key, required this.onDone});

  @override
  State<DailyResultsScreen> createState() => _DailyResultsScreenState();
}

class _DailyResultsScreenState extends State<DailyResultsScreen> {
  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFCD34D);

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps the "new challenge in…" countdown honest while the screen is up.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _untilMidnight() {
    final now = DateTime.now();
    final mid = DateTime(now.year, now.month, now.day + 1);
    final d = mid.difference(now);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static String _fmtTime(int ms) {
    final secs = (ms / 1000).round();
    return secs >= 60
        ? '${secs ~/ 60}m ${(secs % 60).toString().padLeft(2, '0')}s'
        : '${secs}s';
  }

  String _verdict(BuildContext context, DailyResult r) {
    final l = context.l10n;
    if (r.perfect) return l.dailyFlawless;
    // Under a 60-second budget, an unfinished run means the clock won.
    if (!r.completed) return l.dailyOutOfTime;
    // Shares of the run, not counts: these were written for ten questions,
    // and when the daily grew to fifteen they went on calling 6/15 solid.
    final share = _shareOf(r);
    if (share >= 0.8) return l.dailySharp;
    if (share >= 0.6) return l.dailySolid;
    if (share >= 0.4) return l.dailyWarmingUp;
    return l.dailyTomorrow;
  }

  static double _shareOf(DailyResult r) => r.total == 0 ? 0 : r.correct / r.total;

  Future<void> _share(DailyResult r, int streak) async {
    HapticsService.impactMedium();
    AnalyticsService.instance.capture(Ev.dailyShared, {
      'correct': r.correct,
      'total': r.total,
    });
    final text = buildDailyShareText(r, streak,
        installUrl: installUrlFor(defaultTargetPlatform, isWeb: kIsWeb));
    try {
      // The iPad's popover needs an anchor or the plugin throws; see the
      // same call in DailyChallengeCard.
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        text,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      // No share sheet on this platform (e.g. web without navigator.share):
      // fall back to the clipboard rather than leaving a dead button.
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.dailyCopied),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// The card the screen is built around, and the picture that gets shared:
  /// what you see is exactly what lands in the chat.
  final _cardKey = GlobalKey();

  Future<void> _shareImage(DailyResult r, int streak) async {
    HapticsService.impactMedium();
    AnalyticsService.instance.capture(Ev.dailyShared, {
      'correct': r.correct,
      'total': r.total,
      'as': 'image',
    });
    final text = buildDailyShareText(r, streak,
        installUrl: installUrlFor(defaultTargetPlatform, isWeb: kIsWeb));
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3);
      final bytes = await image?.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no card to capture');
      await Share.shareXFiles(
        [
          XFile.fromData(bytes.buffer.asUint8List(),
              mimeType: 'image/png', name: 'improvy-daily.png'),
        ],
        text: text,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      // No picture (or no file sharing here): the text result still travels.
      await _share(r, streak);
    }
  }

  /// The verdict's colour — the same ladder the session summary uses.
  static Color _accent(DailyResult r) => r.perfect
      ? _gold
      : _shareOf(r) >= 0.6
          ? _mint
          : _shareOf(r) >= 0.4
              ? _orange
              : _rose;

  static const _mint = Color(0xFF10B981);
  static const _orange = Color(0xFFF97316);
  static const _rose = Color(0xFFF43F5E);

  IconData _verdictIcon(DailyResult r) => r.perfect
      ? Icons.auto_awesome_rounded
      : !r.completed
          ? Icons.timer_off_rounded
          : _shareOf(r) >= 0.6
              ? Icons.check_circle_rounded
              : Icons.trending_up_rounded;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final result = provider.activeDailyResult ?? provider.todayDailyResult;
    final degrees = provider.activeDailyDegrees;
    final streak = provider.dailyStreak;
    final notation = provider.notation;
    final l = context.l10n;

    if (result == null) {
      return Scaffold(backgroundColor: AppColors.background, body: _fallback());
    }
    final accent = _accent(result);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // The summary's atmosphere, warmed toward the daily's gold.
        Positioned(top: -120, left: -80, child: _Blob(size: 340, color: _gold.withValues(alpha: 0.09))),
        Positioned(bottom: -60, right: -60, child: _Blob(size: 260, color: const Color(0xFF7C3AED).withValues(alpha: 0.10))),
        SafeArea(
          child: Column(children: [
            // ── Header, as on the session summary ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                _SquareBtn(icon: Icons.close_rounded, onTap: widget.onDone),
                Expanded(
                  child: Column(children: [
                    Text(l.dailyTitle,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _goldSoft,
                            letterSpacing: 3)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (result.mode == TrainingMode.ofWhat)
                          Text(l.dailySubjectOn,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.4))),
                        NoteText(
                          note: formatNoteForDisplay(result.key, notation),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                        Text(
                          result.mode == TrainingMode.ofWhat
                              ? ' · ${result.mode.localizedName(l)}'
                              : ' ${l.dailyMajorSuffix} · ${result.mode.localizedName(l)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(width: 40),
              ]),
            ),
            Expanded(
              // Content fades under the header and above the buttons rather
              // than being cut off by a hard edge.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (b) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                  stops: [0, 0.04, 0.95, 1],
                ).createShader(b),
                child: SingleChildScrollView(
                physics: kAppScrollPhysics,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // The card is also the picture Share sends.
                  RepaintBoundary(
                    key: _cardKey,
                    child: _ScoreCard(
                      result: result,
                      streak: streak,
                      accent: accent,
                      verdict: _verdict(context, result),
                      verdictIcon: _verdictIcon(result),
                      time: _fmtTime(result.timeMs),
                      notation: notation,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: l.dailyTheRun,
                    trailing: Text('${result.correct}/${result.total}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5))),
                    child: _RunGrid(result: result, degrees: degrees),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    title: l.dailyStreak,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      const _Flame(size: 15),
                      const SizedBox(width: 4),
                      Text(l.dailyStreakDays(streak),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _goldSoft)),
                    ]),
                    child: _WeekStrip(results: provider.dailyResults),
                  ),
                ]),
              ),
              ),
            ),
            // ── Actions, pinned like the summary's ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(children: [
                _ShareBtn(label: l.dailyShare.toUpperCase(), onTap: () => _shareImage(result, streak)),
                const SizedBox(height: 10),
                _HomeBtn(label: l.done.toUpperCase(), onTap: widget.onDone),
                const SizedBox(height: 12),
                Text(
                  l.dailyNewIn(_untilMidnight()),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white.withValues(alpha: 0.3)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // Should never happen (the screen only shows after a recorded run), but a
  // dead-end with no way home would be worse than a plain exit.
  Widget _fallback() => Center(
        child: TextButton(
          onPressed: widget.onDone,
          child: Text(context.l10n.dailyBackHome,
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
        ),
      );
}

/// The result as one object — and the image that gets shared, so it carries
/// the app's name and address. Framed like the home screen's Total Progress
/// card: a rainbow edge around a dark plate.
class _ScoreCard extends StatelessWidget {
  final DailyResult result;
  final int streak;
  final Color accent;
  final String verdict;
  final IconData verdictIcon;
  final String time;
  final String notation;
  const _ScoreCard({
    required this.result,
    required this.streak,
    required this.accent,
    required this.verdict,
    required this.verdictIcon,
    required this.time,
    required this.notation,
  });

  static const _rainbow = [
    Color(0xFFF97316), Color(0xFFEAB308), Color(0xFF22C55E),
    Color(0xFF3B82F6), Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFFF97316),
  ];

  List<Color> get _scoreColors => result.perfect
      ? const [Color(0xFFFDE68A), Color(0xFFF59E0B)]
      : [Color.lerp(accent, Colors.white, 0.35)!, accent];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result;
    DateTime d;
    try {
      d = DateTime.parse(r.dateKey);
    } catch (_) {
      d = DateTime.now();
    }
    final date = DateFormat('d MMM yyyy').format(d).toUpperCase();
    final label = TextStyle(
        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white.withValues(alpha: 0.3));
    const value = TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const SweepGradient(colors: _rainbow),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241D33), Color(0xFF16121F)],
          ),
        ),
        child: Stack(children: [
          // The verdict's light pooled behind the ring.
          Positioned(
            top: 36,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(children: [
              Row(children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFFF43F5E)],
                  ).createShader(b),
                  child: const Text('IMPROVY',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                ),
                const Spacer(),
                Text(date, style: label),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: 204,
                height: 204,
                child: CustomPaint(
                  painter: _RunRing(
                    answers: r.answers,
                    right: r.perfect ? _DailyResultsScreenState._gold : const Color(0xFF34D399),
                    wrong: const Color(0xFFFB7185),
                  ),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: _scoreColors,
                            ).createShader(b),
                            child: Text('${r.correct}',
                                style: const TextStyle(
                                    fontSize: 76, fontWeight: FontWeight.w900, height: 1, letterSpacing: -4, color: Colors.white)),
                          ),
                          Text('/${r.total}',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.3))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l.dailyCardScore, style: label),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // The badge, as the summary's "LEVEL PASSED".
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 20)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(verdictIcon, color: accent, size: 15),
                  const SizedBox(width: 8),
                  Text(verdict,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: accent, letterSpacing: 1.5)),
                ]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Expanded(
                      child: _Stat(
                        label: r.mode == TrainingMode.ofWhat ? l.dailyCardOn : l.dailyCardKey,
                        labelStyle: label,
                        child: NoteText(note: formatNoteForDisplay(r.key, notation), style: value),
                      ),
                    ),
                    _divider(),
                    Expanded(child: _Stat(label: l.dailyCardTime, labelStyle: label, child: Text(time, style: value))),
                    _divider(),
                    Expanded(
                      child: _Stat(
                        label: l.dailyCardStreak,
                        labelStyle: label,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const _Flame(size: 16),
                          const SizedBox(width: 3),
                          Text('$streak', style: value),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Text('improvy.app',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.25))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _divider() => Container(width: 1, color: Colors.white.withValues(alpha: 0.07));
}

class _Stat extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final Widget child;
  const _Stat({required this.label, required this.labelStyle, required this.child});

  @override
  Widget build(BuildContext context) => Column(children: [
        FittedBox(fit: BoxFit.scaleDown, child: child),
        const SizedBox(height: 4),
        Text(label, style: labelStyle),
      ]);
}

/// The run as a ring: one arc per question, in the order they were asked,
/// starting at twelve o'clock.
class _RunRing extends CustomPainter {
  final List<bool> answers;
  final Color right;
  final Color wrong;
  _RunRing({required this.answers, required this.right, required this.wrong});

  @override
  void paint(Canvas canvas, Size size) {
    final n = answers.isEmpty ? 1 : answers.length;
    const stroke = 10.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke);
    canvas.drawCircle(
        rect.center,
        rect.width / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = Colors.white.withValues(alpha: 0.06));
    const gap = 0.10;
    final sweep = 2 * math.pi / n;
    for (var i = 0; i < answers.length; i++) {
      final c = answers[i] ? right : wrong;
      final start = -math.pi / 2 + i * sweep + gap / 2;
      canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 6
            ..strokeCap = StrokeCap.round
            ..color = c.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = c);
    }
  }

  @override
  bool shouldRepaint(_RunRing old) => old.answers != answers;
}

/// The questions in order: the degree asked, in the app's tile style, green
/// when right and red when not.
class _RunGrid extends StatelessWidget {
  final DailyResult result;
  final List<String> degrees;
  const _RunGrid({required this.result, required this.degrees});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const perRow = 5;
        const gap = 8.0;
        final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(result.answers.length, (i) {
            final ok = result.answers[i];
            // "♯4/♭5" asks one question; the first spelling names it.
            final deg = i < degrees.length ? degrees[i].split('/').first : '?';
            final col = ok ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
            return Container(
              width: w,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [col.withValues(alpha: 0.20), col.withValues(alpha: 0.08)],
                ),
                border: Border.all(color: col.withValues(alpha: 0.35), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NoteText(
                  note: deg,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: ok ? const Color(0xFF6EE7B7) : const Color(0xFFFDA4AF)),
                ),
              ),
            );
          }),
        );
      });
}

/// The summary's card: a quiet plate with a tracked-out label.
class _Card extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;
  const _Card({required this.title, required this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.3))),
            const Spacer(),
            trailing,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      );
}

/// The daily's primary action, in its gold.
class _ShareBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ShareBtn({required this.label, required this.onTap});

  @override
  State<_ShareBtn> createState() => _ShareBtnState();
}

class _ShareBtnState extends State<_ShareBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(widget.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF2A1B04))),
              const SizedBox(width: 10),
              const Icon(Icons.ios_share_rounded, color: Color(0xFF2A1B04), size: 18),
            ]),
          ),
        ),
      );
}

class _HomeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HomeBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.home_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ),
      );
}

/// The streak's flame, drawn rather than typed.
class _Flame extends StatelessWidget {
  final double size;
  const _Flame({required this.size});

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFF97316), Color(0xFFFCD34D)],
        ).createShader(r),
        child: Icon(Icons.local_fire_department_rounded, size: size, color: Colors.white),
      );
}

/// The last seven days, ending today: which dailies were played, which were
/// perfect.
class _WeekStrip extends StatelessWidget {
  final Map<String, DailyResult> results;
  const _WeekStrip({required this.results});

  static const _gold = Color(0xFFFBBF24);

  String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final locale = Localizations.localeOf(context).toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 6; i >= 0; i--) _day(today.subtract(Duration(days: i)), i == 0, locale),
      ],
    );
  }

  Widget _day(DateTime d, bool isToday, String locale) {
    final r = results[_dk(d)];
    final played = r != null;
    final perfect = r?.perfect ?? false;
    return Column(children: [
      Text(DateFormat.E(locale).format(d).substring(0, 1).toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: isToday ? 0.8 : 0.3))),
      const SizedBox(height: 8),
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: played
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                )
              : null,
          color: played ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: played
                ? const Color(0xFFFDE68A).withValues(alpha: 0.6)
                : isToday
                    ? _gold.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.07),
            width: isToday && !played ? 1.5 : 1,
          ),
          boxShadow: played ? [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 10)] : null,
        ),
        child: Center(
          child: played
              ? Icon(perfect ? Icons.star_rounded : Icons.check_rounded, size: 17, color: const Color(0xFF3A2405))
              : Text('${d.day}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.3))),
        ),
      ),
    ]);
  }
}
