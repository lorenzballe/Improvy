import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';
import 'analytics_service.dart';

/// Why a code was, or was not, accepted. One sentence each in the UI.
enum PromoOutcome {
  success,
  notSignedIn,
  alreadyRedeemed,
  malformed,
  unknown,
  inactive,
  exhausted,
  expired,
  offline,
  notConfigured,
  error,
}

/// The shape of a code as the author writes it in the Firebase console:
///
///     codes/LAUNCH2026   { active: true, maxUses: 50, uses: 0,
///                          expiresAt: <timestamp, optional>, note: "…" }
///
/// This is the decision the app makes from that document before it tries to
/// spend the code, so the person gets the real reason rather than the
/// permission error the rules would return. The rules make the same
/// decision again, on the server, with the server's clock.
abstract final class PromoCode {
  static final _shape = RegExp(r'^[A-Z0-9][A-Z0-9-]{2,30}[A-Z0-9]$');

  /// What the person typed, as the document is named: upper-case, no spaces.
  /// Null when it could not be a code at all, which saves the round trip.
  static String? normalise(String raw) {
    final s = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    return _shape.hasMatch(s) ? s : null;
  }

  /// Reads a code document the way the rules do.
  static PromoOutcome evaluate(Map<String, dynamic>? data, {required DateTime now}) {
    if (data == null) return PromoOutcome.unknown;
    if (data['active'] != true) return PromoOutcome.inactive;
    final uses = data['uses'];
    final max = data['maxUses'];
    if (uses is! int || max is! int) return PromoOutcome.inactive;
    if (uses >= max) return PromoOutcome.exhausted;
    final expires = data['expiresAt'];
    if (expires != null) {
      final DateTime? at = switch (expires) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        _ => null,
      };
      if (at == null || !at.isAfter(now)) return PromoOutcome.expired;
    }
    return PromoOutcome.success;
  }
}

/// Spends promo codes against Firestore. Requires a signed-in account: the
/// redemption is the account's, so that Pro-by-code follows the person.
class PromoCodeService {
  PromoCodeService._();
  static final PromoCodeService instance = PromoCodeService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _ready => FirebaseConfig.isConfigured;

  /// The code this account has already spent, if any.
  Future<String?> redeemedCode(String uid) async {
    if (!_ready) return null;
    try {
      final doc = await _db.collection('redemptions').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['code'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[Promo] redemption lookup failed: $e');
      return null;
    }
  }

  /// Spends [raw] for [uid]. One transaction: read the code, decide, then
  /// +1 on the code and a redemption for this account together — the rules
  /// accept neither write alone.
  Future<PromoOutcome> redeem(String raw, {required String? uid}) async {
    if (!_ready) return PromoOutcome.notConfigured;
    if (uid == null) return PromoOutcome.notSignedIn;
    final code = PromoCode.normalise(raw);
    if (code == null) return PromoOutcome.malformed;

    final codeRef = _db.collection('codes').doc(code);
    final mine = _db.collection('redemptions').doc(uid);
    try {
      final outcome = await _db.runTransaction<PromoOutcome>((tx) async {
        final already = await tx.get(mine);
        if (already.exists) return PromoOutcome.alreadyRedeemed;
        final snap = await tx.get(codeRef);
        final verdict = PromoCode.evaluate(snap.data(), now: DateTime.now());
        if (verdict != PromoOutcome.success) return verdict;
        tx.update(codeRef, {'uses': FieldValue.increment(1)});
        tx.set(mine, {'code': code, 'at': FieldValue.serverTimestamp()});
        return PromoOutcome.success;
      });
      AnalyticsService.instance.capture(
          outcome == PromoOutcome.success ? Ev.promoRedeemed : Ev.promoRejected,
          {'code': code, 'outcome': outcome.name});
      return outcome;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('[Promo] redeem failed: ${e.code} ${e.message}');
      final outcome = switch (e.code) {
        'unavailable' || 'deadline-exceeded' => PromoOutcome.offline,
        // The rules said no where the app said yes: the code changed between
        // the read and the write, or the clocks disagree on expiry.
        'permission-denied' => PromoOutcome.inactive,
        _ => PromoOutcome.error,
      };
      AnalyticsService.instance.capture(Ev.promoRejected, {'code': code, 'outcome': outcome.name, 'firestore': e.code});
      return outcome;
    } catch (e) {
      AnalyticsService.instance.error(Ev.promoRejected, e, {'code': code});
      return PromoOutcome.error;
    }
  }

  /// Gives up this account's redemption (account deletion).
  Future<void> forget(String uid) async {
    if (!_ready) return;
    try {
      await _db.collection('redemptions').doc(uid).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[Promo] forget failed: $e');
    }
  }
}
