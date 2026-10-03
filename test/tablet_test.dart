import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/main.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/root_screen.dart';
import 'package:improvy/services/storage_service.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// The app ships as an iPad app (TARGETED_DEVICE_FAMILY = "1,2") but every
/// screen in it is drawn for a phone held upright. Handed 1024pt the layouts do
/// not become a tablet app, they become a stretched phone — and Apple's
/// reviewers look at iPad.
///
/// So on a tablet the app lays out on a roomy phone and is scaled up whole to
/// fill the screen (TabletFit). This is the check that it does, and that the
/// screens still lay out inside it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  Future<void> pumpApp(WidgetTester t, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    provider.completeTutorial();

    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: const ImprovyApp(),
    ));
    await t.pump(const Duration(milliseconds: 700));
  }

  testWidgets('on an iPad the app fills the screen, laid out phone-sized',
      (t) async {
    // 12.9" portrait, the widest thing the app can be handed.
    await pumpApp(t, const Size(1024, 1366));

    // Laid out at a roomy phone's width…
    final logical = t.getSize(find.byType(RootScreen));
    expect(logical.width, inInclusiveRange(480, 700));
    expect(logical.height, greaterThanOrEqualTo(800));
    // …and drawn edge to edge, not as a strip in the middle.
    final rect = t.getRect(find.byType(RootScreen));
    expect(rect.left, closeTo(0, 1));
    expect(rect.width, closeTo(1024, 1));
    expect(rect.height, closeTo(1366, 1));
  });

  testWidgets('on a phone nothing is constrained at all', (t) async {
    await pumpApp(t, const Size(430, 932));
    expect(t.getSize(find.byType(RootScreen)).width, 430);
  });
}
