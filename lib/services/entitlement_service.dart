import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';

/// A Pro licence that was not bought in this app.
///
/// It lives in entitlements/{uid}, written by the server the moment a
/// payment on the website clears, and revoked there if the money goes back.
/// The app only reads it — the rules let nobody write it — and treats it
/// exactly like a store purchase or a promo code: a third door to the same
/// room.
///
/// Nothing in the app names where such a licence comes from, on purpose.
@immutable
class WebEntitlement {
  final String source;
  final DateTime? grantedAt;
  const WebEntitlement({required this.source, required this.grantedAt});
}

class EntitlementService {
  EntitlementService._();
  static final EntitlementService instance = EntitlementService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _ready => FirebaseConfig.isConfigured && Firebase.apps.isNotEmpty;

  /// The licence on this account, if any.
  ///
  /// By account id first. Then, for a VERIFIED address only, by email: the
  /// same person can have signed in with Google on the site and Apple here,
  /// and be two accounts sharing one address. An unverified address is
  /// anyone's to type, so it is never consulted — the rules refuse the query
  /// anyway, but the app should not even ask.
  Future<WebEntitlement?> lookup({
    required String uid,
    required String? email,
    required bool emailVerified,
  }) async {
    if (!_ready) return null;
    try {
      final own = await _db.collection('entitlements').doc(uid).get();
      final direct = _live(own.data());
      if (direct != null) return direct;

      if (email == null || !emailVerified) return null;
      final byEmail = await _db
          .collection('entitlements')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (byEmail.docs.isEmpty) return null;
      return _live(byEmail.docs.first.data());
    } catch (e) {
      if (kDebugMode) debugPrint('[Entitlement] lookup failed: $e');
      return null;
    }
  }

  /// A revoked licence is not a licence.
  static WebEntitlement? _live(Map<String, dynamic>? d) {
    if (d == null || d['pro'] != true || d['revokedAt'] != null) return null;
    final at = d['grantedAt'];
    return WebEntitlement(
      source: d['source'] as String? ?? 'web',
      grantedAt: at is Timestamp ? at.toDate() : null,
    );
  }
}
