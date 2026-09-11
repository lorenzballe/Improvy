@Tags(['golden'])
library;

import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/account_service.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/account_card.dart';
import 'package:improvy/widgets/account_sheet.dart';
import 'package:improvy/widgets/promo_code_card.dart';

import 'store_screenshot_test.dart' show loadRealFonts;

/// Pictures of the account and promo-code surfaces, drawn from the real
/// widgets rather than a mock-up, so what gets argued about is what ships.
/// Italian, because that is the audience being shown them.
///
///   flutter test test/account_gallery_test.dart --tags golden --run-skipped --update-goldens
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AccountService.instance.user.value = null);

  Future<AppProvider> provider({String? code}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    p.completeTutorial();
    if (code != null) p.setCodePro(true, code);
    return p;
  }

  /// One page, laid out at phone width and drawn at 2×: vector all the way,
  /// so the PNG is crisp rather than an upscale of a small capture.
  Future<void> page(
    WidgetTester t,
    Size size,
    Widget child,
    String file, {
    Future<void> Function()? after,
  }) async {
    await loadRealFonts();
    // The sheet leads with Apple on an iPhone and with Google everywhere
    // else. These are the iPhone pictures. It has to be put back before the
    // body returns: the framework checks that no foundation debug variable
    // outlives a test.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    t.view.physicalSize = Size(size.width * 2, size.height * 2);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
        scaffoldBackgroundColor: const Color(0xFF0F0A1A),
        useMaterial3: true,
        fontFamily: 'Lexend',
      ),
      // Align first: as the route's direct child a SizedBox is handed tight
      // constraints and ignored, which laid the page out at twice its width
      // and pushed the second panel off the edge. Align passes loose ones, so
      // the page really is [size], and the transform then draws it at 2× —
      // vector all the way, so the PNG is crisp rather than an upscale.
      home: Align(
        alignment: Alignment.topLeft,
        child: Transform.scale(
          scale: 2,
          alignment: Alignment.topLeft,
          child: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 400));
    if (after != null) await after();
    // The app, not the page: the page is [size], and it is the view above it
    // that carries the 2× transform.
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$file'));
    debugDefaultTargetPlatformOverride = null;
  }

  testWidgets('the sign-in sheet', (t) async {
    await page(
      t,
      const Size(840, 660),
      const _Page(children: [
        _Panel(title: 'TRE PORTE', child: AccountSheet()),
        _Panel(title: 'CON EMAIL', child: AccountSheet()),
      ]),
      'account_sheet.png',
      after: () async {
        // The right-hand copy opens its email form.
        await t.tap(find.byKey(const Key('account-email')).at(1));
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 80));
        }
      },
    );
  });

  // The card reads one global notifier, so two copies on a page can never
  // show two different states. Two pages instead: before and after.
  testWidgets('settings, signed out', (t) async {
    final empty = await provider();
    final typed = await provider();
    await page(
      t,
      const Size(1260, 215),
      _Page(children: [
        _Panel(title: 'ACCOUNT', child: _card(empty, const AccountCard())),
        _Panel(title: 'CODICI PROMOZIONALI', child: _card(empty, const PromoCodeCard())),
        _Panel(title: 'CODICE SCRITTO', child: _card(typed, const PromoCodeCard())),
      ]),
      'account_settings_out.png',
      after: () async {
        await t.enterText(find.byKey(const Key('promo-field')).at(1), 'LANCIO2026');
        await t.pump(const Duration(milliseconds: 200));
      },
    );
  });

  testWidgets('settings, signed in with a code', (t) async {
    final done = await provider(code: 'LANCIO2026');
    AccountService.instance.user.value = const AccountUser(
        uid: 'u1', email: 'lorenzo@improvy.app', provider: 'google.com');
    await page(
      t,
      const Size(840, 225),
      _Page(children: [
        _Panel(title: 'ACCOUNT', child: _card(done, const AccountCard())),
        _Panel(title: 'CODICE RISCATTATO', child: _card(done, const PromoCodeCard())),
      ]),
      'account_settings_in.png',
    );
  });
}

/// The Settings card these live in: same fill, same radius, same inset.
Widget _card(AppProvider p, Widget child) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: p,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1625),
          border: Border.all(color: Colors.white.withAlpha(13)),
          borderRadius: BorderRadius.circular(32),
        ),
        child: child,
      ),
    );

class _Page extends StatelessWidget {
  final List<Widget> children;
  const _Page({required this.children});

  @override
  Widget build(BuildContext context) => Material(
        // Text fields want a Material above them; in the app that is the
        // Scaffold this page does not have.
        color: const Color(0xFF0F0A1A),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in children) ...[
                Expanded(child: c),
                if (c != children.last) const SizedBox(width: 20),
              ],
            ],
          ),
        ),
      );
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white.withAlpha(102),
              )),
          const SizedBox(height: 10),
          child,
        ],
      );
}
