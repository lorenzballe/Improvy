@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/services/storage_service.dart';

/// Renders the two screens where the accidentals are hardest to typeset, so a
/// change to their alignment can be looked at rather than argued about. Run
/// with `--update-goldens` to refresh the images in `test/goldens/`.
///
/// Deterministic on purpose: the chromatic question is pinned to a single
/// degree, because a screenshot of a random question proves nothing.
Future<void> loadRealFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await family('Lexend', [
    'Lexend-Light.ttf', 'Lexend-Regular.ttf', 'Lexend-Medium.ttf',
    'Lexend-SemiBold.ttf', 'Lexend-Bold.ttf', 'Lexend-ExtraBold.ttf',
    'Lexend-Black.ttf',
  ]);
  await family('Outfit', [
    'Outfit-Light.ttf', 'Outfit-Regular.ttf', 'Outfit-Medium.ttf',
    'Outfit-SemiBold.ttf', 'Outfit-Bold.ttf',
  ]);
  await family('NotoMusic', ['NotoMusic-Regular.ttf']);

  // Material's icon font lives in the SDK, not the app's assets. Without it
  // every icon renders as an empty box and the screenshots misrepresent the
  // screen they are supposed to show.
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons');
    loader.addFont(
        icons.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)));
    await loader.load();
  }
}

Future<AppProvider> freshProvider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  Future<void> show(WidgetTester t, Widget child, AppProvider p) async {
    t.view.physicalSize = const Size(412, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
            scaffoldBackgroundColor: const Color(0xFF0F0A1A),
            useMaterial3: true,
            fontFamily: 'Lexend',
          ),
          home: child,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 900));
  }

  testWidgets('a sharp question sits level with its number', (t) async {
    final p = await freshProvider();
    await show(
      t,
      TrainerScreen(
        mode: TrainingMode.custom,
        selectedKey: 'C',
        difficulty: 1,
        // One degree, so the question asked is always ♯4 — a bare sharp in
        // front of a digit, which is the pairing that looked wrong.
        customDegrees: const ['♯4'],
        isReverse: false,
        adaptiveDifficulty: false,
        sessionHistory: const [],
        notation: 'CDE',
        onExit: () {},
        onAnswer: (_, __, ___) {},
        onFinish: (_) {},
      ),
      p,
    );
    await expectLater(
      find.byType(TrainerScreen),
      matchesGoldenFile('goldens/question_sharp.png'),
    );
  });

  testWidgets('the mode cards for a key', (t) async {
    final p = await freshProvider();
    p.selectKey('C');
    await show(
      t,
      HomeScreen(onShowPaywall: ([_]) {}, onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {}, onStartDaily: () {}),
      p,
    );
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/choose_mode.png'),
    );
  });
}
