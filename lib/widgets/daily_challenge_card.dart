import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import '../models/daily_challenge.dart';
import '../models/key_progress.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../services/haptics_service.dart';
import 'note_text.dart';

/// Home-screen hero for the Daily Challenge. Two states:
///  • not played — key of the day, the rule, gold CTA feel;
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
    AnalyticsService.instance.capture(Ev.dailyShared, {
      'correct': result.correct,
      'total': result.total,
      'from': 'home_card',
    });
    final text = buildDailyShareText(result, streak,
        installUrl: installUrlFor(defaultTargetPlatform, isWeb: kIsWeb));
    try {
      await Share.share(text);
    } catch (_) {
      // No share sheet on this platform — fall back to the clipboard rather
      // than leaving a dead button.
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
        child: played ? _playedCard(provider, result) : _freshCard(provider),
      ),
    );
  }

  /// Played state — the white-framed neutral card, unchanged.
  Widget _playedCard(AppProvider provider, DailyResult result) => Container(
        padding: const EdgeInsets.all(1.4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20.6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF221830), Color(0xFF141020)],
            ),
          ),
          child: _playedBody(provider, result),
        ),
      );

  /// Not-yet-played state — design 22d, "quiet, gold only as accent": a flat
  /// #1A1625 body under a single thin gold hairline, one soft gold glow in the
  /// corner, and a plain gold chevron instead of a filled play button. The
  /// membership-card gold frame is gone; the gold survives only as an accent.
  Widget _freshCard(AppProvider provider) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1625),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Stack(children: [
            // The one gold flourish: a soft glow bleeding in from the top-right
            // corner, clipped to the card by the ClipRRect above.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_gold.withValues(alpha: 0.16), Colors.transparent],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: _freshBody(provider),
            ),
          ]),
        ),
      );

  // ── Not played yet: the invitation ──────────────────────────────────────────

  Widget _freshBody(AppProvider provider) {
    final challenge = provider.todayChallenge;
    final streak = provider.dailyStreak;
    // The day's key in the same colour the app gives it everywhere else, so the
    // card and that key's mastery tile agree — 22d shows the key in its colour.
    final keyIndex = kDefaultKeyOrder.indexOf(challenge.key);
    final keyColor = AppColors.keyColor(keyIndex < 0 ? 0 : keyIndex);
    return Row(children: [
      // Trophy, in a flat gold-tinted tile (no gradient) — quiet.
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _gold.withValues(alpha: 0.14),
          border: Border.all(color: _gold.withValues(alpha: 0.32)),
        ),
        child: const Icon(Icons.emoji_events_rounded, color: _goldSoft, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // The label plus a streak chip is a few pixels too wide on a 320dp
          // phone; scaling the pair keeps both readable instead of clipping the
          // streak, which is the half people look for.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Text(context.l10n.dailyTitle,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: _goldSoft)),
              if (streak > 0) ...[
                const SizedBox(width: 8),
                Text('🔥 $streak',
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, color: _goldSoft)),
              ],
            ]),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(challenge.subjectPrefix,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
              NoteText(
                  note: formatNoteForDisplay(challenge.key, provider.notation),
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700, color: keyColor)),
            ],
          ),
          const SizedBox(height: 4),
          // Just the rule: adding "· one attempt" overflowed the card on a
          // 412dp phone and got ellipsised mid-word. The single attempt is
          // stated where it actually bites — the quit dialog — and the card
          // turning to its "done" state says it plainly enough.
          Text('${challenge.modeLabel} · ${challenge.rule}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5))),
        ]),
      ),
      const SizedBox(width: 10),
      // 22d's control: a plain gold chevron, not a filled play button.
      const Icon(Icons.chevron_right_rounded, color: _goldSoft, size: 26),
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
            Text(context.l10n.dailyDone,
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
          Text(context.l10n.dailyNextIn(_untilMidnight()),
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
