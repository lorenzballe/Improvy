import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/app_info.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/models/key_progress.dart';
import 'package:improvy/screens/explainer_screen.dart';
import 'package:improvy/screens/session_summary_screen.dart';
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

  group('the explainer', () {
    testWidgets('three pages, then the app', (t) async {
      var done = false;
      await t.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ExplainerScreen(onDone: () => done = true)));
      expect(find.textContaining('Every note'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.textContaining('Same numbers'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.textContaining('We ask'), findsOneWidget);
      expect(done, isFalse);
      await t.tap(find.text("Let's go"));
      expect(done, isTrue);
    });

    testWidgets('can be skipped from the first page', (t) async {
      var done = false;
      await t.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ExplainerScreen(onDone: () => done = true)));
      await t.tap(find.text('Skip'));
      expect(done, isTrue);
    });
  });
}
