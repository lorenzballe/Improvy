@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/purchase_service.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/paywall_modal.dart';

import 'store_screenshot_test.dart' show loadRealFonts;

/// The paywall as someone who typed a creator's code sees it: the real
/// widget, with the offer the store would return passed in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  for (final locale in const [Locale('it'), Locale('en')]) {
    testWidgets('creator paywall, ${locale.languageCode}', (t) async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();
      final p = AppProvider(storage);
      await p.init();
      p.completeTutorial();

      // 1290×2796: the 6.7" iPhone size App Store Connect accepts for the
      // in-app purchase's review screenshot (430×932 points at 3×).
      t.view.physicalSize = const Size(1290, 2796);
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
              PaywallModal(
                onClose: () {},
                onPurchase: () async {},
                creatorOffer: CreatorOffer(
                  code: 'MARCO10',
                  pct: 14,
                  regularPrice: locale.languageCode == 'it' ? '20,99 €' : '€20.99',
                  price: locale.languageCode == 'it' ? '17,99 €' : '€17.99',
                ),
              ),
            ]),
          ),
        ),
      ));
      await t.runAsync(() async {
        final ctx = t.element(find.byType(MaterialApp));
        await precacheImage(const AssetImage('assets/images/improvy_logo.png'), ctx);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump(const Duration(milliseconds: 1400));

      expect(find.textContaining('MARCO10'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/creator_paywall_${locale.languageCode}.png'),
      );
    });
  }
}
