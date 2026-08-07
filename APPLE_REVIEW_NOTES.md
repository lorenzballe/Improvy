# Apple review — what to do, and what to paste

Submission ID `ac0c387e-9ed4-459c-863d-c3f7df5054b8`, rejection of 07 Aug 2026.
Two issues. **One of them cannot be fixed in code** — it is an App Store
Connect answer only the Account Holder or an Admin can change.

---

## 1. Guideline 5.1.2(i) — App Tracking Transparency

### What is actually true

The app was read end to end for this. It does not track, by Apple's
definition or any other:

| Claimed in the privacy label | Reality in the code |
|---|---|
| Email Address | **Never collected.** There is no sign-in, no account, and no `identify()` call anywhere. |
| Coarse Location | **Never requested.** `Info.plist` has no `NSLocation*` key, so iOS could not grant it even if the app asked. |
| Used for tracking | **No.** No IDFA, no `AppTrackingTransparency`, no ad SDK, no data broker, no third-party linking. |

Two SDKs send anything at all:

- **PostHog** (EU cloud) — anonymous product analytics: which screens open,
  which modes start, how a session ended. No account is attached.
- **RevenueCat** — whether the one-off Pro unlock was bought, so it can be
  unlocked and restored.

Neither links data to third-party data for advertising, which is what Apple
means by tracking.

### Fixed in this commit

- **Server-side GeoIP switched off.** PostHog otherwise derives a city and
  region from the request IP. It no longer does — every event carries
  `$geoip_disable`. So "Coarse Location" is now false at the source, not just
  on paper.
- **A privacy manifest was added** (`ios/Runner/PrivacyInfo.xcprivacy`) and
  wired into the Xcode target. It declares `NSPrivacyTracking = false` and
  lists exactly the two data types above, both unlinked and both non-tracking.
  The app had no manifest at all before, which is why nothing contradicted the
  wrong label.

### You must do this — it is the actual fix

App Store Connect → **App Privacy** → edit. The label currently declares 11
data types; the app collects **three**. Everything else is either not
collected at all or an artefact of guessing what the SDKs do. Only PostHog
(anonymous product analytics) and RevenueCat (purchase state) send anything —
there is no login, no `identify()` call, and no crash/performance SDK in the
project at all.

**Delete these — they are false:**

| Declared now | Why it is wrong |
|---|---|
| Email Address | Never collected. No sign-in, no `identify()`. |
| Coarse Location | GeoIP is now disabled per event; not collected. |
| Payment Info / Financial Info | The app never sees payment details — Apple processes the transaction; RevenueCat only learns *whether* Pro was bought. |
| User ID | There is no user identity — nothing to key it to. |
| Crash Data | No crash-reporting SDK is present. |
| Performance Data / Other Diagnostic Data | Nothing collects these. |
| Other Usage Data | Redundant with Product Interaction. |

**Keep exactly these three.** For each: **"Not linked to the user"** and
**"Not used for tracking"**, purposes limited to Analytics / App Functionality:

| Keep | Purpose | Source |
|---|---|---|
| Product Interaction | Analytics | PostHog events |
| Purchase History | App Functionality | RevenueCat |
| Device ID | Analytics, App Functionality | anonymous PostHog `distinct_id` / RevenueCat app-user id — declare it: if Apple's scanner sees the id and the label denies it, that is a fresh rejection |

**Then, on every remaining item, remove these purposes** — they are what makes
Apple read the app as tracking:

- **"Developer's Advertising or Marketing"** — nothing uses data for ads.
- **"Product Personalization"** — the app adapts difficulty on-device only; no
  transmitted data drives it.

- The **"Used to Track You" section must end up empty.**

Then reply to the rejection message with:

> Improvy does not track users. It collects no email address and no location:
> the app requests no location permission and has no `NSLocation*` key in its
> Info.plist, and there is no sign-in of any kind. The only data leaving the
> device is anonymous product analytics (PostHog, EU) and purchase state
> (RevenueCat) — neither is linked to third-party data for advertising and
> neither is shared with a data broker, so no ATT prompt is required. The
> App Privacy information has been corrected accordingly, and this build adds
> a privacy manifest declaring NSPrivacyTracking = false.

---

## 2. Guideline 2.5.4 — background audio

### The feature is real

**Pocket Mode** is a hands-free audio drill. A recorded voice asks for a scale
degree, waits while you work it out, then says the answer, and it keeps going
with the screen locked and the phone in your pocket — which is the entire
point of the mode and why `UIBackgroundModes: audio` is declared. It is
**free**, behind no paywall.

The reviewer almost certainly never reached it: the Pocket Mode card sits
below the fold on the home screen.

### Fixed in this commit

The audio session was only put into the `playback` category when you pressed
Play — *after* the voice player had already been created. Any player made
before that ran on the plugin's default category, and an `ambient` default is
silenced by the ring/silent switch and never plays in the background. On a
review device left on silent, the whole mode would be mute. The session is now
configured in `main()`, before anything creates a player.

**This is worth re-testing on your own iPhone before you resubmit** — it may
well be the real cause of the rejection rather than the reviewer missing the
screen.

### Paste this into App Review Information → Notes

> Improvy's background audio is used by **Pocket Mode**, a hands-free audio
> drill that keeps speaking with the screen locked — that is the purpose of
> the mode. It is free and requires no account.
>
> To reach it:
> 1. Open the app and finish the one welcome screen ("Start training").
> 2. On the Training tab, scroll down to the **Pocket Mode** card and tap it.
> 3. Leave the defaults and tap **START TRAINING** at the bottom.
> 4. A voice begins asking for scale degrees and answering them.
> 5. Press the Home gesture or lock the screen — the voice keeps going.
>
> Please make sure the device is not on silent and the volume is up.
>
> A screen recording of this on a physical device is attached.

### Before you resubmit — you have to record the video

Apple asked for it explicitly and I cannot produce it from here (no iOS
device in this environment). On a real iPhone: start Pocket Mode, swipe to the
Home Screen so the app is backgrounded, keep recording for ~20 seconds while
the voice continues, then attach it in **App Review Information → Notes**.

**If it does not keep speaking in the background on your device**, tell me and
I will remove `audio` from `UIBackgroundModes` instead — but that also means
removing the "Keeps playing with the screen off" promise from Pocket Mode, the
Settings copy and the marketing site, since it would no longer be true.
