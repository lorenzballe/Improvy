import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/levels.dart';
import 'package:improvy/constants/release_notes.dart';
import 'package:improvy/widgets/level_up_modal.dart';
import 'package:improvy/widgets/quiz_reveal_modal.dart';
import 'package:improvy/widgets/whats_new_modal.dart';

/// Every modal that animates IN must animate back OUT.
///
/// Each of these used to hand control back the instant it was tapped, so the
/// sheet that had just slid up vanished mid-air and read as a glitch rather
/// than a dismissal. The contract is now: the callback fires only once the
/// exit has played, which is exactly what these assert — tap, confirm nothing
/// has fired yet, then let the animation finish and confirm it has.
///
/// Checking the callback (rather than pixels) is the point: it is the thing
/// that tears the modal off screen, so if it fires early there is no exit to
/// see no matter how the animation is written.
void main() {
  Future<void> pumpIn(WidgetTester t, Widget child) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Stack(children: [child]))));
    await t.pump(const Duration(milliseconds: 600)); // let the entrance land
  }

  testWidgets("what's new: CONTINUE lowers the sheet before it hands back", (t) async {
    var read = 0;
    await pumpIn(t, WhatsNewModal(
      release: kReleases.first,
      onDismiss: () {},
      onRead: () => read++,
    ));

    await t.tap(find.text('CONTINUE'));
    await t.pump(const Duration(milliseconds: 60));
    expect(read, 0, reason: 'fired before the sheet had begun to drop');

    await t.pump(const Duration(milliseconds: 400));
    expect(read, 1);
  });

  testWidgets("what's new: the backdrop leaves the same way", (t) async {
    var dismissed = 0;
    await pumpIn(t, WhatsNewModal(
      release: kReleases.first,
      onDismiss: () => dismissed++,
      onRead: () {},
    ));

    // Top-left corner is backdrop: the sheet is anchored to the bottom.
    await t.tapAt(const Offset(10, 10));
    await t.pump(const Duration(milliseconds: 60));
    expect(dismissed, 0);

    await t.pump(const Duration(milliseconds: 400));
    expect(dismissed, 1);
  });

  testWidgets('quiz reveal: closing rewinds the entrance', (t) async {
    var closed = 0;
    await pumpIn(t, QuizRevealModal(
      question: '♭3',
      answer: 'E♭',
      musicalKey: 'C',
      onClose: () => closed++,
      onTrainKey: () {},
    ));

    await t.tapAt(const Offset(10, 10)); // backdrop
    await t.pump(const Duration(milliseconds: 60));
    expect(closed, 0);

    await t.pump(const Duration(milliseconds: 400));
    expect(closed, 1);
  });

  testWidgets('level up: Awesome! plays the entrance backwards', (t) async {
    var closed = 0;
    await pumpIn(t, LevelUpModal(
      animal: getAnimalLevel(100),
      onClose: () => closed++,
    ));

    await t.tap(find.text('Awesome!'));
    await t.pump(const Duration(milliseconds: 60));
    expect(closed, 0);

    await t.pump(const Duration(milliseconds: 600));
    expect(closed, 1);
  });

  testWidgets('a second tap during the exit does not fire it twice', (t) async {
    var read = 0;
    await pumpIn(t, WhatsNewModal(
      release: kReleases.first,
      onDismiss: () {},
      onRead: () => read++,
    ));

    await t.tap(find.text('CONTINUE'));
    await t.pump(const Duration(milliseconds: 40));
    await t.tap(find.text('CONTINUE'), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 500));
    expect(read, 1, reason: 'the guard let a second tap through');
  });
}
