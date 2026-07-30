# 🎵 Improvy Store Assets - iOS App Store & Google Play

> ✅ **This copy matches the shipped app.** Every claim below is checked against
> the code: 6 modes (`lib/models/training_mode.dart`), 8 animal levels
> Snail → Cheetah (`lib/constants/levels.dart`), spoken TTS prompts
> (`lib/services/tts_service.dart`), no accounts / anonymous analytics
> (`lib/services/analytics_service.dart`), lifetime one-time Pro at €19,99
> (`lib/widgets/paywall_modal.dart`). If the app changes, change this file.

## App Store Metadata

### App Name
**Current**: Improvy  
**Length**: 7 characters (max 30)  
✓ Ready

### Subtitle (iOS only)
**Current**: Know Every Key by Heart  
**Length**: 23 characters (max 30)  
✓ Ready

### Promotional Text (iOS only, 170 chars, editable without review)
```
New: the Daily Challenge — one key, 10 questions, 40 seconds, one attempt, the same for everyone in the world. Keep your streak and share your grid.
```

### Short Description (Google Play, 80 chars)
```
Instant scale-degree recall in all 12 keys. Think faster, improvise freer.
```
**Length**: 74 characters ✓

---

## App Description (Same for Both Stores)

### Full Description (for store listing)

```
🎵 IMPROVY — Know Every Key by Heart

Great improvisers don't calculate — they know. Improvy trains instant recall of scale degrees in all 12 major keys: what the ♭3 of E♭ is, which degree B is in the key of G, and where every note lives — without stopping to think.

That mental map is the foundation under improvisation, transposition, sight-reading and composition. Improvy builds it the way athletes build reflexes: short daily reps, measured speed, rising difficulty.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

HOW IT WORKS

1. Improvy asks: "the flat three of C"
2. You answer on the note pad: E♭
3. Instant feedback — right or wrong, and how fast
4. Weak keys and degrees come back more often, until they're automatic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SIX TRAINING MODES

✓ DIATONIC — the seven scale degrees of any major key. The foundation.

✓ CHROMATIC — all twelve degrees across every key, asked by every name they go by: ♭2 or ♭9, ♯4 or ♯11, ♭6 or ♭13 — the names real charts print.

✓ NOTE TO NUMBER — the reverse direction: see the note, name the degree.

✓ …OF WHAT? — "E is the third of what key?" Reverse-engineer the key itself.

✓ CUSTOM — pick exactly the keys and degrees you want to drill.

✓ POCKET MODE — hands-free audio training. A voice asks, pauses, then speaks the answer. Keeps running with the screen locked: train while walking, commuting, warming up.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BUILT TO KEEP YOU TRAINING

✓ DAILY CHALLENGE — one key, 10 questions, 40 seconds, one attempt: the same challenge for the whole world, every day. Keep the streak, share the grid.
✓ HOME SCREEN WIDGETS — a scale degree waiting for an answer, a new one every hour, plus your daily challenge and streak at a glance
✓ 8 ANIMAL LEVELS — climb from 🐌 Snail to 🐆 Cheetah as your mastery grows
✓ ADAPTIVE DIFFICULTY — the challenge tightens as you get faster
✓ DEEP ANALYTICS — accuracy, response time and streaks for every key
✓ DAILY STREAKS & REMINDERS — a few minutes a day is the whole method
✓ YOUR NOTATION — C-D-E or Do-Re-Mi
✓ WORKS OFFLINE — no connection needed to train

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPROVY PRO

Free to download and start training. One single purchase unlocks everything forever — Chromatic, Note to Number, Custom, …Of What? extensions, Adaptive Difficulty and Deep Analytics. No subscription. No recurring fees. No ads.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRIVACY FIRST

No account. No sign-up. No personal data collected — only anonymous usage statistics to improve the app.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For every musician tired of counting on their fingers: guitarists, pianists, horn players, singers, songwriters, students of jazz and theory.

Stop calculating. Start knowing.

IMPROVY — Every key. Every degree. Instant.

---

Support: thebalecompany@gmail.com
Privacy: lorenzballe.github.io/Improvyapp/#privacy
Terms: lorenzballe.github.io/Improvyapp/#terms
```

**Character Count**: ~2,400 / 4,000 (both stores)  
✓ Fits both platforms

---

## Keywords/Tags

> Honest by design: no "ear training" / "perfect pitch" terms — the app doesn't
> train the ear, and irrelevant keywords violate App Store Review 2.3.7.

### For iOS (100 characters max)
```
music theory,scale degrees,improvisation,jazz,transposition,solfege,piano,guitar,nashville numbers
```
**Count**: 98 characters (no spaces after commas — they waste the budget)  
✓ Ready

### For Android (keyword themes — Play indexes the listing text, not a keyword field)
```
music theory trainer, scale degrees, all 12 keys, improvisation practice,
transposition, jazz theory, nashville number system, solfege, do re mi,
circle of fifths, music practice, music education, songwriting,
key signatures, music student, guitar theory, piano theory
```
✓ Woven into the description above

---

## Support & Legal Links

| Link | Value | Status |
|------|-------|--------|
| Support Email | thebalecompany@gmail.com | ✓ Live |
| Website | https://lorenzballe.github.io/Improvyapp/ | ✓ Live |
| Privacy Policy | https://lorenzballe.github.io/Improvyapp/#privacy | ✓ Live |
| Terms of Service | https://lorenzballe.github.io/Improvyapp/#terms | ✓ Live |

> These are the URLs to paste into App Store Connect and Play Console. They are
> served by the marketing site and show the same text the app ships in Settings.
> Two copies exist — `kPrivacyPolicyBody` / `kTermsBody` in
> `lib/screens/legal_screen.dart`, and `PrivacyPolicyPage.tsx` /
> `TermsOfServicePage.tsx` in the site repo. Change one, change the other, and
> bump the "Last updated" date in both.

---

## Pricing

| Item | Value |
|------|-------|
| Download | Free |
| Improvy Pro (`improvy_pro_lifetime`) | **€19,99** one-time, non-consumable |

> Set the price in App Store Connect (tier for €19,99) **and** Play Console.
> The app reads the live localized price via RevenueCat; the hard-coded
> `€19,99` in `paywall_modal.dart` is only the fallback while the store loads.

---

## Screenshots (Required)

### iOS App Store
**Required**: 5-8 screenshots  
**Dimensions**: 1170 × 2532 px (or 1080 × 1920 px for older format)  
**Format**: PNG or JPEG  
**Localization**: English at minimum

### Android Play Store
**Required**: 4-8 screenshots  
**Dimensions**: 1080 × 1920 px minimum  
**Format**: PNG or JPEG  
**Localization**: English at minimum

---

### Screenshot Sequence (Same Order for Both)

#### Screenshot 1: HOME — "Your practice, at a glance"
```
Focus: streak, animal level, progress ring
Text Overlay:
  "IMPROVY"
  "Know every key by heart"
  (Show: current animal level, day streak counter, progress)
```

#### Screenshot 2: TRAINER — "A few minutes a day"
```
Focus: a live question mid-session
Text Overlay:
  "♭3 of C?"
  "Answer before it becomes thinking"
  (Show: question, note pad, question counter)
```

#### Screenshot 3: STATS — "Watch yourself get faster"
```
Focus: analytics dashboard
Text Overlay:
  "Accuracy, speed, streaks"
  "For every key"
  (Show: accuracy chart, response time, per-key analytics)
```

#### Screenshot 4: MODES — "Six ways to drill it in"
```
Focus: mode selection
Text Overlay:
  "Diatonic • Chromatic • Custom"
  "Note to Number • …Of What? • Pocket"
  (Show: the mode cards)
```

#### Screenshot 5: POCKET MODE — "Train with the screen off"
```
Focus: hands-free audio session
Text Overlay:
  "A voice asks. You answer. It confirms."
  "Walk, commute, warm up"
  (Show: pocket mode running)
```

#### Screenshot 6: DAILY CHALLENGE — "Everyone plays the same one"
```
Focus: the daily results screen (score, grid, streak calendar)
Text Overlay:
  "One key. 10 questions. 40 seconds."
  "Keep the streak. Share the grid."
  (Show: result screen with a strong score and a lit calendar)
```

#### Screenshot 7: LEVELS — "Climb from Snail to Cheetah"
```
Focus: the 8-animal progression
Text Overlay:
  "🐌 → 🐢 → 🐧 → 🐰 → 🦊 → 🐴 → 🦅 → 🐆"
  "8 levels of mastery"
  (Show: level-up moment or level list)
```

#### Screenshot 8 (Optional): PRO — "One purchase. Forever."
```
Focus: the paywall
Text Overlay:
  "No subscription"
  "€19,99 once, yours for life"
  (Show: the Pro membership card)
```

---

## How to Create Screenshots

### Option 1: Automated (Recommended)
```bash
# Flutter integration_test with screenshot capture
flutter drive --target=test_driver/app.dart --driver=test_driver/app_test.dart
```

### Option 2: Manual (Fastest)
1. Run app on iOS simulator or Android emulator
2. Navigate to each screen in sequence
3. Take screenshot (Cmd+S on iOS, Ctrl+S on Android)
4. Crop to required dimensions in Preview/Photoshop
5. Add text overlay in Figma/Canva (optional but recommended)

> The repo already has screenshot entrypoints: `lib/main_screenshot.dart`,
> `main_pocket_screenshot.dart`, `main_ofwhat_screenshot.dart`,
> `main_notif_screenshot.dart`.

---

## Category Selection

### iOS App Store
- **Primary**: Music
- **Secondary**: Education

### Google Play
- **Category**: Education (better discovery for trainers than Music & Audio,
  which is dominated by players/streaming)
- **Tags**: Music, Music theory
- **Content Rating**: Everyone / PEGI 3

---

## Additional Metadata

### Age Rating (Both Stores)

**IARC (International Age Rating Coalition)** questionnaire:

- Does your app collect personal information? → NO
- Does your app contain ads? → NO
- Does your app allow social interaction? → NO
- Does your app have social networking? → NO
- Does your app contain user-generated content? → NO
- Does your app contain music? → NO (prompts are a spoken text-to-speech
  voice; there are no songs or instrumental recordings)
- Digital purchases? → YES (in-app purchase)

**Rating Result**: 4+ (iOS) / 3+ (Android)

---

### Data Safety (Google Play Only)

**Data Safety Form**:

```
App Data
├─ Personal Information
│  └─ No personal data collected
│
├─ Sensitive Information
│  └─ None
│
├─ Sensitive Permissions
│  └─ None required (audio is standard)
│
├─ Data Retention
│  ├─ Analytics: 12 months then deleted
│  ├─ App Data: On device, deleted on uninstall
│  └─ IAP: RevenueCat managed (see their privacy policy)
│
└─ Third-Party Sharing
   └─ RevenueCat (for IAP verification)
   └─ PostHog (for anonymous analytics)
```

---

### Privacy Manifest (iOS 17+)

**Location**: `ios/Runner/PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypeProductInteraction</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <false/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

---

## Checklist for Store Submission

### Pre-Upload Checklist

- [ ] Pro price set to €19,99 in App Store Connect AND Play Console
- [ ] `kAppStoreId` in `lib/constants/app_info.dart` filled with the Apple ID
      from App Store Connect → App Information (the "Rate Improvy" row in
      Settings stays hidden on iOS until it is)
- [ ] iOS widget extension target added in Xcode — see
      `ios/ImprovyWidget/SETUP.md` (Android widgets need nothing; they build
      with the app)
- [ ] All screenshots are correct dimensions
- [ ] All screenshots have proper overlays/text
- [ ] Description pasted (this file), keywords pasted
- [ ] Privacy Policy link is accessible
- [ ] Terms of Service link is accessible
- [ ] Support email is monitored
- [ ] App icon (1024x1024) is uploaded
- [ ] Version number bumped (1.1.0)
- [ ] Build is signed with production certificates

### iOS Specific

- [ ] Privacy Manifest included in Xcode project
- [ ] Build uploaded to TestFlight
- [ ] Internal testing completed (no crashes)
- [ ] RevenueCat sandbox tested
- [ ] All links in Privacy/Terms are reachable

### Android Specific

- [ ] AAB (App Bundle) built with release config
- [ ] Signed with correct keystore
- [ ] Internal testing in Play Console complete
- [ ] RevenueCat with license key configured
- [ ] Data Safety form submitted

---

## Text Assets Summary

| Asset | iOS | Android | Status |
|-------|-----|---------|--------|
| App Name | 30 chars | 50 chars | ✓ Ready |
| Subtitle | 23/30 chars | N/A | ✓ Ready |
| Short Desc | N/A | 74/80 chars | ✓ Ready |
| Full Desc | ~2,400/4,000 | ~2,400/4,000 | ✓ Ready |
| Keywords | 98/100 chars | in description | ✓ Ready |
| Screenshots | 5-8 × 1170×2532px | 4-8 × 1080×1920px | ⏳ Create |
| Support URL | Required | Required | ✓ Ready |
| Privacy URL | Required | Required | ✓ Ready |
| Terms URL | Required | Required | ✓ Ready |

---

## Next Steps

1. Create screenshots (manual or automated)
2. Set the €19,99 price on both stores
3. Upload to App Store Connect (iOS)
4. Upload to Play Console (Android)
5. Fill out compliance forms (privacy manifest, data safety)
6. Submit for review

**Timeline**: 2-3 hours for screenshot creation + form filling
**Review Time**: 1-2 weeks per store

---

**Last Updated**: July 29, 2026
**Status**: Copy ready — screenshots pending
