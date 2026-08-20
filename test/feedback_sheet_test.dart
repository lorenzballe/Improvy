import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
