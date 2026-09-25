# Improvy — release readiness

**Version**: 1.17.0 (build 105) · `com.improvy.app` · iOS 15+ (widgets 16+), Android 7+ (API 24)
**Last full check**: 19 September 2026, on this branch. Everything below was
actually run, not ticked.

## What was verified

| Check | Command | Result |
|---|---|---|
| Static analysis, warnings fatal (Codemagic's gate) | `flutter analyze --no-fatal-infos` | **No issues found** |
| Flutter test suite (what CI and Codemagic run) | `flutter test` | **381 passed**, 0 failed, 7 skipped by design (golden + `ios` tags) |
| iOS purpose-string scan of every locked package | `flutter test --tags ios --run-skipped` | passed |
| Localizations in sync with the ARB files | `flutter gen-l10n` → no diff | 6 languages, 496 keys each, no gaps |
| iOS project in step with Firebase | `dart run tool/sync_firebase_ios.dart --check` | in step |
| Cloud Functions (Stripe checkout, webhooks) | `cd functions && npm ci && npm test` | 32 passed |
| Firestore rules against the emulator | `cd tool/firestore_rules && npm test` | 16 passed |
| Web release build (the GitHub Pages preview) | `flutter build web --release --base-href /Improvy/` | built |
| Android release build | — | **not run here**: the sandbox cannot reach dl.google.com (Android SDK and Google's Maven repository). Build it on a machine with the SDK: `flutter build appbundle --release` with `android/key.properties` in place. |
| iOS archive | — | Codemagic (`codemagic.yaml`), which runs analyze, the tests and the privacy check first. |

Toolchain used: Flutter 3.47.5 stable / Dart 3.13.4, Node 22, Java 21 — the
same channel Codemagic and the workflows pin.

## What changed in this pass

Full detail is in the commit messages on this branch. In short:

* **Progression**: Note to Number ran thirty questions at every tier, so its
  Master tier could never open. It now runs 30/40/50 by tier like the other
  modes.
* **Daily Challenge**: a force-quit mid-run was a free retry (the recovery
  looked for a direction the daily never runs); results verdicts were still
  scaled for ten questions; …Of What? days credited a stale tier and row.
* **Home**: Resume paywalled free games outside C; an …Of What? session was
  labelled "Of-what"; widget taps could strand the app on a tab with no nav.
* **Widgets**: the weakest-key widget opened a non-existent key on Do-Re-Mi
  phones; the level widget and the theory card were English on every phone;
  iOS cached its labels for the life of the extension; Android's tall
  widgets were indistinguishable in the picker; the Android 12+ splash
  colour was lost in dark mode.
* **Accounts and purchases**: deleting an account with a stale sign-in lost
  the promo code without deleting the account; two concurrent restores.
* **iPad**: the Share button always fell back to "copied".
* **Compliance**: `ios/Runner/PrivacyInfo.xcprivacy` now declares the
  account data collected since 1.17.0 (Email Address, User ID, linked);
  the store copy no longer says "No account".
* **Android R8**: code shrinking and resource shrinking are on again, with
  the keep rule for the WorkManager/Room launch crash that had them turned
  off, R8 in compatibility mode, and the widgets' resources pinned
  (`android/app/proguard-rules.pro`, `gradle.properties`,
  `res/raw/keep.xml`). **This can only be proven on a device**, see below.
* **Hygiene**: analyzer silent, 15 MB of committed golden-failure diffs
  removed, README written, web shell named, dead workflow trigger removed,
  Android builds without the keystore on hand.

## Before you press Submit — things only you can do

1. **App Store Connect → App Privacy**: update the label to the table at the
   top of `APPLE_REVIEW_NOTES.md` (Email Address and User ID are collected
   now, linked to the user, not used for tracking). The old "no sign-in"
   reply text must not be reused.
2. **Play Console → Data safety**: the same additions (`FIREBASE_SETUP.md`,
   section 7). Both stores also require in-app account deletion — it exists,
   in the Account card in Settings.
3. **Pro price**: the paywall's fallback `€19,99`
   (`lib/widgets/paywall_modal.dart`) is shown only until RevenueCat answers,
   so it must match the price set in App Store Connect and Play Console. The
   website's 18,99 € (`functions/lib/catalog.js`) is deliberately lower (no
   store commission) and must never be mentioned inside the app.
4. **Firebase** (`FIREBASE_SETUP.md`): Play's SHA-1 in the Firebase project
   (Google sign-in on Android does not start without it), Firestore rules
   published, "Sign in with Apple" ticked on the App ID and its stale
   profile deleted.
5. **Website purchase** (`STRIPE_SETUP.md`): Stripe account and webhook,
   Blaze plan, the deploy key and the three GitHub secrets, the authorised
   domain — none of it is code.
6. **Build number**: pubspec is at `+105`. Codemagic numbers the iOS build
   itself (latest TestFlight + 1); Android takes `+105` from pubspec, so
   bump it again for every upload after this one. If you want a What's New
   sheet for these fixes, bump to 1.17.1 and add the entry in
   `lib/constants/release_notes.dart` — the version test keeps them in step.
7. **Android release build on a real phone, before the first upload with
   R8 on**: `flutter build apk --release`, install it, and check that the
   app opens at all (the old crash was at launch), that a reminder can be
   scheduled and the test notification shows, that the widgets fill, that
   Google sign-in and Restore Purchases work. If Gradle stops with
   "Missing class …" it prints the rule to add to `proguard-rules.pro`. To
   retreat, set `isMinifyEnabled` and `isShrinkResources` to false in
   `android/app/build.gradle.kts`. The AAB carries the R8 mapping file, so
   Play's crash reports stay readable.
8. **On a real iPhone, once**: Pocket Mode keeps speaking with the screen
   locked (the reviewer's video), the widgets fill after the first launch,
   Sign in with Apple and Google round-trip, and Restore Purchases does not
   pop an App Store password prompt on sign-out (RevenueCat calls
   `restorePurchases` there; StoreKit 2 may ask for the Apple ID).
9. **Screenshots** for both stores (`STORE_ASSETS.md`), and the ASCII-safe
   App Store text in `STORE_DESCRIPTION.md`.

## Not blocking, worth knowing

* 148 developer screenshots (`_*.png`, 55 MB) sit in the repository root.
  They are not shipped and nothing references them; deleting them is a
  judgement call, not a fix.
* `COMPLETION_PLAN.md` describes the v1.0 launch plan and is historical.
