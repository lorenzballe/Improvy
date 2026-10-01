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

  Color _accent(DailyResult r) => r.perfect
      ? _gold
      : _shareOf(r) >= 0.6
          ? _mint
          : _shareOf(r) >= 0.4
              ? const Color(0xFFFB923C)
              : _rose;

  static const _mint = Color(0xFF34D399);
  static const _rose = Color(0xFFFB7185);
  static const _ink = Color(0xFF0B0712);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final result = provider.activeDailyResult ?? provider.todayDailyResult;
    final degrees = provider.activeDailyDegrees;
    final streak = provider.dailyStreak;
    final notation = provider.notation;
    final accent = result == null ? _gold : _accent(result);

    return Scaffold(
      backgroundColor: _ink,
      body: Stack(children: [
        // One light, in the verdict's colour, falling from above the card.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.05),
                radius: 1.1,
                colors: [accent.withValues(alpha: 0.20), Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: result == null
              ? _fallback()
              : SingleChildScrollView(
                  physics: kAppScrollPhysics,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(result),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _cardKey,
                        child: _ScoreCard(
                          result: result,
                          streak: streak,
                          accent: accent,
                          verdict: _verdict(context, result),
                          time: _fmtTime(result.timeMs),
                          notation: notation,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _questionGrid(result, degrees, notation),
                      const SizedBox(height: 14),
                      _streakCard(provider, streak),
                      const SizedBox(height: 22),
                      _shareButton(result, streak),
                      const SizedBox(height: 6),
                      _doneLink(),
                      Text(
                        context.l10n.dailyNewIn(_untilMidnight()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.32)),
                      ),
                    ],
                  ),
                ),
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
              style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
        ),
      );

  Widget _topBar(DailyResult result) {
    return Row(children: [
      Text(context.l10n.dailyTitle,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: Colors.white.withValues(alpha: 0.55))),
      const Spacer(),
      GestureDetector(
        onTap: widget.onDone,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.7), size: 19),
        ),
      ),
    ]);
  }

  /// The questions in order: the degree asked, tinted by how it went.
  Widget _questionGrid(DailyResult r, List<String> degrees, String notation) {
    return _Panel(
      title: context.l10n.dailyTheRun,
      trailing: Text('${r.correct}/${r.total}',
          style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55))),
      child: LayoutBuilder(builder: (context, c) {
        const perRow = 5;
        const gap = 8.0;
        final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(r.answers.length, (i) {
            final ok = r.answers[i];
            // "♯4/♭5" asks one question; the first spelling names it.
            final deg = i < degrees.length ? degrees[i].split('/').first : '?';
            final c = ok ? _mint : _rose;
            return Container(
              width: w,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: c.withValues(alpha: ok ? 0.10 : 0.14),
              ),
              child: Stack(children: [
                Center(
                  child: NoteText(
                    note: deg,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ok ? Colors.white.withValues(alpha: 0.92) : _rose),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                  ),
                ),
              ]),
            );
          }),
        );
      }),
    );
  }

  Widget _streakCard(AppProvider provider, int streak) {
    return _Panel(
      title: context.l10n.dailyStreak,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        const _Flame(size: 15),
        const SizedBox(width: 4),
        Text(context.l10n.dailyStreakDays(streak),
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _goldSoft)),
      ]),
      child: _WeekStrip(results: provider.dailyResults),
    );
  }

  Widget _shareButton(DailyResult r, int streak) => GestureDetector(
        onTap: () => _shareImage(r, streak),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.ios_share_rounded, size: 19, color: _ink),
              const SizedBox(width: 9),
              Text(context.l10n.dailyShare,
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
            ]),
          ),
        ),
      );

  Widget _doneLink() => TextButton(
        onPressed: widget.onDone,
        child: Text(context.l10n.done,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6))),
      );
}

/// The result as one object: the run drawn as a ring of questions around the
/// score, and what it was played in underneath. It is also the image the share
/// button sends, so it carries its own name and address.
class _ScoreCard extends StatelessWidget {
  final DailyResult result;
  final int streak;
  final Color accent;
  final String verdict;
  final String time;
  final String notation;
  const _ScoreCard({
    required this.result,
    required this.streak,
    required this.accent,
    required this.verdict,
    required this.time,
    required this.notation,
  });

  static const _mint = Color(0xFF34D399);
  static const _rose = Color(0xFFFB7185);

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
    final date = DateFormat('d MMM yyyy', Localizations.localeOf(context).toString())
        .format(d)
        .toUpperCase();
    final label = TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: Colors.white.withValues(alpha: 0.42));
    const value = TextStyle(
        fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241640), Color(0xFF150D26), Color(0xFF0E0819)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(children: [
          // The verdict's light, pooled behind the ring.
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(children: [
              Row(children: [
                const Text('IMPROVY',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.2,
                        color: Colors.white)),
                const Spacer(),
                Text(date, style: label),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                width: 212,
                height: 212,
                child: CustomPaint(
                  painter: _RunRing(
                      answers: r.answers,
                      // A flawless run is the one day the ring turns gold.
                      right: r.perfect ? const Color(0xFFFCD34D) : _mint,
                      wrong: _rose),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${r.correct}',
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 72,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  letterSpacing: -2.5,
                                  color: Colors.white)),
                          Text('/${r.total}',
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.38))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(verdict,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.6,
                              color: accent)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(
                    child: _Stat(
                      // An …Of What? day is built ON a note, not played in a key.
                      label: r.mode == TrainingMode.ofWhat ? l.dailyCardOn : l.dailyCardKey,
                      labelStyle: label,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        NoteText(note: formatNoteForDisplay(r.key, notation), style: value),
                        if (r.mode != TrainingMode.ofWhat)
                          Text(' ${l.dailyMajorSuffix}',
                              style: value.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.6))),
                      ]),
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _Stat(
                      label: l.dailyCardTime,
                      labelStyle: label,
                      child: Text(time, style: value),
                    ),
                  ),
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
              const SizedBox(height: 14),
              Text('improvy.app',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.32))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final Widget child;
  const _Stat({required this.label, required this.labelStyle, required this.child});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: child),
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
    const stroke = 9.0;
    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(rect.center, rect.width / 2, track);
    const gap = 0.09; // radians between arcs
    final sweep = 2 * math.pi / n;
    for (var i = 0; i < answers.length; i++) {
      final c = answers[i] ? right : wrong;
      final start = -math.pi / 2 + i * sweep + gap / 2;
      // A soft halo under each arc, then the arc itself.
      canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 6
            ..strokeCap = StrokeCap.round
            ..color = c.withValues(alpha: 0.16)
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

/// A quiet section: a small tracked label, something on the right, content.
class _Panel extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;
  const _Panel({required this.title, required this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.045),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.45))),
            const Spacer(),
            trailing,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

/// The streak's flame, drawn rather than typed: an emoji is the one thing on
/// this screen that would look different on every phone.
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
/// perfect. A month of mostly empty squares said less than this, at four
/// times the height.
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
        for (var i = 6; i >= 0; i--) _day(context, today.subtract(Duration(days: i)), i == 0, locale),
      ],
    );
  }

  Widget _day(BuildContext context, DateTime d, bool isToday, String locale) {
    final r = results[_dk(d)];
    final played = r != null;
    final perfect = r?.perfect ?? false;
    return Column(children: [
      Text(DateFormat.E(locale).format(d).substring(0, 1).toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: isToday ? 0.85 : 0.35))),
      const SizedBox(height: 8),
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: played
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                )
              : null,
          color: played ? null : Colors.white.withValues(alpha: 0.06),
          border: isToday && !played
              ? Border.all(color: _gold.withValues(alpha: 0.7), width: 1.4)
              : null,
        ),
        child: Center(
          child: played
              ? Icon(perfect ? Icons.star_rounded : Icons.check_rounded,
                  size: 17, color: const Color(0xFF3A2405))
              : Text('${d.day}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.35))),
        ),
      ),
    ]);
  }
}
