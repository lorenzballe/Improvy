import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../constants/music_constants.dart';
import '../models/daily_challenge.dart';
import '../providers/app_provider.dart';
import '../utils/music_engine.dart';
import '../widgets/note_text.dart';
import '../constants/app_colors.dart';
import '../constants/levels.dart';
import '../constants/theory_cards.dart';
import '../models/key_progress.dart';

/// Feeds the home-screen widgets.
///
/// The split is deliberate: **everything is formatted here, in Dart**, and the
/// native widgets only draw strings. Notation (C-D-E vs Do-Re-Mi), accidental
/// spelling and pluralisation are app rules — duplicating them in Kotlin and
/// Swift would guarantee they drift.
///
/// A widget must keep making sense for days without the app ever launching, so
/// the quiz rotation is written a **week ahead** (one question per hour) and
/// the native side just indexes into it by clock. Same idea as the Daily
/// Challenge: derive from the date, don't fetch.
class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  /// Must match the App Group added to both the app and the widget extension
  /// in Xcode, and `Improvy.appGroupId` in the Swift sources.
  static const String iOSAppGroupId = 'group.com.improvy.app.widget';

  /// Android provider class names, and the iOS widget *kinds* — the strings
  /// passed to `StaticConfiguration(kind:)` in ImprovyWidget.swift. They have
  /// to match exactly or the reload silently refreshes nothing.
  static const String _androidQuizProvider = 'ImprovyQuizWidgetProvider';
  static const String _androidDailyProvider = 'ImprovyDailyWidgetProvider';
  static const String _iOSQuizKind = 'ImprovyQuizWidget';
  static const String _iOSDailyKind = 'ImprovyDailyWidget';

  /// Every widget the app publishes, as (Android provider, iOS kind). Adding a
  /// widget means adding it here — the refresh loop below walks this list, so a
  /// new provider left out of it simply never updates.
  static const List<(String, String)> _widgets = [
    (_androidQuizProvider, _iOSQuizKind),
    (_androidDailyProvider, _iOSDailyKind),
    ('ImprovyQuizWideWidgetProvider', 'ImprovyQuizWideWidget'),
    ('ImprovyLevelWidgetProvider', 'ImprovyLevelWidget'),
    ('ImprovyMapWidgetProvider', 'ImprovyMapWidget'),
    ('ImprovyMapTallWidgetProvider', 'ImprovyMapTallWidget'),
    ('ImprovyStreakWidgetProvider', 'ImprovyStreakWidget'),
    ('ImprovyStreakTallWidgetProvider', 'ImprovyStreakTallWidget'),
    ('ImprovyWeakestWidgetProvider', 'ImprovyWeakestWidget'),
    ('ImprovyLauncherWidgetProvider', 'ImprovyLauncherWidget'),
    ('ImprovyPocketWidgetProvider', 'ImprovyPocketWidget'),
    ('ImprovyTheoryWidgetProvider', 'ImprovyTheoryWidget'),
  ];

  /// The twelve keys in chromatic order, spelled the way the app spells them.
  /// The map widget's 6×2 grid reads left-to-right as a rising scale, which is
  /// only true in this order — [kKeys] is arranged by key signature instead.
  static const List<String> chromaticKeyOrder = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B',
  ];

  /// Hours of questions written ahead. A week of rotation costs a few KB and
  /// means an untouched phone still shows something new every hour.
  static const int _hoursAhead = 24 * 7;

  bool _initialised = false;

  /// A tap on a widget, waiting to be handled by the UI. RootScreen watches
  /// this: `improvy://quiz?s=<slot>` opens the reveal card,
  /// `improvy://daily` jumps into today's challenge.
  final ValueNotifier<Uri?> pendingAction = ValueNotifier<Uri?>(null);

  Future<void> init() async {
    if (kIsWeb || _initialised) return;
    try {
      await HomeWidget.setAppGroupId(iOSAppGroupId);
      _initialised = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] init failed: $e');
    }
  }

  /// Starts listening for widget taps — both the one that launched the app from
  /// cold and any that arrive while it is already running.
  Future<void> listenForTaps() async {
    if (kIsWeb) return;
    await init();
    try {
      final launched = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launched != null) pendingAction.value = launched;
      HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) pendingAction.value = uri;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[WidgetService] tap listener failed: $e');
    }
  }

  /// Pushes the current state to both widgets. Cheap and idempotent — call it
  /// on launch, on resume, and after anything the widgets show changes.
  Future<void> sync(AppProvider provider) async {
    if (kIsWeb) return;
    await init();
    try {
      final now = DateTime.now();
      final daily = provider.todayChallenge;
      final result = provider.todayDailyResult;
      final animal = provider.animalLevel;

      await Future.wait([
        // ── Quiz ("the little question") ──────────────────────────────────
        HomeWidget.saveWidgetData<String>('quiz_json',
            jsonEncode(buildQuestions(now, provider.notation))),
        // Absolute slot of entry 0. The native side indexes by clock, and the
        // tap hands the absolute slot back so the app can regenerate exactly
        // the question that was on screen — no array to keep aligned.
        HomeWidget.saveWidgetData<int>('quiz_base_slot', baseSlot(now)),

        // ── Daily Challenge ───────────────────────────────────────────────
        HomeWidget.saveWidgetData<String>(
            'daily_key', formatNoteForDisplay(daily.key, provider.notation)),
        HomeWidget.saveWidgetData<bool>('daily_played', result != null),
        HomeWidget.saveWidgetData<String>(
            'daily_score', result == null ? '' : '${result.correct}/${result.total}'),
        HomeWidget.saveWidgetData<String>(
            'daily_grid', result == null ? '' : _grid(result)),
        // The rule in words, derived from the challenge constants — so the
        // widgets can never advertise a budget the run no longer uses.
        HomeWidget.saveWidgetData<String>('daily_sub', DailyChallenge.rule),
        HomeWidget.saveWidgetData<int>('daily_streak', provider.dailyStreak),

        // The key of the day in its own colour, so the widget's tile matches
        // the tile the app shows for that key.
        HomeWidget.saveWidgetData<String>('daily_key_color', _keyHex(daily.key)),
        // Whether today is already covered. The streak widget goes to its alert
        // state on false — a streak you are about to lose is the only number
        // here worth interrupting someone for.
        HomeWidget.saveWidgetData<bool>('played_today', provider.playedToday),

        // ── Level & progress ──────────────────────────────────────────────
        HomeWidget.saveWidgetData<String>('animal_emoji', animal.emoji),
        HomeWidget.saveWidgetData<String>('animal_name', animal.name),
        HomeWidget.saveWidgetData<String>('animal_color', animal.hex),
        HomeWidget.saveWidgetData<String>('animal_quote', animal.quote),
        HomeWidget.saveWidgetData<int>('animal_level', animal.level),
        HomeWidget.saveWidgetData<int>('animal_levels_total', kAnimalLevelCount),
        HomeWidget.saveWidgetData<int>('progress_pct', provider.totalProgress.round()),

        // ── Key mastery ───────────────────────────────────────────────────
        // Twelve entries in chromatic order: name, percentage, colour, and
        // whether it has ever been played (an untouched key is drawn hollow,
        // not at 0% — "never started" and "started badly" are different).
        HomeWidget.saveWidgetData<String>('keys_json', jsonEncode(_keyTiles(provider))),

        // ── Weakest key ───────────────────────────────────────────────────
        ..._weakestKeyData(provider),

        // ── Theory of the day ─────────────────────────────────────────────
        HomeWidget.saveWidgetData<String>('theory_degree', _theory(now).$1),
        HomeWidget.saveWidgetData<String>('theory_text', _theory(now).$2),
        HomeWidget.saveWidgetData<String>('theory_color', _theory(now).$3),
      ]);

      // Every widget is refreshed from the same payload — one write, one sweep.
      for (final (android, ios) in _widgets) {
        await HomeWidget.updateWidget(
          androidName: android,
          iOSName: ios,
          qualifiedAndroidName: 'com.improvy.improvy.$android',
        );
      }
    } catch (e) {
      // A widget that fails to refresh must never disturb the app.
      if (kDebugMode) debugPrint('[WidgetService] sync failed: $e');
    }
  }

  /// A key's colour as `#rrggbb`, from its position in the chromatic order —
  /// the same positional rainbow the app uses, so a key looks the same on the
  /// home screen as it does inside.
  static String _keyHex(String key) {
    final i = chromaticKeyOrder.indexOf(key);
    final c = AppColors.keyColor(i < 0 ? 0 : i);
    return '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  /// The twelve tiles of the mastery map, chromatic order.
  static List<Map<String, dynamic>> _keyTiles(AppProvider provider) {
    return [
      for (var i = 0; i < chromaticKeyOrder.length; i++)
        () {
          final key = chromaticKeyOrder[i];
          final p = provider.progressData.firstWhere(
            (k) => k.key == key,
            orElse: () => KeyProgress(key: key),
          );
          final pct = p.totalProgress;
          return <String, dynamic>{
            'k': formatNoteForDisplay(key, provider.notation),
            'p': pct,
            'c': _keyHex(key),
            // Untouched keys read as an outline. Without this a key you have
            // never opened looks identical to one you keep failing.
            'played': pct > 0,
          };
        }(),
    ];
  }

  /// The key most worth practising, plus the numbers the widget shows for it.
  ///
  /// "Weakest" only means something once there is something to compare, so a
  /// profile with nothing played publishes an empty name and the widget shows
  /// its own invitation instead of pointing at an arbitrary C.
  static List<Future<bool?>> _weakestKeyData(AppProvider provider) {
    final played = provider.progressData.where((k) => k.totalProgress > 0).toList();
    if (played.isEmpty) {
      return [
        HomeWidget.saveWidgetData<String>('weak_key', ''),
        HomeWidget.saveWidgetData<int>('weak_pct', 0),
        HomeWidget.saveWidgetData<String>('weak_color', _keyHex('C')),
      ];
    }
    played.sort((a, b) => a.totalProgress.compareTo(b.totalProgress));
    final worst = played.first;
    return [
      HomeWidget.saveWidgetData<String>(
          'weak_key', formatNoteForDisplay(worst.key, provider.notation)),
      HomeWidget.saveWidgetData<int>('weak_pct', worst.totalProgress),
      HomeWidget.saveWidgetData<String>('weak_color', _keyHex(worst.key)),
    ];
  }

  /// One theory card per day, picked by date so every device shows the same one
  /// and it changes at midnight without the app running.
  static (String, String, String) _theory(DateTime now) {
    final card = kTheoryCards[_epochDay(now) % kTheoryCards.length];
    return (card.degree, card.text, card.hex);
  }

  /// Days since 1970-01-01 for a local calendar date.
  ///
  /// Built as a **UTC** instant from the local Y/M/D on purpose: using the
  /// local midnight would divide down to the previous day for anyone east of
  /// Greenwich. The native side does the identical construction — they must
  /// agree, or the widget reads the wrong hour of the rotation.
  static int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  static String _grid(DailyResult r) =>
      r.answers.map((a) => a ? '🟩' : '🟥').join();

  /// Absolute slot number of the first entry written for [from] — hours since
  /// the epoch, in local calendar terms.
  static int baseSlot(DateTime from) => _epochDay(from) * 24;

  /// One question per hour for the next week.
  ///
  /// Diatonic degrees dominate — a home screen is read in a glance, and "the
  /// 6th of A♭" is the app's core skill. Every fourth slot goes chromatic to
  /// keep it from feeling small.
  List<Map<String, String>> buildQuestions(DateTime from, String notation) {
    final base = baseSlot(from);
    return [
      for (var i = 0; i < _hoursAhead; i++) questionForSlot(base + i, notation),
    ];
  }

  /// The question belonging to an absolute hour slot.
  ///
  /// Pure function of the slot: the same slot yields the same question on every
  /// device, on every regeneration, forever. That is what lets the widget hand
  /// back a slot number on tap and the app rebuild precisely what was on
  /// screen — nothing needs to be stored or kept in sync.
  Map<String, String> questionForSlot(int slot, String notation) {
    final rnd = _slotRandom(slot);
    final key = kKeys[rnd(kKeys.length)];
    // Every fourth hour asks a chromatic degree.
    final degree = slot % 4 == 3
        ? const ['♭2', '♭3', '♯4', '♭6', '♭7'][rnd(5)]
        : const ['2', '3', '4', '5', '6', '7'][rnd(6)];
    final answer = getNoteFromChromaticDegree(degree, calculateMajorScale(key), key);
    return {
      'q': '$degree of ${formatNoteForDisplay(key, notation)}',
      'a': formatNoteForDisplay(answer, notation),
      // The key unformatted — the app opens this key's training from the
      // reveal card.
      'k': key,
    };
  }

  /// Tiny deterministic PRNG over a slot index — same family as
  /// [DailyChallenge]'s, and for the same reason: `Random()` gives no
  /// cross-platform guarantee, and these questions must be reproducible.
  int Function(int) _slotRandom(int slot) {
    var s = (slot * 2654435761) & 0x7fffffff;
    if (s == 0) s = 1;
    return (int max) {
      s = (s * 48271) % 0x7fffffff;
      return s % max;
    };
  }
}
