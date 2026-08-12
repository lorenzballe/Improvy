@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/paywall_modal.dart';

/// One-off: renders the real paywall widget to a PNG for App Store Connect's
/// mandatory "App Review screenshot" on the in-app purchase. Apple asks for at
/// least 640×920; 390×844 logical at devicePixelRatio 2 gives 780×1688.
///
/// It is the shipping widget, not a mockup — the same tree the app builds, so
/// what the reviewer sees is what a customer sees.
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

  // Material's own icon font is not bundled with the app, so the test runner
  // has no glyphs for Icons.* and draws every one as an empty box. Load it
  // from the SDK cache, or the shot shows the paywall with holes in it.
  final iconFont = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (iconFont.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconFont.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  testWidgets('paywall for App Store Connect', (t) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();

    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2.0;
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
          home: Scaffold(
            backgroundColor: const Color(0xFF0F0A1A),
            body: Stack(children: [
              PaywallModal(onClose: () {}, onPurchase: () async {}),
            ]),
          ),
        ),
      ),
    );
    // The logo is an Image.asset, and asset decoding is real async I/O that a
    // widget test's fake clock never lets finish — without this it renders as
    // an empty box. runAsync gives it a real event loop for a moment.
    await t.runAsync(() async {
      final ctx = t.element(find.byType(MaterialApp));
      await precacheImage(const AssetImage('assets/images/improvy_logo.png'), ctx);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    // The entrance runs 700ms; settle past it so the shot is the resting state.
    await t.pump(const Duration(milliseconds: 1400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/iap_review_paywall.png'),
    );
  });
}
