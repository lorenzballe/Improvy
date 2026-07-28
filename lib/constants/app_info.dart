/// Single source of truth for the details the app shows the outside world.
/// The marketing site publishes the same address — they must not drift apart.
const String kSupportEmail = 'thebalecompany@gmail.com';

/// Prefilled mail draft for the Contact Support row.
const String kSupportMailto =
    'mailto:$kSupportEmail?subject=Improvy%20%E2%80%94%20support';

/// The live marketing site. This is the only address that actually resolves —
/// the site is a single-page app, so it has no per-page URLs to link deeper to.
const String kWebsiteUrl = 'https://lorenzballe.github.io/Improvyapp/';
