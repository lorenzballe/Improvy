import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/services/analytics_service.dart';

/// Analytics fails quietly or not at all: a misspelled event name does not
/// throw, it just creates a second event that looks like the first one in the
/// dashboard and splits a funnel in half. These make that a test failure.
void main() {
  final source = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.readAsStringSync())
      .join('\n');

  test('no event name is written as a bare string', () {
    // Everything goes through Ev, so the compiler catches a typo that a
    // dashboard never would.
    final literals = RegExp(r"capture\('([a-z_$]+)'")
        .allMatches(source)
        .map((m) => m.group(1))
        .toList();
    expect(literals, isEmpty,
        reason: 'these bypass the Ev dictionary: $literals');
  });

  test('the event names are snake_case and distinct', () {
    final names = RegExp(r"static const [a-zA-Z]+ = '([^']+)'")
        .allMatches(File('lib/services/analytics_service.dart').readAsStringSync())
        .map((m) => m.group(1)!)
        .toList();
    expect(names.length, greaterThan(30),
        reason: 'the dictionary lost entries');
    expect(names.toSet().length, names.length,
        reason: 'two constants share one event name, which merges them in the '
            'dashboard: $names');
    for (final n in names) {
      expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(n), isTrue,
          reason: '"$n" is not snake_case — mixed conventions make the event '
              'list unreadable');
    }
  });

  test('the funnels that matter are all instrumented', () {
    // Not "is this event defined" but "is it actually sent from somewhere".
    // A dictionary entry nothing fires is a chart that stays empty forever.
    for (final ev in [
      Ev.onboardingCompleted,
      Ev.firstSessionCompleted,
      Ev.sessionStarted,
      Ev.sessionFinished,
      Ev.dailyStarted,
      Ev.dailyFinished,
      Ev.lockedFeatureTapped,
      Ev.paywallShown,
      Ev.paywallDismissed,
      Ev.purchaseStarted,
      Ev.purchaseSucceeded,
      Ev.purchaseFailed,
      Ev.pocketStarted,
      Ev.pocketFinished,
      Ev.freeModeOpened,
      Ev.settingChanged,
      Ev.startupStepFailed,
      Ev.audioSessionFailed,
      Ev.feedbackSubmitted,
    ]) {
      final constant = RegExp("static const ([a-zA-Z]+) = '$ev'")
          .firstMatch(File('lib/services/analytics_service.dart').readAsStringSync())
          ?.group(1);
      expect(source.contains('Ev.$constant'), isTrue,
          reason: '$ev is declared but never sent');
    }
  });

  test('a purchase can always be traced back to what was locked', () {
    // A conversion rate with no source cannot say which door sells, which is
    // the only question the money funnel exists to answer.
    expect(source.contains("'source': paywallSource"), isTrue);
    expect(source.contains('takeLockedFeature()'), isTrue);
  });
}
