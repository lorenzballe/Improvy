import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/daily_challenge.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../services/haptics_service.dart';
import 'note_text.dart';

/// Home-screen hero for the Daily Challenge. Two states:
///  • not played — key of the day, "10 questions · beat the clock", gold CTA feel;
///  • played — today's score with the ✓/✗ dot row, the countdown to midnight,
///    and a share button (same Wordle-style text as the results screen).
///
/// Free for everyone by design: the daily is the app's retention engine, and
/// every share is free acquisition.
class DailyChallengeCard extends StatefulWidget {
  final VoidCallback onStart;
  const DailyChallengeCard({super.key, required this.onStart});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  static const _gold = Color(0xFFFBBF24);
  static const _goldSoft = Color(0xFFFCD34D);
  static const _goldDeep = Color(0xFFF59E0B);
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  Timer? _tick;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // The countdown (and the midnight flip back to "play me") stay fresh.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
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

  Future<void> _share(DailyResult result, int streak) async {
    HapticsService.impactMedium();
    AnalyticsService.instance.capture('daily_challenge_shared', {
      'correct': result.correct,
      'total': result.total,
      'from': 'home_card',
    });
    final text = buildDailyShareText(result, streak);
    try {
      await Share.share(text);
    } catch (_) {
      // No share sheet on this platform — fall back to the clipboard rather
      // than leaving a dead button.
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Result copied — paste it anywhere'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final result = provider.todayDailyResult;
    final played = result != null;

    return GestureDetector(
      onTapDown: played ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: played
          ? null
          : (_) {
              setState(() => _pressed = false);
              HapticsService.impactMedium();
              widget.onStart();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        // Gold gradient hairline — the same membership-card framing the paywall
        // uses, marking this as the special card on the page.
        child: Container(
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: played
                  ? [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.06),
                    ]
                  : [
                      _goldSoft.withValues(alpha: 0.85),
                      _goldDeep.withValues(alpha: 0.35),
                      _goldSoft.withValues(alpha: 0.6),
                    ],
            ),
            boxShadow: [
              if (!played)
                BoxShadow(
                    color: _goldDeep.withValues(alpha: 0.16),
                    blurRadius: 30,
                    spreadRadius: -6,
                    offset: const Offset(0, 10)),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(21)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF221830), Color(0xFF141020)],
              ),
            ),
            child: played ? _playedBody(provider, result) : _freshBody(provider),
          ),
        ),
      ),
    );
  }

  // ── Not played yet: the invitation ──────────────────────────────────────────

  Widget _freshBody(AppProvider provider) {
    final challenge = provider.todayChallenge;
    final streak = provider.dailyStreak;
    return Row(children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _gold.withValues(alpha: 0.2),
              _goldDeep.withValues(alpha: 0.08)
            ],
          ),
          border: Border.all(color: _gold.withValues(alpha: 0.35)),
        ),
        child: const Icon(Icons.emoji_events_rounded, color: _goldSoft, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('DAILY CHALLENGE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: _goldSoft)),
            if (streak > 0) ...[
              const SizedBox(width: 8),
              Text('🔥 $streak',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: _goldSoft)),
            ],
          ]),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('Key of ',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
              NoteText(
                  note: formatNoteForDisplay(challenge.key, provider.notation),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text('10 questions · beat the clock · one attempt',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5))),
        ]),
      ),
      const SizedBox(width: 8),
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _gold.withValues(alpha: 0.14),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.play_arrow_rounded, color: _goldSoft, size: 22),
      ),
    ]);
  }

  // ── Played: today's score, the dots, the countdown, share ──────────────────

  Widget _playedBody(AppProvider provider, DailyResult result) {
    final streak = provider.dailyStreak;
    return Row(children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _green.withValues(alpha: 0.12),
          border: Border.all(color: _green.withValues(alpha: 0.35)),
        ),
        child: const Icon(Icons.check_rounded, color: _green, size: 26),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('DAILY DONE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.45))),
            if (streak > 0) ...[
              const SizedBox(width: 8),
              const Text('🔥', style: TextStyle(fontSize: 11)),
              Text(' $streak',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w900, color: _goldSoft)),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('${result.correct}/${result.total}',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 10),
            // The mini grid — today's run at a glance. Shrinks rather than
            // overflowing on narrow phones.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: List.generate(result.answers.length, (i) {
                    final ok = result.answers[i];
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: (ok ? _green : _red).withValues(alpha: 0.85),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Next challenge in ${_untilMidnight()}',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5))),
        ]),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _share(result, streak),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _gold.withValues(alpha: 0.14),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.ios_share_rounded, color: _goldSoft, size: 17),
        ),
      ),
    ]);
  }
}
