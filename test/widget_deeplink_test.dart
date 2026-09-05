import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/root_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/screens/stats_screen.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/widgets/quiz_reveal_modal.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/services/widget_service.dart';

import 'screens_render_test.dart' show loadRealFonts;

/// A widget's whole reason to exist is the tap. "It opened the app" is what a
/// launcher icon does; a widget that only manages that is a launcher icon
/// taking up four times the room.
///
/// Every URI the widgets publish is exercised here against the real RootScreen,
/// both ways it can arrive: waiting when the app cold-starts, and delivered
/// while it is already running.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealFonts);

  /// Frames, not one long jump. Switching tabs is a ballistic scroll: a single
  /// pump past its duration moves the clock but not the simulation, and the
  /// page never arrives.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<AppProvider> pumpRoot(WidgetTester t, {Uri? waiting}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    provider.completeTutorial();

    // A tap that cold-started the app is already sitting in the notifier by
    // the time any screen is built.
    WidgetService.instance.pendingAction.value = waiting;

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(() => WidgetService.instance.pendingAction.value = null);

    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
          scaffoldBackgroundColor: const Color(0xFF0F0A1A),
          useMaterial3: true,
          fontFamily: 'Lexend',
        ),
        home: const RootScreen(),
      ),
    ));
    await settle(t);
    return provider;
  }

  /// Delivers a tap the way the plugin does while the app is already up.
  Future<void> tap(WidgetTester t, String uri) async {
    WidgetService.instance.pendingAction.value = Uri.parse(uri);
    await settle(t);
  }

  group('a tap lands somewhere', () {
    testWidgets('the question opens its reveal card', (t) async {
      await pumpRoot(t);
      await tap(t, 'improvy://quiz?s=${WidgetService.baseSlot(DateTime.now())}');
      expect(find.byType(QuizRevealModal), findsOneWidget);
    });

    testWidgets('the daily starts today\'s challenge', (t) async {
      final p = await pumpRoot(t);
      expect(p.activeMode, isNull);
      await tap(t, 'improvy://daily');
      expect(p.activeMode, isNotNull, reason: 'the run should have started');
    });

    testWidgets('the weakest key opens that key', (t) async {
      final p = await pumpRoot(t);
      await tap(t, 'improvy://key?k=A%E2%99%AD');
      expect(p.selectedKey, 'A♭');
    });

    testWidgets('pocket and custom open their setup', (t) async {
      await pumpRoot(t);
      await tap(t, 'improvy://pocket');
      expect(find.byType(PocketModeSetup), findsOneWidget);

      await pumpRoot(t);
      await tap(t, 'improvy://custom');
      expect(find.byType(CustomModeSetup), findsOneWidget);
    });

    testWidgets('chromatic starts a chromatic run', (t) async {
      // It has no setup screen, so pointing the tap at one left the app on
      // Home doing nothing at all.
      final p = await pumpRoot(t);
      await tap(t, 'improvy://chromatic');
      expect(p.activeMode, TrainingMode.chromatic);
      expect(find.byType(TrainerScreen), findsOneWidget);
    });

    testWidgets('stats and theory both land on the stats page', (t) async {
      for (final uri in ['improvy://stats', 'improvy://theory']) {
        await pumpRoot(t);
        await tap(t, uri);
        final stats = t.widget<StatsScreen>(find.byType(StatsScreen));
        expect(stats, isNotNull, reason: uri);
        // Built is not shown: the page has to be the one under the viewport.
        final box = t.renderObject<RenderBox>(find.byType(StatsScreen));
        final left = box.localToGlobal(Offset.zero).dx;
        expect(left, closeTo(0, 1), reason: '$uri should scroll to Statistics');
      }
    });
  });

  testWidgets('a tap waiting at launch is not dropped', (t) async {
    // The cold-start path: the plugin resolves the launch intent in main(),
    // before any screen exists, so RootScreen has to pick the value up rather
    // than wait for it to change.
    final p = await pumpRoot(t, waiting: Uri.parse('improvy://daily'));
    expect(p.activeMode, isNotNull);
  });

  testWidgets('a tap during a run is ignored, not queued', (t) async {
    final p = await pumpRoot(t);
    await tap(t, 'improvy://daily');
    final mode = p.activeMode;
    await tap(t, 'improvy://pocket');
    expect(p.activeMode, mode, reason: 'a run in progress is never interrupted');
  });
}
