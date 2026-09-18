import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/daily_challenge_card.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// The daily card states two things nobody could work out for themselves: how
/// hard today is, and how hard tomorrow will be.
///
/// Checked by reading the card rather than by a picture of it: every word on
/// this card is derived from the date, and the countdown moves every minute,
/// so a stored image would be stale by tomorrow and wrong within the hour.
/// Both cards are still built at the narrowest phone the app supports — that
/// is where a new chip on an already-full row would be clipped instead of
/// shown, and a clipped row fails the test on its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppProvider> provider({bool played = false}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    if (played) {
      final today = p.todayChallenge;
      p.dailyResults = {
        today.dateKey: DailyResult(
          dateKey: today.dateKey,
          key: today.key,
          answers: List.generate(
              DailyChallenge.questionCount, (i) => i % 5 != 3),
          timeMs: 28400,
          completed: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          mode: today.mode,
        ),
      };
    }
    return p;
  }

  Future<void> show(WidgetTester t, AppProvider p) async {
    await t.runAsync(loadRealFonts);
    t.view.physicalSize = const Size(320, 200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
          scaffoldBackgroundColor: const Color(0xFF0F0A1A),
          useMaterial3: true,
          fontFamily: 'Lexend',
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              // The home screen hands the card a height it decides for
              // itself; a bare Center does not, and the Stack inside then
              // takes everything it is offered.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [DailyChallengeCard(onStart: () {})],
              ),
            ),
          ),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('not played — the card says how hard today is', (t) async {
    final p = await provider();
    await show(t, p);
    final today = p.todayChallenge;
    expect(find.text(today.rating.label.toUpperCase()), findsOneWidget);
  });

  testWidgets('played — the card says what tomorrow holds', (t) async {
    final p = await provider(played: true);
    await show(t, p);
    final tomorrow = DailyChallenge.tomorrow();
    expect(find.text(L10n.current.dailyNextUp(tomorrow.modeLabel)), findsOneWidget);
    expect(find.text(tomorrow.rating.label.toUpperCase()), findsOneWidget);
    // Today's score is still the headline; the forecast is a footnote.
    expect(find.text('12/${DailyChallenge.questionCount}'), findsOneWidget);
  });
}
