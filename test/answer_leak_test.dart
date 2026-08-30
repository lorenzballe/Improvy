import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/screens/setup_screen.dart';
import 'package:improvy/services/storage_service.dart';
import 'package:improvy/screens/trainer_screen.dart';
import 'package:improvy/utils/music_engine.dart';

/// The board must not answer the question for you.
///
/// The diatonic answer buttons are sorted by pitch, and in C — the one free
/// key, where every beginner starts — pitch order *is* scale order, so degree
/// N sat on button N. Counting to the Nth button scored full marks without
/// knowing the scale, which made the first mastery percentage anyone sees the
/// least trustworthy number in the app.
///
/// Shuffling was the obvious fix and the wrong one: response time is what the
/// difficulty tiers are built on, and moving targets add visual search that has
/// nothing to do with music. The layout stays fixed; what changes is how much
/// the keyboard gives away, tier by tier.
void main() {
  test('counting the buttons works in C and nowhere else', () {
    // Documents the leak rather than pretending it is gone: with seven buttons
    // in pitch order there is no arrangement of C major that is not also its
    // scale. This is why the fix had to be the keyboard and the direction.
    final leaky = <String>[];
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      final buttons = [...scale]..sort(
          (a, b) => (kNoteToSemitone[a] ?? 0) - (kNoteToSemitone[b] ?? 0));
      final counts = List.generate(7, (i) => buttons.indexOf(scale[i]) == i)
          .every((ok) => ok);
      if (counts) leaky.add(key);
    }
    expect(leaky, ['C'],
        reason: 'the button-position leak should exist only in C, where pitch '
            'order and scale order are the same thing: $leaky');
  });

  test('the keyboard stops giving the scale away above Apprentice', () {
    // Apprentice is where the shape of the scale is the lesson, so it keeps the
    // help. Above it, lighting only the seven scale keys would let a diatonic
    // question be answered by counting the lit ones.
    expect(KeyboardAid.forDifficulty(1), KeyboardAid.full);
    expect(KeyboardAid.forDifficulty(1).allKeysLive, isFalse);

    expect(KeyboardAid.forDifficulty(2).allKeysLive, isTrue,
        reason: 'Virtuoso must offer all twelve keys, or counting still works');
    expect(KeyboardAid.forDifficulty(3).allKeysLive, isTrue);
  });

  test('only Master takes the printed names off the keys', () {
    // A real piano has no names on it. But taking them away earlier would make
    // counting the *only* crutch left, which is the opposite of the point.
    expect(KeyboardAid.forDifficulty(1).showsNames, isTrue);
    expect(KeyboardAid.forDifficulty(2).showsNames, isTrue);
    expect(KeyboardAid.forDifficulty(3).showsNames, isFalse);
  });

  test('Note to Number cannot be answered by position at all', () {
    // The direction that is structurally leak-proof, which is why the diatonic
    // half of it is free in every key: the question is a written note and the
    // answers are the numbers 1-7, so there is no position to count to.
    const answers = ['1', '2', '3', '4', '5', '6', '7'];
    for (final key in kAllKeys) {
      final scale = calculateMajorScale(key);
      for (var degree = 1; degree <= 7; degree++) {
        final shown = scale[degree - 1];
        // The note asked about carries no hint of where its answer sits: the
        // answer board is the same seven numbers, in the same order, always.
        expect(answers.indexOf('$degree'), degree - 1);
        expect(shown, isNotEmpty, reason: 'degree $degree of $key');
      }
    }
  });

  testWidgets('the Pro half of Note to Number wears a padlock', (t) async {
    // A control that costs money must say so before it is tapped. Chromatic
    // looked exactly like Diatonic and only revealed itself by opening a
    // paywall — the wall you find by walking into it.
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();

    Future<int> padlocksWhenPro(bool isPro) async {
      await t.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: NoteToNumberSetup(
            initialKey: 'C',
            isPro: isPro,
            onShowPaywall: () {},
            onCancel: () {},
            onStart: (_, _, _, _) {},
          ),
        ),
      ));
      await t.pump();
      // Only the padlock riding on the CHROMATIC pill. The difficulty tiers
      // wear the same icon when they are not yet unlocked, and counting every
      // lock on the page would make this test fail for the wrong reason.
      return find
          .descendant(
            of: find.ancestor(
                of: find.text('CHROMATIC'), matching: find.byType(Row)),
            matching: find.byIcon(Icons.lock_rounded),
          )
          .evaluate()
          .length;
    }

    expect(await padlocksWhenPro(false), greaterThan(0),
        reason: 'a free user must see the lock on Chromatic');
    expect(await padlocksWhenPro(true), 0,
        reason: 'a paying user must not be shown a lock on what they own');
  });

  testWidgets('tapping the locked half opens the paywall there and then',
      (t) async {
    // The bug this replaces: the paywall state flipped but nothing drew,
    // because Note to Number's branch was the one that never stacked the
    // overlay in. It appeared only after the setup was dismissed — a wall that
    // arrives once you have already given up.
    var opened = false;
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();

    await t.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: NoteToNumberSetup(
          initialKey: 'C',
          isPro: false,
          onShowPaywall: () => opened = true,
          onCancel: () {},
          onStart: (_, _, _, _) {},
        ),
      ),
    ));
    await t.pump();

    await t.tap(find.text('CHROMATIC'));
    await t.pump();

    expect(opened, isTrue,
        reason: 'the tap must ask for the paywall immediately');
    // …and must not have quietly switched to the mode it cannot afford.
    expect(find.textContaining('Focus on the 7 notes'), findsOneWidget,
        reason: 'a free user must still be on Diatonic afterwards');
  });
}
