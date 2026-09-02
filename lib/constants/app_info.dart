import 'package:flutter/foundation.dart' show TargetPlatform;

/// Single source of truth for the details the app shows the outside world.
/// The marketing site publishes the same address — they must not drift apart.
const String kSupportEmail = 'thebalecompany@gmail.com';

/// Prefilled mail draft for the Contact Support row.
const String kSupportMailto =
    'mailto:$kSupportEmail?subject=Improvy%20%E2%80%94%20support';

/// The live marketing site.
const String kWebsiteUrl = 'https://lorenzballe.github.io/Improvyapp/';

/// The developer's Instagram.
///
/// Deliberately the plain https address rather than the `instagram://` scheme:
/// Instagram serves this as a universal link, so iOS and Android hand it to the
/// installed app on their own and fall back to the browser when it is missing.
/// The custom scheme would additionally have to be listed in
/// LSApplicationQueriesSchemes just to be *probed*, and buys nothing.
const String kInstagramHandle = 'lorenz_balle';
const String kInstagramUrl = 'https://www.instagram.com/$kInstagramHandle/';

/// Public copies of the two legal texts. The store listings need addresses a
/// reviewer can open, and these must keep saying the same thing as the bodies
/// below — change one, change the other.
const String kPrivacyPolicyUrl = '$kWebsiteUrl#privacy';
const String kTermsUrl = '$kWebsiteUrl#terms';

/// Apple's numeric ID for the app, from App Store Connect → App Information
/// ("Apple ID", e.g. '6501234567'). Needed to open the store listing on iOS —
/// Android finds itself from the package name.
///
/// While this was empty — for two weeks after the app went live — the "Rate
/// Improvy" row hid itself on iOS and every shared Daily Challenge sent the
/// reader to the website instead of the store, which is the one place a
/// share is worth anything.
const String kAppStoreId = '6775236759';

/// Play Console → the listing's own address. Must match `applicationId` in
/// android/app/build.gradle.kts — the id in the URL is what Play resolves, not
/// the namespace the Kotlin lives under.
const String kAndroidPackageId = 'com.improvy.app';
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=$kAndroidPackageId';

/// Public listing on the App Store, once [kAppStoreId] is known.
String get kAppStoreUrl =>
    kAppStoreId.isEmpty ? '' : 'https://apps.apple.com/app/id$kAppStoreId';

/// Where to send someone who wants to *install* Improvy.
///
/// Prefers the reader's own store and falls back to the site, which is the
/// only address that is always right: it outlives a store that has not
/// approved us yet, and it is what a desktop browser can open. [platform] is
/// injected so this stays a pure function — callers pass
/// `defaultTargetPlatform`, tests pass whatever they are proving.
String installUrlFor(TargetPlatform platform, {bool isWeb = false}) {
  if (isWeb) return kWebsiteUrl;
  switch (platform) {
    case TargetPlatform.android:
      return kPlayStoreUrl;
    case TargetPlatform.iOS:
      return kAppStoreUrl.isEmpty ? kWebsiteUrl : kAppStoreUrl;
    default:
      return kWebsiteUrl;
  }
}
