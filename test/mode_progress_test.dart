import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/stats.dart';
import 'package:improvy/models/key_progress.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/mastery_bar.dart';

/// Note to Number and "…Of What?" used to leave nothing behind: three sessions
/// and none produced exactly the same saved state. These pin down the records
/// they now keep — and, just as importantly, the ones they must NOT touch.
Future<AppProvider> freshProvider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  return p;
}

void answer(AppProvider p, String key, String mode, bool correct) {
  p.recordAnswer(
    isCorrect: correct,
    responseTime: 900,
    answerDetails: AnswerRecord(
      degree: '3',
      note: 'E',
      selectedNote: correct ? 'E' : 'F',
      tonality: key,
      mode: mode,
      isReverse: true,
      difficulty: 1,
      responseTime: 900,
      isCorrect: correct,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ),
  );
}

void main() {
  group('Note to Number keeps a record', () {
    test('a diatonic run credits the diatonic store and nothing else',
        () async {
      final p = await freshProvider();
      p.selectKey('C');
      p.startNoteToNumberMode(
          degrees: const ['1', '2', '3'], difficulty: 1, chromatic: false);
      for (var i = 0; i < 5; i++) {
        answer(p, 'C', 'note-to-number', true);
      }

      final c = p.progressFor('C');
      expect(c.ntnDiatonicLevels[0], 5);
      expect(c.ntnChromaticLevels, [0, 0, 0],
          reason: 'a 7-degree run must not fill the 12-degree dial');
      expect(c.diatonicLevels, [0, 0, 0],
          reason: 'naming the degree for a note is not the forward skill, and '
              'must not move the forward ladder');
      expect(c.normalProgress, 0);
      // It DOES move the key's own number, which is the mean of the three
      // families — that is the whole point of it keeping a record.
      expect(c.noteToNumberProgress, greaterThan(0));
      expect(c.totalProgress, greaterThan(0));
      expect(p.totalProgress, greaterThan(0),
          reason: 'and so it reaches the global figure the animal reads');
    });

    test('a chromatic run credits the other store', () async {
      final p = await freshProvider();
      p.selectKey('G');
      p.startNoteToNumberMode(
          degrees: const ['1', '♭2'], difficulty: 1, chromatic: true);
      for (var i = 0; i < 4; i++) {
        answer(p, 'G', 'note-to-number', true);
      }

      final g = p.progressFor('G');
      expect(g.ntnChromaticLevels[0], 4);
      expect(g.ntnDiatonicLevels, [0, 0, 0]);
    });

    test('only the best run of a tier survives', () async {
      final p = await freshProvider();
      p.selectKey('C');

      p.startNoteToNumberMode(degrees: const ['1'], difficulty: 1);
      for (var i = 0; i < 9; i++) {
        answer(p, 'C', 'note-to-number', true);
      }
      p.finishSession();
      p.exitTrainer();

      p.startNoteToNumberMode(degrees: const ['1'], difficulty: 1);
      answer(p, 'C', 'note-to-number', true);

      expect(p.progressFor('C').ntnDiatonicLevels[0], 9,
          reason: 'a short second run must not overwrite a better first one');
    });

    test('Custom Mode still leaves no record', () async {
      final p = await freshProvider();
      p.selectKey('C');
      // Custom can be narrowed to a single degree, which is exactly why it
      // cannot be allowed to fill a dial.
      p.startCustomMode(
          degrees: const ['1'],
          reverse: true,
          difficulty: 3,
          questions: 30,
          overrideKey: 'C');
      for (var i = 0; i < 6; i++) {
        answer(p, 'C', 'custom', true);
      }

      final c = p.progressFor('C');
      expect(c.ntnDiatonicLevels, [0, 0, 0]);
      expect(c.ntnChromaticLevels, [0, 0, 0]);
      expect(c.diatonicLevels, [0, 0, 0]);
    });
  });

  _tierFollowsTheKey();
  _keyStanding();

  group('the tier gates', () {
    test('Apprentice is always open, the two above are earned at 80%', () {
      expect(AppProvider.highestUnlockedTier([0, 0, 0]), 1);
      expect(AppProvider.highestUnlockedTier([23, 0, 0]), 1);
      expect(AppProvider.highestUnlockedTier([24, 0, 0]), 2); // 24/30
      expect(AppProvider.highestUnlockedTier([30, 31, 0]), 2);
      expect(AppProvider.highestUnlockedTier([30, 32, 0]), 3); // 32/40
    });

    test('the gate is one fraction, not a number typed out per tier', () {
      for (var t = 1; t < 3; t++) {
        expect(kTierUnlock[t], (kTierCaps[t - 1] * kTierUnlockFraction).round(),
            reason: 'tier ${t + 1} does not open at '
                '${kTierUnlockFraction * 100}% of the tier below');
      }
    });
  });

  group('the saved shape', () {
    test('the two new stores survive a round trip', () {
      final k = KeyProgress(
        key: 'E♭',
        ntnDiatonicLevels: [12, 0, 0],
        ntnChromaticLevels: [3, 4, 5],
      );
      final back = KeyProgress.fromJson(k.toJson());
      expect(back.ntnDiatonicLevels, [12, 0, 0]);
      expect(back.ntnChromaticLevels, [3, 4, 5]);
    });

    test('a save written before these existed reads as zero, not as a crash',
        () {
      final old = {
        'key': 'C',
        'diatonicLevels': [30, 40, 50],
        'chromaticLevels': [10, 0, 0],
      };
      final k = KeyProgress.fromJson(old);
      expect(k.ntnDiatonicLevels, [0, 0, 0]);
      expect(k.ntnChromaticLevels, [0, 0, 0]);
      expect(k.diatonicLevels, [30, 40, 50], reason: 'the old data is intact');
    });

    test('all three tiers make the dial, not just the one being played', () {
      // Master untouched, so the outline on that row cannot be full.
      expect(KeyProgress.rowProgress([30, 40, 0]), 67);
      expect(KeyProgress.rowProgress([30, 40, 50]), 100);
    });

    test('Note to Number is one number per key, both directions', () {
      // The same two-row ladder as the forward modes: the twelve contain the
      // seven, so a chromatic run credits the diatonic row.
      final only7 = KeyProgress(key: 'C', ntnDiatonicLevels: [30, 40, 50]);
      expect(only7.noteToNumberProgress, 50);
      final all12 = KeyProgress(key: 'C', ntnChromaticLevels: [0, 0, 50]);
      expect(all12.noteToNumberProgress, 100);
    });

    test('the harmonizer is the same ladder, chord inside all', () {
      final chord = KeyProgress(key: 'C', harmonizerLevels: [30, 40, 50]);
      expect(chord.harmonizerProgress, 50);
      final all = KeyProgress(key: 'C', harmonizerAllLevels: [0, 0, 50]);
      expect(all.harmonizerProgress, 100);
    });
  });

  group('the mastery bar', () {
    Future<double> filled(WidgetTester t, double progress) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              height: 56,
              child: Stack(children: [
                MasteryBar(progress: progress, color: Colors.red),
              ]),
            ),
          ),
        ),
      ));
      await t.pump();
      return t
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
    }

    testWidgets('an untouched key still shows its empty track', (t) async {
      // The point of a bar over an outline: the part not yet earned is visible,
      // so "nothing here yet" is something the tile can actually say.
      expect(await filled(t, 0), 0);
      expect(find.byType(MasteryBar), findsOneWidget);
    });

    testWidgets('the fill is the progress, and cannot exceed the track',
        (t) async {
      expect(await filled(t, 0.62), closeTo(0.62, 1e-9));
      expect(await filled(t, 1.4), 1.0);
      expect(await filled(t, -0.2), 0.0);
    });
  });

  group('the setup screens say the new thing', () {
    Future<void> pump(WidgetTester t, Widget child) async {
      final p = await freshProvider();
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(home: child),
      ));
      await t.pump();
    }

    testWidgets('…Of What? offers Chord and All, and no question count',
        (t) async {
      await pump(
        t,
        OfWhatSetup(
          isPro: true,
          onShowPaywall: () {},
          onCancel: () {},
          onStart: (_, _, _, _) {},
        ),
      );
      expect(find.text('CHORD'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('Number of Questions'), findsNothing,
          reason: 'the tier decides the length now');
      expect(find.text('BEST'), findsNothing);
      expect(find.textContaining('/30 BEST'), findsOneWidget,
          reason: 'the record for the selected tier belongs on the page');
    });

    testWidgets('Custom offers all three modes', (t) async {
      await pump(
        t,
        CustomModeSetup(
          initialKey: 'C',
          onStart: (_, _, _, _, _) {},
          onCancel: () {},
        ),
      );
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('NOTE TO NUMBER'), findsOneWidget);
      expect(find.text('…OF WHAT?'), findsOneWidget);
    });
  });
}

/// The tier shown and the tier START uses must be the same one. They were not:
/// the correction ran during build, so a key with nothing on it displayed
/// Apprentice while the button still carried Master over from the last key.
void _tierFollowsTheKey() {
  testWidgets('changing key drops back to a tier that key has actually earned',
      (t) async {
    final p = await freshProvider();
    // C has been taken to Master; G has never been touched.
    p.selectKey('C');
    p.startNoteToNumberMode(degrees: const ['1'], difficulty: 1);
    for (var i = 0; i < 27; i++) {
      answer(p, 'C', 'note-to-number', true);
    }
    p.finishSession();
    p.exitTrainer();

    var startedAt = 0;
    t.view.physicalSize = const Size(390, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(
        home: NoteToNumberSetup(
          initialKey: 'C',
          isPro: true,
          onShowPaywall: () {},
          onCancel: () {},
          onStart: (_, _, d, _) => startedAt = d,
        ),
      ),
    ));
    await t.pump();

    // Virtuoso is open in C — 27 of Apprentice's 30.
    await t.tap(find.text('VIRTUOSO'));
    await t.pump();
    expect(find.textContaining('/40 BEST'), findsOneWidget);

    // Move to a key with no history at all.
    await t.tap(find.text('G'));
    await t.pump();
    expect(find.textContaining('/30 BEST'), findsOneWidget,
        reason: 'an untouched key can only be started at Apprentice');

    await t.tap(find.text('START TRAINING'));
    await t.pump();
    expect(startedAt, 1,
        reason: 'START must use the tier the page is showing, not the one '
            'left over from the previous key');
  });
}

/// The number beside "Select Root Key" is the outline on that key's tile, read
/// out. Same source, so they can never disagree — and it must follow both the
/// key and the row being set up.
void _keyStanding() {
  testWidgets('the standing beside the grid tracks the key and the row',
      (t) async {
    final p = await freshProvider();
    // C taken a long way in the 7-degree row; G untouched.
    p.selectKey('C');
    p.startNoteToNumberMode(degrees: const ['1'], difficulty: 1);
    for (var i = 0; i < 24; i++) {
      answer(p, 'C', 'note-to-number', true);
    }
    p.finishSession();
    p.exitTrainer();

    t.view.physicalSize = const Size(390, 1100);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(
        home: NoteToNumberSetup(
          initialKey: 'C',
          isPro: true,
          onShowPaywall: () {},
          onCancel: () {},
          onStart: (_, _, _, _) {},
        ),
      ),
    ));
    await t.pump();

    final shown = p.ntnProgress('C', chromatic: false);
    expect(shown, greaterThan(0));
    expect(find.text('$shown%'), findsOneWidget,
        reason: 'the badge must show what the bar is drawing');

    // The 12-degree row was never played, so switching to it drops to zero.
    await t.tap(find.text('CHROMATIC'));
    await t.pump();
    expect(p.ntnProgress('C', chromatic: true), 0);
    // Two zeroes now: the standing beside the grid and the tier record under
    // the pills. Both are right — the 12-degree row has nothing in it at all.
    expect(find.text('0%'), findsNWidgets(2));

    // And an untouched key reads zero too.
    await t.tap(find.text('DIATONIC'));
    await t.pump();
    await t.tap(find.text('G'));
    await t.pump();
    expect(p.ntnProgress('G', chromatic: false), 0);
    expect(find.text('0%'), findsNWidgets(2));
  });
}
