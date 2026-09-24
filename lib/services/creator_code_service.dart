import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';
import 'promo_code_service.dart';

/// A creator's discount code, e.g. MARCO10 — the same code their audience
/// types on the website, recognised in the app too.
///
///     creators/{CODE}   { active: bool, ref: string, pct: int }
///
/// Written only by the New creator workflow. Unlike a free-Pro code it spends
/// nothing and needs no account: it only chooses which price the store shows
/// and records who sent the buyer, so anyone may look one up.
@immutable
class CreatorCode {
  final String code;
  final String ref;
  final int pct;
  const CreatorCode({required this.code, required this.ref, required this.pct});
}

class CreatorCodeService {
  CreatorCodeService._();
  static final CreatorCodeService instance = CreatorCodeService._();

  bool get _ready => FirebaseConfig.isConfigured && Firebase.apps.isNotEmpty;

  /// The creator behind [raw], or null when it is not a live creator code —
  /// in which case the caller treats it as an ordinary promo code.
  Future<CreatorCode?> lookup(String raw) async {
    final code = PromoCode.normalise(raw);
    if (code == null || !_ready) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('creators').doc(code).get();
      final d = doc.data();
      if (d == null || d['active'] != true) return null;
      final ref = d['ref'];
      final pct = d['pct'];
      if (ref is! String || ref.isEmpty) return null;
      return CreatorCode(code: code, ref: ref, pct: pct is int ? pct : 0);
    } catch (e) {
      if (kDebugMode) debugPrint('[Creator] lookup failed: $e');
      return null;
    }
  }
}
