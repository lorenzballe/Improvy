import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../models/daily_challenge.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../services/haptics_service.dart';
import '../widgets/note_text.dart';
import '../constants/app_scroll.dart';

/// Result screen for the Daily Challenge — the once-a-day moment, so it gets
/// its own stage instead of the standard session summary: verdict + score,
/// the 10-question grid, the challenge streak with its month calendar, and
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
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

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
    if (r.correct >= 8) return l.dailySharp;
    if (r.correct >= 6) return l.dailySolid;
    if (r.correct >= 4) return l.dailyWarmingUp;
    return l.dailyTomorrow;
  }

  Future<void> _share(DailyResult r, int streak) async {
    HapticsService.impactMedium();
    AnalyticsService.instance.capture(Ev.dailyShared, {
      'correct': r.correct,
      'total': r.total,
    });
    final text = buildDailyShareText(r, streak,
        installUrl: installUrlFor(defaultTargetPlatform, isWeb: kIsWeb));
    try {
      await Share.share(text);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final result = provider.activeDailyResult ?? provider.todayDailyResult;
    final degrees = provider.activeDailyDegrees;
    final streak = provider.dailyStreak;
    final notation = provider.notation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Same cinematic base as the trainer, warmed toward gold — this is the
        // trophy room, not another question screen.
        Container(color: const Color(0xFF0F0A1A)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -1),
                radius: 1.4,
                colors: [Color(0x33F59E0B), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1, 1),
                radius: 1.5,
                colors: [Color(0x554C1D95), Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: result == null
              ? _fallback()
              : SingleChildScrollView(
                physics: kAppScrollPhysics,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(result),
                      const SizedBox(height: 18),
                      _hero(result, notation),
                      const SizedBox(height: 18),
                      _questionGrid(result, degrees),
                      const SizedBox(height: 14),
                      _streakCard(provider, streak),
                      const SizedBox(height: 22),
                      _shareButton(result, streak),
                      const SizedBox(height: 10),
                      _doneLink(),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.dailyNewIn(_untilMidnight()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.35)),
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
    DateTime d;
    try {
      d = DateTime.parse(result.dateKey);
    } catch (_) {
      d = DateTime.now();
    }
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.dailyTitle,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: _goldSoft)),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE d MMMM').format(d),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45))),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: widget.onDone,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.65), size: 20),
        ),
      ),
    ]);
  }

  Widget _hero(DailyResult r, String notation) {
    final accent = r.perfect
        ? _gold
        : r.correct >= 6
            ? _green
            : r.correct >= 4
                ? const Color(0xFFF97316)
                : _red;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211830), Color(0xFF15101F)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 36,
              spreadRadius: -6,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Text(_verdict(context, r),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
                color: accent)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${r.correct}',
                style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1)),
            Text(' / ${r.total}',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _chip(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              NoteText(
                  note: formatNoteForDisplay(r.key, notation),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _goldSoft)),
              const Text(' major',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _goldSoft)),
            ]),
            border: _gold.withValues(alpha: 0.3),
            fill: _gold.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 8),
          _chip(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_outlined,
                  size: 14, color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(width: 5),
              Text(_fmtTime(r.timeMs),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.75))),
            ]),
            border: Colors.white.withValues(alpha: 0.12),
            fill: Colors.white.withValues(alpha: 0.05),
          ),
        ]),
      ]),
    );
  }

  Widget _chip({required Widget child, required Color border, required Color fill}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: fill,
          border: Border.all(color: border),
        ),
        child: child,
      );

  /// The 10 questions as chips: the degree asked, coloured by the outcome.
  Widget _questionGrid(DailyResult r, List<String> degrees) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.dailyTheRun,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: Colors.white.withValues(alpha: 0.4))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(r.answers.length, (i) {
            final ok = r.answers[i];
            final deg = i < degrees.length ? degrees[i] : '?';
            final c = ok ? _green : _red;
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: c.withValues(alpha: 0.12),
                border: Border.all(color: c.withValues(alpha: 0.45)),
              ),
              child: Center(
                child: Text(deg,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900, color: c)),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _streakCard(AppProvider provider, int streak) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(context.l10n.dailyStreak,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: Colors.white.withValues(alpha: 0.4))),
          const Spacer(),
          Text('🔥 $streak ${streak == 1 ? 'day' : 'days'}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900, color: _goldSoft)),
        ]),
        const SizedBox(height: 14),
        _MonthCalendar(results: provider.dailyResults),
      ]),
    );
  }

  Widget _shareButton(DailyResult r, int streak) => GestureDetector(
        onTap: () => _share(r, streak),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFCE7A6), Color(0xFFF7C955), Color(0xFFE8A22B)],
            ),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -8),
            ],
          ),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.ios_share_rounded, size: 19, color: Color(0xFF2A1B04)),
              SizedBox(width: 9),
              Text(context.l10n.dailyShare,
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A1B04))),
            ]),
          ),
        ),
      );

  Widget _doneLink() => TextButton(
        onPressed: widget.onDone,
        child: Text(context.l10n.done,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5))),
      );
}

/// Current month, Monday-first: played days fill gold (perfect days glow),
/// today outlines gold until played, the rest stay quiet.
class _MonthCalendar extends StatelessWidget {
  final Map<String, DailyResult> results;
  const _MonthCalendar({required this.results});

  static const _gold = Color(0xFFFBBF24);

  String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leading = (first.weekday - DateTime.monday) % 7; // blanks before day 1

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final cells = <Widget>[
      for (final l in labels)
        Center(
          child: Text(l,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.3))),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _dayCell(DateTime(now.year, now.month, day), now),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      children: cells,
    );
  }

  Widget _dayCell(DateTime date, DateTime now) {
    final r = results[_dk(date)];
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

    Color? fill;
    Color? border;
    Color ink = Colors.white.withValues(alpha: isFuture ? 0.18 : 0.4);
    FontWeight weight = FontWeight.w600;

    if (r != null) {
      fill = _gold.withValues(alpha: r.perfect ? 0.9 : 0.55);
      ink = const Color(0xFF2A1B04);
      weight = FontWeight.w900;
      if (r.perfect) border = const Color(0xFFFCD34D);
    } else if (isToday) {
      border = _gold.withValues(alpha: 0.7);
      ink = const Color(0xFFFCD34D);
      weight = FontWeight.w900;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: fill,
        border: border != null ? Border.all(color: border, width: 1.4) : null,
      ),
      child: Center(
        child: Text('${date.day}',
            style: TextStyle(fontSize: 11, fontWeight: weight, color: ink)),
      ),
    );
  }
}
