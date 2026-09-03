import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/app_info.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/models/key_progress.dart';
import 'package:improvy/screens/explainer_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
import 'package:improvy/screens/stats_screen.dart';
import 'package:improvy/l10n/l10n.dart';

/// The things an audit found broken on the day the app was declared ready
/// for advertising. Each is cheap to break again by accident, so each is a
/// test rather than a memory.
void main() {
  group('the store id', () {
    test('is filled in, so shares and ratings reach the App Store', () {
      // Empty for two weeks after launch: the Rate row hid itself, and every
      // shared Daily Challenge sent friends to the website instead.
      expect(kAppStoreId, isNotEmpty);
      expect(installUrlFor(TargetPlatform.iOS), contains('apps.apple.com'));
      expect(installUrlFor(TargetPlatform.iOS), contains(kAppStoreId));
    });
  });

  group('the session summary', () {
    Map<String, dynamic> run({
      required String mode,
      required int diff,
      required int correct,
      int total = 30,
      String key = 'G',
    }) =>
        {'key': key, 'mode': mode, 'correct': correct, 'total': total,
         'time': 60000, 'difficulty': diff};

    Future<void> pump(WidgetTester t, Map<String, dynamic> data,
        {List<KeyProgress>? progress, bool isPro = true, void Function([String?])? paywall}) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final provider = AppProvider(storage);
      await provider.init();
      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: SessionSummaryScreen(
            sessionData: data,
            progressData: progress ?? [KeyProgress(key: 'G')],
            onRetry: () {},
            onBack: () {},
            onNextDifficulty: (_) {},
            isPro: isPro,
            onShowPaywall: paywall,
          ),
        ),
      ));
      await t.pump(const Duration(seconds: 2));
    }

    testWidgets('"passed" is the 80% gate, not a private count of errors',
        (t) async {
      // 24 of 30 is exactly the bar Virtuoso opens at. The old rule — at most
      // three wrong — would have called this NOT YET.
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 24),
          progress: [KeyProgress(key: 'G', diatonicLevels: [24, 0, 0])]);
      expect(find.text('LEVEL PASSED'), findsOneWidget);
    });

    testWidgets('one short of the gate is not passed', (t) async {
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 23),
          progress: [KeyProgress(key: 'G', diatonicLevels: [23, 0, 0])]);
      expect(find.text('LEVEL PASSED'), findsNothing);
      expect(find.text('PLAY NEXT DIFFICULTY'), findsNothing);
    });

    testWidgets('the next tier is offered only when it is actually open',
        (t) async {
      // A great run does not open the tier by itself — the saved ladder does.
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 29),
          progress: [KeyProgress(key: 'G', diatonicLevels: [29, 0, 0])]);
      expect(find.text('PLAY NEXT DIFFICULTY'), findsOneWidget);
    });

    testWidgets('a free player who finished the free half is told about the other',
        (t) async {
      var opened = '';
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 27),
          isPro: false, paywall: ([r]) => opened = r ?? '');
      expect(find.textContaining('free half of G'), findsOneWidget);
      await t.tap(find.textContaining('free half of G'));
      expect(opened, 'summary_chromatic');
    });

    testWidgets('but not in C, where Chromatic is already free, and not for Pro',
        (t) async {
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 27, key: 'C'),
          isPro: false, paywall: ([r]) {});
      expect(find.textContaining('free half'), findsNothing);
      await pump(t, run(mode: 'diatonic', diff: 1, correct: 27),
          isPro: true, paywall: ([r]) {});
      expect(find.textContaining('free half'), findsNothing);
    });
  });

  _progressReporting();

  group('the explainer', () {
    Future<void> pumpExplainer(WidgetTester t, void Function() done) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final provider = AppProvider(storage);
      await provider.init();
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExplainerScreen(onDone: done),
        ),
      ));
      await t.pumpAndSettle();
    }

    testWidgets('three pages, then the app', (t) async {
      var done = false;
      await pumpExplainer(t, () => done = true);
      expect(find.textContaining('Every key'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.textContaining('Change key'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.textContaining('Try one'), findsOneWidget);
      expect(done, isFalse);
      await t.tap(find.text("Let's go"));
      expect(done, isTrue);
    });

    testWidgets('the keyboard renames its keys when the key changes', (t) async {
      // The whole point of page two: the numbers stay, the letters move.
      await pumpExplainer(t, () {});
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      // Two plain F's on screen in C: one on the keyboard, one on the key
      // picker. In G the keyboard's becomes F♯ — a Text.rich, not a plain
      // Text — so only the picker's remains.
      expect(find.text('F'), findsNWidgets(2));
      await t.tap(find.text('G').last);
      await t.pumpAndSettle();
      expect(find.text('F'), findsOneWidget,
          reason: 'G major replaces the keyboard F with F♯ — that is the lesson');
      // And every degree is still on the board.
      for (var d = 1; d <= 7; d++) {
        expect(find.text('$d'), findsWidgets, reason: 'degree $d vanished');
      }
    });

    testWidgets('the last page is a real question that can be got right',
        (t) async {
      await pumpExplainer(t, () {});
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text('Next'));
        await t.pumpAndSettle();
      }
      // "In C, which note is the 5?" — the answer is G. The keyboard above
      // the question labels a key G too, so take the answer button: it comes
      // after the keyboard in the tree.
      expect(find.textContaining('which note'), findsOneWidget);
      await t.tap(find.text('G').last);
      await t.pumpAndSettle();
      expect(find.textContaining("That's it"), findsOneWidget);
    });

    testWidgets('a wrong answer says so and lets you try again', (t) async {
      await pumpExplainer(t, () {});
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text('Next'));
        await t.pumpAndSettle();
      }
      await t.tap(find.text('A').last);
      await t.pumpAndSettle();
      expect(find.textContaining('Not quite'), findsOneWidget);
      await t.tap(find.text('G').last);
      await t.pumpAndSettle();
      expect(find.textContaining("That's it"), findsOneWidget);
    });

    testWidgets('can be skipped from the first page', (t) async {
      var done = false;
      await pumpExplainer(t, () => done = true);
      await t.tap(find.text('Skip'));
      expect(done, isTrue);
    });
  });
}

/// The progress model changed shape twice — three families, then 40/40/20 —
/// and two screens were still reporting the old picture. These pin the new one.
void _progressReporting() {
  group('the summary reports what actually moved', () {
    Future<void> pump(WidgetTester t, String mode, KeyProgress key) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final provider = AppProvider(storage);
      await provider.init();
      t.view.physicalSize = const Size(390, 1100);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SessionSummaryScreen(
            sessionData: {
              'key': key.key, 'mode': mode, 'correct': 27, 'total': 30,
              'time': 60000, 'difficulty': 1,
            },
            progressData: [key],
            onRetry: () {},
            onBack: () {},
            onNextDifficulty: (_) {},
          ),
        ),
      ));
      await t.pump(const Duration(seconds: 2));
    }

    testWidgets('a Note to Number run reports its own family, not the forward one',
        (t) async {
      // Before this, the card read the raw diatonic dial — and was hidden
      // outright for the two modes that now keep records of their own.
      final key = KeyProgress(
        key: 'G',
        diatonicLevels: [30, 40, 50],      // forward: finished
        ntnDiatonicLevels: [24, 0, 0],     // backwards: just started
      );
      await pump(t, 'note-to-number', key);
      expect(key.noteToNumberProgress, 13);
      expect(find.text('13%'), findsOneWidget,
          reason: 'the family this run belongs to');
      expect(find.text('${key.totalProgress}%'), findsOneWidget,
          reason: 'and the key as a whole, which is the mean of three');
      expect(find.text('${key.normalProgress}%'), findsNothing,
          reason: 'the forward family was not played and must not be reported');
    });

    testWidgets('…Of What? reports the harmonizer', (t) async {
      final key = KeyProgress(key: 'C', harmonizerLevels: [30, 40, 50]);
      await pump(t, 'of-what', key);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('Custom still reports nothing, because it records nothing',
        (t) async {
      await pump(t, 'custom', KeyProgress(key: 'C'));
      expect(find.text('MODE MASTERY'), findsNothing);
    });
  });

  testWidgets('the Skill Mastery row shows all three families', (t) async {
    // One bar could say 33% and leave nobody able to tell whether that was one
    // family finished or three barely started.
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    provider.completeTutorial();
    provider.progressData = provider.progressData
        .map((k) => k.key == 'C'
            ? k.copyWith(diatonicLevels: [30, 40, 50], ntnDiatonicLevels: [24, 0, 0])
            : k)
        .toList();
    final handle = t.ensureSemantics();
    // Tall enough to lay the whole page out at once: semantics only covers
    // what has been built, and the list sits well below one screen.
    t.view.physicalSize = const Size(390, 5000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StatsScreen(),
      ),
    ));
    await t.pump(const Duration(seconds: 2));
    final labels = <String>[];
    void walk(SemanticsNode n) {
      if (n.label.isNotEmpty) labels.add(n.label);
      n.visitChildren((c) { walk(c); return true; });
    }
    walk(t.getSemantics(find.byType(MaterialApp)));
    // The row is one tap target, so Flutter merges the three bars' labels into
    // it — what matters is that a reader is told all three, not how the tree
    // is shaped.
    final spoken = labels.join(' | ');
    // C: forward finished (50), backwards barely started (13), harmonizer none.
    expect(spoken, contains('DEGREE → NOTE, 50%'));
    expect(spoken, contains('NOTE → DEGREE, 13%'));
    expect(spoken, contains('…OF WHAT?, 0%'));
    handle.dispose();
  });
}
