@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/pocket_mode_screen.dart';
import 'package:improvy/screens/root_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/utils/music_engine.dart';
import 'package:improvy/widgets/note_text.dart';

import 'screens_render_test.dart' as layout show loadRealFonts;
import 'store_screenshot_test.dart' as store show loadRealFonts;

/// The phone screens shown on improvy.app, rendered from the real widgets at
/// the exact geometry of an iPhone 16 Pro: 402×874 points at 3× (1206×2622),
/// with its safe areas — 62 points under the Dynamic Island, 34 over the home
/// indicator. The site draws the island, status bar and home indicator on top
/// of these, so the app has to leave that room exactly as it does on a phone.
///
///     flutter test test/site_screens_test.dart --tags golden --run-skipped --update-goldens
///
/// then scale each test/goldens/site_*.png to 804×1748 WebP and replace the
/// matching src/assets/images/method_*.webp in the website repository.
const _points = Size(402, 874);
const _scale = 3.0;
const _top = 62.0, _bottom = 34.0;

Future<AppProvider> seeded() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  // Keys taken different distances, the way a real few weeks look.
  const dia = {
    'C': [30, 40, 50], 'G': [30, 40, 50], 'F': [30, 40, 50], 'D': [30, 40, 50],
    'B♭': [30, 40, 47], 'A': [30, 40, 41], 'E♭': [30, 40, 33], 'E': [30, 40, 22],
    'A♭': [30, 36, 0], 'B': [30, 24, 0], 'D♭': [30, 12, 0], 'F♯': [21, 0, 0],
  };
  const chr = {
    'C': [30, 40, 50], 'G': [30, 40, 50], 'F': [30, 40, 38], 'D': [30, 40, 26],
    'B♭': [30, 40, 9], 'A': [30, 31, 0], 'E♭': [30, 18, 0], 'E': [30, 6, 0],
    'A♭': [22, 0, 0], 'B': [14, 0, 0],
  };
  p.progressData = p.progressData
      .map((k) => k.copyWith(
            diatonicLevels: List<int>.from(dia[k.key] ?? const [0, 0, 0]),
            chromaticLevels: List<int>.from(chr[k.key] ?? const [0, 0, 0]),
          ))
      .toList();
  // Enough games for the charts, averages and streak to have something real.
  var t = 0;
  for (final key in ['C', 'G', 'F', 'D', 'B♭', 'C', 'G', 'A', 'C', 'F', 'E♭', 'G', 'C', 'D']) {
    p.selectKey(key);
    p.startMode(TrainingMode.diatonic, overrideKey: key);
    for (var i = 0; i < 20; i++) {
      final correct = (i + t) % 9 != 0;
      final ms = 1500 - t * 40 + (i % 5) * 70;
      p.recordAnswer(
        isCorrect: correct,
        responseTime: ms,
        answerDetails: AnswerRecord(
          degree: '${(i % 7) + 1}',
          note: 'E',
          selectedNote: correct ? 'E' : 'F',
          tonality: key,
          mode: 'diatonic',
          isReverse: false,
          difficulty: 1,
          responseTime: ms,
          isCorrect: correct,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    p.finishSession();
    p.exitTrainer();
    t++;
  }
  // Back on the home tab with nothing picked, the way the app opens; and Pro,
  // so the screens show what they unlock rather than their locks.
  // Three weeks of practice, most days, ending today: the streak the stats
  // screen shows is computed from exactly this history.
  final now = DateTime.now();
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final history = {...p.stats.dailyHistory};
  for (var i = 1; i <= 23; i++) {
    history[day(now.subtract(Duration(days: i)))] =
        DayStats(attempts: 40 + i % 3 * 10, correct: 36 + i % 3 * 9, responseTime: (40 + i % 3 * 10) * 1300, sessions: 2);
  }
  p.stats = p.stats.copyWith(dailyHistory: history);
  p.deselectKey();
  p.setIsPro(true);
  return p;
}

Future<void> frame(WidgetTester t, Widget home, AppProvider p) async {
  t.view.physicalSize = _points * _scale;
  t.view.devicePixelRatio = _scale;
  const pad = FakeViewPadding(top: _top * _scale, bottom: _bottom * _scale);
  t.view.padding = pad;
  t.view.viewPadding = pad;
  addTearDown(t.view.reset);
  await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
    value: p,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
        scaffoldBackgroundColor: const Color(0xFF0F0A1A),
        useMaterial3: true,
        fontFamily: 'Lexend',
      ),
      home: home,
    ),
  ));
  await settle(t);
  // A seeded history counts as good sessions, which is exactly when the app
  // asks about reminders. The site shows the app, not that question.
  final notNow = find.text('Not now');
  if (notNow.evaluate().isNotEmpty) {
    await t.tap(notNow.first);
    await settle(t);
  }
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> save(WidgetTester t, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/site_$name.png'));


int? _semi(String note) => kNoteToSemitone[note.trim()];

/// The note a degree names in [key], as a pitch class.
int? _degreeIn(String degree, String key) =>
    _semi(getNoteFromChromaticDegree(degree, calculateMajorScale(key), key));

/// Every note and degree the trainer draws goes through NoteText, which sets
/// the accidental apart from the letter — so it is read from the widget, not
/// from the glyphs on screen.
Iterable<NoteText> _notes() => find.byType(NoteText).evaluate().map((e) => e.widget as NoteText);

/// The question: the largest NoteText on the screen.
NoteText _question() => _notes().reduce(
    (a, b) => (a.style?.fontSize ?? 0) >= (b.style?.fontSize ?? 0) ? a : b);

/// Plays [n] rounds the way someone good at it would — the trainer checks
/// every answer itself, so the counters on screen are the app's own — with
/// a slip at [missAt] so the numbers look like a person's.
Future<void> play(
  WidgetTester t, {
  required int n,
  required bool Function(String question, String button) isAnswer,
  // Where two buttons sound the same (♯5 and ♭6), the one the app spells.
  bool Function(String question, String button)? spelled,
  int missAt = -1,
}) async {
  for (var i = 0; i < n; i++) {
    final q = _question();
    final qY = t.getCenter(find.byWidget(q).first).dy;
    NoteText? pick, exact, wrong;
    for (final w in _notes()) {
      if (identical(w, q)) continue;
      // Answers sit below the question; the key badge above it is not one.
      if (t.getCenter(find.byWidget(w).first).dy <= qY) continue;
      if (isAnswer(q.note, w.note)) {
        pick ??= w;
        if (spelled?.call(q.note, w.note) ?? false) exact ??= w;
      } else {
        wrong ??= w;
      }
    }
    pick = exact ?? pick;
    final target = (i == missAt ? wrong : pick) ?? pick;
    if (target == null) return;
    final asked = q;
    await t.tap(find.byWidget(target).first, warnIfMissed: false);
    // Wait for the next question to actually be on screen — a fixed pause
    // sometimes caught the screen between two questions — then a little
    // longer, so no verdict is left over it.
    for (var k = 0; k < 40; k++) {
      await t.pump(const Duration(milliseconds: 100));
      if (k > 6 && _notes().isNotEmpty && !identical(_question(), asked)) break;
    }
    for (var k = 0; k < 8; k++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }
}

bool _noteAnswers(String degree, String key, String label) {
  final want = _degreeIn(degree, key);
  return want != null && label.split('/').any((n) => _semi(n) == want);
}

Widget trainer(TrainingMode mode, {String key = 'C', int difficulty = 1, String? fixedNote}) => TrainerScreen(
      mode: mode,
      selectedKey: key,
      fixedNote: fixedNote,
      difficulty: difficulty,
      numberOfQuestions: 30,
      adaptiveDifficulty: false,
      sessionHistory: const [],
      notation: 'CDE',
      onExit: () {},
      onAnswer: (_, _, _) {},
      onFinish: (_) {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Both loaders: the layout one brings Bravura, the store one the Material
  // icon font — without it every icon renders as an empty box.
  setUpAll(() async {
    await layout.loadRealFonts();
    await store.loadRealFonts();
    // A streak of ten or more is drawn with a 🔥 emoji, which the test
    // runner has no font for; every session below ends on a shorter one.
  });

  testWidgets('home', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await save(t, 'home');
  });

  testWidgets('stats', (t) async {
    await frame(t, const RootScreen(), await seeded());
    await t.tap(find.text('Stats').last);
    await settle(t);
    await save(t, 'stats');
  });

  testWidgets('diatonic', (t) async {
    await frame(t, trainer(TrainingMode.diatonic), await seeded());
    await play(t, n: 24, missAt: 17, isAnswer: (q, b) => _noteAnswers(q, 'C', b));
    await save(t, 'diatonic');
  });

  testWidgets('piano', (t) async {
    await frame(t, trainer(TrainingMode.diatonic, key: 'G'), await seeded());
    await t.tap(find.textContaining('PIANO').last);
    await settle(t);
    await play(t, n: 17, missAt: 9, isAnswer: (q, b) => _noteAnswers(q, 'G', b));
    await save(t, 'piano');
  });

  testWidgets('chromatic', (t) async {
    await frame(t, trainer(TrainingMode.chromatic), await seeded());
    await play(t, n: 21, missAt: 13, isAnswer: (q, b) => _noteAnswers(q, 'C', b),
        spelled: (q, b) => b.split('/').contains(getNoteFromChromaticDegree(q, calculateMajorScale('C'), 'C')));
    await save(t, 'chromatic');
  });

  testWidgets('note to number', (t) async {
    await frame(t, trainer(TrainingMode.noteToNumber, key: 'D'), await seeded());
    await play(t, n: 19, missAt: 12,
        isAnswer: (q, b) => _semi(q) != null && _degreeIn(b, 'D') == _semi(q),
        spelled: (q, b) => getNoteFromChromaticDegree(b, calculateMajorScale('D'), 'D') == q);
    await save(t, 'n2n');
  });

  testWidgets('of what', (t) async {
    await frame(t, trainer(TrainingMode.ofWhat, fixedNote: 'C'), await seeded());
    await play(t, n: 15, missAt: 11, isAnswer: (q, b) => _semi(b) != null && _degreeIn(q, b) == 0);
    await save(t, 'ofwhat');
  });

  testWidgets('pocket', (t) async {
    await frame(
      t,
      PocketModeScreen(
        config: const PocketConfig(key: 'C', degrees: ['1', '2', '3', '4', '5', '6', '7'], delayMs: 5000, questions: 30, shuffleKeys: false),
        onExit: (_) {},
      ),
      await seeded(),
    );
    // Pocket Mode starts its audio at once; the test runner has no audio
    // plugin, and the "missing plugin" it reports is about the sound, not
    // about anything on screen.
    while (t.takeException() != null) {}
    await save(t, 'pocket');
    // Its speech loop runs on timers; let them fire and end before the test
    // does.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 30));
    while (t.takeException() != null) {}
  });
}
