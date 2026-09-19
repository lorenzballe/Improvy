# Improvy

Know every scale degree in every key. A Flutter app for iOS and Android that
drills instant recall of scale degrees — the ♭3 of E♭, which degree B is in G —
across all 12 major keys, with a Daily Challenge, home-screen widgets, a
hands-free Pocket Mode and a one-time Pro unlock.

Bundle / package id: `com.improvy.app`. Version lives in `pubspec.yaml`
(`version: x.y.z+build`) and must match the newest entry of
`lib/constants/release_notes.dart` (`test/release_version_test.dart` checks).

## Layout

| Path | What |
|---|---|
| `lib/` | the app — `screens/`, `widgets/`, `providers/app_provider.dart` (state), `services/` (purchases, accounts, analytics, notifications, voice, widgets), `models/`, `utils/music_engine.dart` |
| `lib/l10n/` | translations (`app_*.arb`, six languages) and the generated `AppLocalizations` |
| `assets/audio/voice/` | the recorded voice clips Pocket Mode speaks (see `VOICE_RECORDING.md`) |
| `android/`, `ios/` | native projects, including the twelve home-screen widgets on each side |
| `functions/` | Cloud Functions: Stripe checkout for the website and the webhooks that write Pro licences (see `STRIPE_SETUP.md`) |
| `firestore.rules` | the promo-code and licence rules — the only server-side logic the app relies on directly |
| `tool/` | maintenance scripts (Firestore rules tests, iOS ↔ Firebase sync, voice-clip tooling) |
| `test/` | the Flutter test suite |

## Working on it

```bash
flutter pub get
flutter analyze --no-fatal-infos   # warnings are fatal, infos are not
flutter test                       # what CI runs
flutter test --tags ios --run-skipped   # iOS purpose-string check, before a build
dart run tool/sync_firebase_ios.dart --check
```

Server side:

```bash
cd functions && npm ci && npm test
cd tool/firestore_rules && npm ci && npm test   # needs Java 11+ for the emulator
```

## Shipping

* **iOS** is built and sent to TestFlight by Codemagic (`codemagic.yaml`); it
  runs analyze, the tests and the iOS privacy check first.
* **Android**: `flutter build appbundle --release` with `android/key.properties`
  pointing at the upload keystore (never committed).
* **Firebase** (functions, rules, hosting) deploys from GitHub Actions on every
  push to `main` that touches them (`.github/workflows/firebase.yml`).
* **Web preview** of the UI is published to GitHub Pages from `main`
  (`.github/workflows/web-preview.yml`); it is a preview, not a product.

Store copy: `STORE_DESCRIPTION.md` (App Store, ASCII-safe) and
`STORE_ASSETS.md`. Review history and privacy-label answers:
`APPLE_REVIEW_NOTES.md`. Account and licence setup: `FIREBASE_SETUP.md`,
`STRIPE_SETUP.md`. Release readiness record: `DEPLOYMENT_READY.md`.
