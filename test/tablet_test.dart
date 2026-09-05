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
/// So the app keeps itself to a phone-width column on anything wider. This is
/// the check that it does, and that the screens still lay out inside it.
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

  testWidgets('on an iPad the app is a phone-width column, not a stretch',
      (t) async {
    // 12.9" portrait, the widest thing the app can be handed.
    await pumpApp(t, const Size(1024, 1366));

    final width = t.getSize(find.byType(RootScreen)).width;
    expect(width, lessThanOrEqualTo(480),
        reason: 'the app should be a column, not the whole slab');
    // And centred on the app's own ground rather than pinned to one edge.
    final centre = t.getCenter(find.byType(RootScreen));
    expect(centre.dx, closeTo(512, 1));
  });

  testWidgets('on a phone nothing is constrained at all', (t) async {
    await pumpApp(t, const Size(430, 932));
    expect(t.getSize(find.byType(RootScreen)).width, 430);
  });
}
