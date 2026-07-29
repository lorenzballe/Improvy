/// Single source of truth for the details the app shows the outside world.
/// The marketing site publishes the same address — they must not drift apart.
const String kSupportEmail = 'thebalecompany@gmail.com';

/// Prefilled mail draft for the Contact Support row.
const String kSupportMailto =
    'mailto:$kSupportEmail?subject=Improvy%20%E2%80%94%20support';

/// The live marketing site.
const String kWebsiteUrl = 'https://lorenzballe.github.io/Improvyapp/';

/// Public copies of the two legal texts. The store listings need addresses a
/// reviewer can open, and these must keep saying the same thing as the bodies
/// below — change one, change the other.
const String kPrivacyPolicyUrl = '${kWebsiteUrl}#privacy';
const String kTermsUrl = '${kWebsiteUrl}#terms';

/// Apple's numeric ID for the app, from App Store Connect → App Information
/// ("Apple ID", e.g. '6501234567'). Needed to open the store listing on iOS —
/// Android finds itself from the package name.
///
/// **Fill this in once the app is created in App Store Connect.** While it is
/// empty the "Rate Improvy" row simply hides itself on iOS rather than opening
/// a broken page; nothing else depends on it.
const String kAppStoreId = '';
