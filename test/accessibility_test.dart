import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/home_screen.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/services/storage_service.dart';

/// Larger type must not break the screens, and the controls a screen reader
/// lands on must say what they are.
Future<AppProvider> providerWith() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  p.completeTutorial();
  return p;
}

Future<void> pumpAt(WidgetTester t, Widget child, double scale) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
    value: await providerWith(),
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(scale),
      ),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, fontFamily: 'Lexend'),
        home: child,
      ),
    ),
  ));
  await t.pump(const Duration(seconds: 2));
}

/// Every label a screen reader would be given, read off the real semantics
/// tree rather than through a finder — the finder matches per render object
/// and misses a label that a wrapper has merged in.
List<String> spokenLabels(WidgetTester t) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) out.add(n.label);
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }
  // The app's own node, through the test API, rather than a pipeline owner:
  // the root owner has no semantics owner of its own, and the one on the
  // view is deprecated to reach into.
  walk(t.getSemantics(find.byType(MaterialApp)));
  return out;
}

void main() {
  group('large type', () {
    for (final scale in [1.3]) {
      testWidgets('home renders at $scale× without overflowing', (t) async {
        await pumpAt(t, HomeScreen(onShowPaywall: ([_]) {}, onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {}, onStartDaily: () {}), scale);
        expect(t.takeException(), isNull);
      });
      testWidgets('settings renders at $scale× without overflowing', (t) async {
        await pumpAt(t, SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}), scale);
        expect(t.takeException(), isNull);
      });
      testWidgets('a setup screen renders at $scale× without overflowing', (t) async {
        await pumpAt(
            t,
            NoteToNumberSetup(
                initialKey: 'C', isPro: true, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
            scale);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('screen reader', () {
    testWidgets('a key cell says its name and standing', (t) async {
      final handle = t.ensureSemantics();
      await pumpAt(
          t,
          NoteToNumberSetup(
              initialKey: 'C', isPro: true, onShowPaywall: () {}, onCancel: () {}, onStart: (_, _, _, _) {}),
          1.0);
      expect(spokenLabels(t).where((l) => RegExp(r'^G, \d+ percent$').hasMatch(l)), hasLength(1));
      // Disposed here, not in a tearDown: the framework checks for live
      // handles before tearDowns run.
      handle.dispose();
    });

    testWidgets('a home key tile says its name and standing', (t) async {
      final handle = t.ensureSemantics();
      await pumpAt(t, HomeScreen(onShowPaywall: ([_]) {}, onOpenSetup: (_, {ofWhatNote, ofWhatDegrees}) {}, onStartDaily: () {}), 1.0);
      expect(spokenLabels(t).where((l) => RegExp(r'^Key of C, \d+ percent$').hasMatch(l)), hasLength(1));
      handle.dispose();
    });
  });
}
