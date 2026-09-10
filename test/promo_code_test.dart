import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/services/promo_code_service.dart';

/// The decision the app makes from a code document, before it spends the
/// code. firestore.rules makes the same decision on the server; the two are
/// kept in step by tool/firestore_rules, this pins the client half.
void main() {
  final now = DateTime(2026, 9, 10, 12);
  Map<String, dynamic> code({
    bool active = true,
    int uses = 0,
    int maxUses = 10,
    DateTime? expiresAt,
  }) =>
      {
        'active': active,
        'uses': uses,
        'maxUses': maxUses,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt),
      };

  group('what counts as a code', () {
    test('is upper-cased and stripped of spaces', () {
      expect(PromoCode.normalise('  launch 2026 '), 'LAUNCH2026');
      expect(PromoCode.normalise('amici-10'), 'AMICI-10');
    });

    test('has to look like one', () {
      expect(PromoCode.normalise(''), isNull);
      expect(PromoCode.normalise('ab'), isNull, reason: 'too short to be deliberate');
      expect(PromoCode.normalise('-ABCD'), isNull, reason: 'cannot start on a dash');
      expect(PromoCode.normalise('ABCD-'), isNull);
      expect(PromoCode.normalise('A' * 33), isNull);
      expect(PromoCode.normalise('A' * 32), 'A' * 32);
      expect(PromoCode.normalise('codé'), isNull, reason: 'ASCII only, like the console');
    });
  });

  group('a code document', () {
    test('that does not exist is unknown', () {
      expect(PromoCode.evaluate(null, now: now), PromoOutcome.unknown);
    });

    test('that is live is accepted', () {
      expect(PromoCode.evaluate(code(), now: now), PromoOutcome.success);
      expect(PromoCode.evaluate(code(uses: 9, maxUses: 10), now: now), PromoOutcome.success);
    });

    test('switched off is inactive', () {
      expect(PromoCode.evaluate(code(active: false), now: now), PromoOutcome.inactive);
    });

    test('with its uses spent is exhausted', () {
      expect(PromoCode.evaluate(code(uses: 10, maxUses: 10), now: now), PromoOutcome.exhausted);
      expect(PromoCode.evaluate(code(uses: 11, maxUses: 10), now: now), PromoOutcome.exhausted);
    });

    test('past its date is expired, up to the minute', () {
      expect(PromoCode.evaluate(code(expiresAt: now.subtract(const Duration(minutes: 1))), now: now),
          PromoOutcome.expired);
      expect(PromoCode.evaluate(code(expiresAt: now), now: now), PromoOutcome.expired);
      expect(PromoCode.evaluate(code(expiresAt: now.add(const Duration(days: 1))), now: now),
          PromoOutcome.success);
    });

    test('with the counters mistyped in the console is not spendable', () {
      // The rules refuse it too; refusing here gives a sentence instead of
      // a permission error.
      expect(PromoCode.evaluate({'active': true, 'uses': '0', 'maxUses': 10}, now: now),
          PromoOutcome.inactive);
      expect(PromoCode.evaluate({'active': true, 'uses': 0}, now: now), PromoOutcome.inactive);
    });

    test('checks in the order a person would want to hear', () {
      // Off beats exhausted beats expired: "no longer active" is the reason
      // the author chose, the others are consequences.
      expect(PromoCode.evaluate(code(active: false, uses: 10, maxUses: 10), now: now),
          PromoOutcome.inactive);
    });
  });
}
