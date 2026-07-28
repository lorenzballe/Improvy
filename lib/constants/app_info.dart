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
