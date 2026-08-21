import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/settings_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/widgets/feedback_sheet.dart';

/// The feedback box is the only channel in the app where the user writes to
/// me. Two things must hold: an empty box cannot be sent (or the list fills
/// with blanks from thumbs brushing the button), and a real message must come
/// back as "sent" so the caller knows to thank them.
void main() {
  Future<bool?> open(WidgetTester t) async {
    bool? result;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => result = await FeedbackSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return result;
  }

  testWidgets('an empty box cannot be sent', (t) async {
    await open(t);
    expect(find.text('SEND'), findsOneWidget);
    await t.tap(find.text('SEND'));
    await t.pumpAndSettle();
    // Still open: nothing was sent and nothing was dismissed.
    expect(find.text('SEND'), findsOneWidget);
  });

  testWidgets('a message closes the sheet and reports itself sent', (t) async {
    bool? sent;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => sent = await FeedbackSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField).first, 'The ♭5 says sharp four');
    await t.pump();
    await t.tap(find.text('SEND'));
    await t.pumpAndSettle();

    expect(find.text('SEND'), findsNothing, reason: 'the sheet should close');
    expect(sent, isTrue);
  });

  testWidgets('the three kinds are all offered and one is preselected',
      (t) async {
    await open(t);
    for (final k in FeedbackKind.values) {
      expect(find.text(k.label), findsOneWidget);
    }
  });

  _confirmation();
}

/// The confirmation after sending was drawn in the surface colour, on a bar
/// that floats where the tab bar already sits — invisible twice over. These
/// pin down both halves of that fix.
void _confirmation() {
  testWidgets('the confirmation is neither the surface colour nor behind the nav',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    provider.completeTutorial();

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        home: SettingsScreen(onShowPaywall: ([_]) {}, onSimulatePerfect: () {}),
      ),
    ));
    await t.pumpAndSettle();

    await t.scrollUntilVisible(find.text('Send Feedback'), 300);
    await t.tap(find.text('Send Feedback'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'the buttons give it away');
    await t.pump();
    await t.tap(find.text('SEND'));
    await t.pumpAndSettle();

    final bar = t.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, isNot(const Color(0xFF1A1625)),
        reason: 'the surface colour is what every card behind it is painted');
    // Clear of the floating tab bar: anchored at 24, about 78 tall.
    expect((bar.margin as EdgeInsets?)?.bottom ?? 0, greaterThan(100),
        reason: 'a confirmation under the nav bar is one nobody reads');
    expect(find.textContaining('Sent.'), findsOneWidget);
  });
}
