@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/explainer_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/l10n/l10n.dart';

import 'store_screenshot_test.dart' show loadRealFonts;

/// Renders the reworked setups to PNGs, with a believable save behind them —
/// the outlines only say anything once some keys have been taken further than
/// others.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ntn = {
    'C': [30, 40, 50], 'G': [30, 40, 12], 'D': [30, 22, 0], 'F': [30, 40, 30],
    'A': [18, 0, 0], 'B♭': [28, 5, 0], 'E♭': [9, 0, 0], 'E': [30, 34, 0],
  };
  const harm = {
    'C': [30, 40, 33], 'F': [30, 12, 0], 'A': [21, 0, 0],
    'D': [30, 40, 50], 'B': [7, 0, 0], 'G': [30, 18, 0],
  };

  Future<AppProvider> seeded() async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();
    p.progressData = p.progressData
        .map((k) => k.copyWith(
              ntnDiatonicLevels: List<int>.from(ntn[k.key] ?? const [0, 0, 0]),
              harmonizerLevels: List<int>.from(harm[k.key] ?? const [0, 0, 0]),
            ))
        .toList();
    return p;
  }

  Future<void> shot(WidgetTester t, Widget child, String name) async {
    await loadRealFonts();
    t.view.physicalSize = const Size(780, 1800);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: await seeded(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Lexend', useMaterial3: true),
        home: child,
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  explainerShots();

  testWidgets('note to number, in Italian', (t) async {
    await loadRealFonts();
    t.view.physicalSize = const Size(780, 1800);
    t.view.devicePixelRatio = 2.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final p = await seeded();
    p.setNotation('DoReMi');
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        theme: ThemeData(fontFamily: 'Lexend', useMaterial3: true),
        home: NoteToNumberSetup(
            initialKey: 'C', isPro: true, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/shot_note_to_number_it.png'));
  });

  testWidgets('note to number', (t) async {
    await shot(
      t,
      NoteToNumberSetup(
        initialKey: 'C',
        isPro: true,
        onShowPaywall: () {},
        onCancel: () {},
        onStart: (_, _, _, _) {},
      ),
      'shot_note_to_number',
    );
  });

  testWidgets('of what', (t) async {
    await shot(
      t,
      OfWhatSetup(
        isPro: true,
        onShowPaywall: () {},
        onCancel: () {},
        onStart: (_, _, _, _) {},
      ),
      'shot_of_what',
    );
  });

  testWidgets('custom', (t) async {
    await shot(
      t,
      CustomModeSetup(
        initialKey: 'C',
        onStart: (_, _, _, _, _) {},
        onCancel: () {},
      ),
      'shot_custom',
    );
  });
}

/// The three explainer pages, for looking at.
void explainerShots() {
  for (final (i, page) in ['explainer_1', 'explainer_2', 'explainer_3'].indexed) {
    testWidgets(page, (t) async {
      await loadRealFonts();
      t.view.physicalSize = const Size(780, 1690);
      t.view.devicePixelRatio = 2.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(fontFamily: 'Lexend', useMaterial3: true),
        home: ExplainerScreen(onDone: () {}),
      ));
      await t.pumpAndSettle();
      for (var k = 0; k < i; k++) {
        await t.tap(find.text('Next'));
        await t.pumpAndSettle();
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/shot_$page.png'));
    });
  }
}
