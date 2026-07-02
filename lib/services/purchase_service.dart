import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'analytics_service.dart';

/// Single entry point for in-app purchases, backed by **RevenueCat**.
///
/// The whole app only ever reads PRO status through [AppProvider.isPro]; this
/// service is what keeps that flag in sync with the user's real entitlements.
/// Wire it once in `main()`:
///
/// ```dart
/// PurchaseService.instance.onProChanged = provider.setIsPro;
/// await PurchaseService.instance.init();
/// ```
///
/// What you still configure outside the app (RevenueCat dashboard + stores):
///   • An **Entitlement** (its identifier is [entitlementId]).
///   • A **Product** `improvy_pro_lifetime` (Non-Consumable / lifetime) created in
///     App Store Connect & Play Console, then attached to a **Package** inside the
///     **current Offering**.
///   • (Optional) A **Paywall** on that offering to use [presentPaywall], and the
///     **Customer Center** for [presentCustomerCenter].
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// RevenueCat **public** SDK keys. Public keys are designed to ship inside the
  /// app binary (they are not the secret key), so hard-coding them here is safe.
  /// Each platform uses its own key from RevenueCat → Project settings → API keys.
  static const String _androidApiKey = 'goog_DzefZojgkijVyeXxsKjLunDbctO';
  // TODO: replace with your iOS key (starts with `appl_`) when you set up iOS.
  static const String _iosApiKey = 'appl_REPLACE_WITH_YOUR_IOS_KEY';

  static String get _apiKey =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosApiKey : _androidApiKey;

  /// Entitlement identifier as set in RevenueCat → Entitlements. We actually
  /// gate on "any active entitlement" below (robust for a single-entitlement
  /// app); switch to a per-id check if you ever sell more than one entitlement.
  static const String entitlementId = 'pro';
  static const String proProductId = 'improvy_pro_lifetime';

  bool _isPro = false;
  bool get isPro => _isPro;

  bool _configured = false;

  /// Fired whenever PRO status changes — from a purchase, a restore, or a remote
  /// update pushed by RevenueCat (e.g. a refund, or a buy on another device).
  void Function(bool isPro)? onProChanged;

  Future<void> init() async {
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
      // Push the real, authoritative status (overrides any stale cached flag).
      await _refresh(force: true);
      // Keep the flag live for the rest of the session.
      Purchases.addCustomerInfoUpdateListener(_apply);
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] init failed: $e');
    }
  }

  /// Localized price of the lifetime PRO product (e.g. "€16,99"), straight from
  /// the store via RevenueCat. Null until an offering with a package exists.
  Future<String?> proPriceString() async {
    final offerings = await getOfferings();
    final current = offerings?.current;
    if (current == null) return null;
    final pkg = current.lifetime ??
        (current.availablePackages.isNotEmpty ? current.availablePackages.first : null);
    return pkg?.storeProduct.priceString;
  }

  /// Returns the configured offerings, or null if unavailable / not yet set up.
  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] getOfferings failed: $e');
      return null;
    }
  }

  /// Launches the native purchase flow for the lifetime PRO package.
  /// Returns true when PRO is active afterwards; false on cancel / no product.
  Future<bool> purchasePro() async {
    if (!_configured) return false;
    AnalyticsService.instance.capture('pro_purchase_start');
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        if (kDebugMode) debugPrint('[PurchaseService] no packages in current offering');
        return false;
      }
      // Prefer the lifetime package; fall back to whatever the offering exposes.
      final package = current.lifetime ?? current.availablePackages.first;
      // Modern unified purchase API (replaces the deprecated purchasePackage).
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) debugPrint('[PurchaseService] purchase cancelled by user');
      } else {
        if (kDebugMode) debugPrint('[PurchaseService] purchase error: $code');
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] purchase failed: $e');
      return false;
    }
    await _refresh(force: true);
    if (_isPro) AnalyticsService.instance.capture('pro_purchase_success');
    return _isPro;
  }

  /// Restores a previous purchase (uses the signed-in App Store / Play account —
  /// no email needed). Returns true when PRO is found.
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] restore failed: $e');
      return false;
    }
    await _refresh(force: true);
    AnalyticsService.instance.capture('pro_restore', {'found': _isPro});
    return _isPro;
  }

  /// Presents the RevenueCat-hosted **Paywall** (design it in the dashboard for
  /// the current offering). Returns true if the user ends up with PRO.
  /// Until you publish a paywall this is a no-op — keep using [PaywallModal].
  Future<bool> presentPaywall() async {
    if (!_configured) return false;
    try {
      await RevenueCatUI.presentPaywall();
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] presentPaywall failed: $e');
    }
    await _refresh(force: true);
    return _isPro;
  }

  /// Presents the RevenueCat **Customer Center** (restore, manage, contact
  /// support, request refunds where the store allows it).
  Future<void> presentCustomerCenter() async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] customerCenter failed: $e');
    }
    await _refresh(force: true);
  }

  // ── internals ──────────────────────────────────────────────────────────────

  Future<void> _refresh({bool force = false}) async {
    try {
      _apply(await Purchases.getCustomerInfo(), force: force);
    } catch (e) {
      if (kDebugMode) debugPrint('[PurchaseService] refresh failed: $e');
    }
  }

  void _apply(CustomerInfo info, {bool force = false}) {
    final pro = info.entitlements.active.isNotEmpty;
    if (force || pro != _isPro) {
      _isPro = pro;
      onProChanged?.call(pro);
    }
  }
}
