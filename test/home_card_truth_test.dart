import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/models/stats.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/services/storage_service.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// The mode card on Home carries two numbers and they say different things.
/// "n/m BEST" is a record — a run that was actually played at that tier, never
/// inferred. The percentage is how far the tier is CREDITED, and credit flows
/// down and inward: a chromatic Master at 98% has proved every diatonic tier
/// at 98% too.
///
/// The card used to derive the percentage from the raw record, so a player who
/// had just scored 49/50 at chromatic Master opened the diatonic card and read
/// 0% — which is the one number on the screen they knew to be false.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  Future<AppProvider> chromaticMasterAt(int correct) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();
    p.setIsPro(true);
    p.selectKey('C');
    p.setChromaticDifficulty(3);
    p.startMode(TrainingMode.chromatic);
    for (var i = 0; i < correct; i++) {
      p.recordAnswer(
        isCorrect: true,
        responseTime: 800,
        answerDetails: AnswerRecord(
          degree: '♭3',
          note: 'E♭',
          selectedNote: 'E♭',
          tonality: 'C',
          mode: 'chromatic',
          isReverse: false,
          difficulty: 3,
          responseTime: 800,
          isCorrect: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    p.finishSession();
    p.exitTrainer();
    return p;
  }

  Future<void> pumpHome(WidgetTester t, AppProvider p) async {
    t.view.physicalSize = const Size(390, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
          scaffoldBackgroundColor: const Color(0xFF0F0A1A),
          useMaterial3: true,
          fontFamily: 'Lexend',
        ),
        home: HomeScreen(
          onShowPaywall: ([_]) {},
          onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {},
          onStartDaily: () {},
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 700));
  }

  testWidgets('a 98% chromatic Master is a 98% diatonic Apprentice', (t) async {
    final p = await chromaticMasterAt(49);
    final c = p.progressFor('C');
    expect(c.chromaticLevels, [0, 0, 49], reason: 'the record is raw');
    expect(c.effectiveDiatonic, [29, 39, 49], reason: '98% of 30, 40, 50');

    await pumpHome(t, p);

    // The diatonic card is sitting at Apprentice — no diatonic run was ever
    // played — and it must say so honestly on both lines: nothing scored
    // here, but the tier is 97% credited (29/30, rounded).
    expect(find.text('0/30 BEST'), findsOneWidget);
    expect(find.text('97%'), findsWidgets);
    expect(find.text('0%'), findsNothing,
        reason: 'nothing on this screen is at zero after a 49/50 Master');
  });

  testWidgets('an untouched key really is at zero', (t) async {
    final p = await chromaticMasterAt(0);
    await pumpHome(t, p);
    expect(find.text('0/30 BEST'), findsWidgets);
    expect(find.text('0%'), findsWidgets);
  });
}
