# Apple review — what to do, and what to paste

Submission ID `ac0c387e-9ed4-459c-863d-c3f7df5054b8`, rejection of 07 Aug 2026.
Two issues. **One of them cannot be fixed in code** — it is an App Store
Connect answer only the Account Holder or an Admin can change.

---

## 1. Guideline 5.1.2(i) — App Tracking Transparency

### What is actually true

The app was read end to end for this. It does not track, by Apple's
definition or any other — no IDFA, no `AppTrackingTransparency`, no ad SDK,
no data broker, no third-party linking, no sign-in, and no `identify()` call
anywhere. Two SDKs send anything at all:

- **PostHog** (EU cloud) — anonymous product analytics: which screens open,
  which modes start, how a session ended. No account is attached. It also
  derives a **coarse location** (roughly city / region / country) from the
  request IP — the app itself asks for **no** location permission and has no
  `NSLocation*` key in `Info.plist`.
- **RevenueCat** — whether the one-off Pro unlock was bought, so it can be
  unlocked and restored.

Neither links data to third-party data for advertising, which is what Apple
means by tracking. The rejection was not "you collect location" — it was a
label that declared data used for **"Developer's Advertising or Marketing"**
without an ATT prompt. Coarse location declared as *Analytics only, not
linked, not tracking* needs no ATT prompt and is allowed.

### Fixed in this commit

- **A privacy manifest was added** (`ios/Runner/PrivacyInfo.xcprivacy`) and
  wired into the Xcode target. It declares `NSPrivacyTracking = false` and
  the four data types below, all unlinked and all non-tracking. The app had no
  manifest at all before, which is why nothing contradicted the wrong label.
- **Audio session fix** for Issue 2 (see below).

PostHog's GeoIP is deliberately left **on** — the coarse location is wanted,
and it is declared honestly everywhere (manifest, store label, site policy).

### You must do this — it is the actual fix

App Store Connect → **App Privacy** → edit. The label currently declares
too many data types; the app collects **four**. Only PostHog (anonymous
analytics + IP-based coarse location) and RevenueCat (purchase state) send
anything — there is no login, no `identify()`, and no crash/performance SDK
in the project.

**Delete these — they are false:**

| Declared now | Why it is wrong |
|---|---|
| Email Address | Never collected. No sign-in, no `identify()`. |
| Payment Info / Financial Info | The app never sees payment details — Apple processes the transaction; RevenueCat only learns *whether* Pro was bought. |
| User ID | There is no user identity — nothing to key it to. |
| Crash Data | No crash-reporting SDK is present. |
| Performance Data / Other Diagnostic Data | Nothing collects these. |
| Other Usage Data | Redundant with Product Interaction. |

**Keep exactly these four.** For each: **"Not linked to the user"** and
**"Not used for tracking"**:

| Keep | Purpose(s) | Source |
|---|---|---|
| Product Interaction | Analytics | PostHog events |
| Purchase History | App Functionality | RevenueCat |
| Device ID | Analytics, App Functionality | anonymous PostHog `distinct_id` / RevenueCat app-user id — declare it: if Apple's scanner sees the id and the label denies it, that is a fresh rejection |
| Coarse Location | **Analytics only** | PostHog IP-based GeoIP — must NOT list any advertising or personalization purpose |

**Then, on every item, remove these purposes** — they are what makes Apple
read the app as tracking:

- **"Developer's Advertising or Marketing"** — nothing uses data for ads.
- **"Product Personalization"** — the app adapts difficulty on-device only; no
  transmitted data drives it.

- The **"Used to Track You" section must end up empty.**

Then reply to the rejection message with:

> Improvy does not track users. There is no sign-in and no `identify()` call,
> no IDFA, no advertising SDK, and no data is shared with a data broker or
> linked to third-party data for advertising — so no ATT prompt is required.
> The app collects anonymous product analytics and purchase state, plus a
> coarse, IP-derived location (roughly city/region) used solely for anonymous
> analytics; the app requests no location permission and has no `NSLocation*`
> key. The App Privacy information has been corrected so that no data type is
> marked as used for tracking or for developer advertising, and this build
> adds a privacy manifest declaring NSPrivacyTracking = false.

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

---

## Ready-to-paste reply to the reviewer

Send this as the reply to the rejection in App Store Connect, once the label
is corrected, the screen recording is attached, and the new build is uploaded.

> Hello, and thank you for the review.
>
> **Guideline 5.1.2(i) — Privacy / Tracking**
>
> Improvy does not track users. There is no login and no account, no
> `identify()` call, no IDFA, and no advertising SDK. No data is shared with a
> data broker or linked to third-party data for advertising, so no App
> Tracking Transparency prompt is required.
>
> The previous privacy label was inaccurate and has now been corrected in App
> Store Connect:
> - **Email Address** was listed by mistake and has been removed — the app
>   never collects an email address. It has no sign-in, and the only email
>   reference in the app is a `mailto:` support link that opens the user's own
>   mail client.
> - **Coarse Location** is not collected via any location permission — the app
>   requests none and has no `NSLocation*` key in Info.plist. A coarse,
>   IP-derived location (city/region) is produced server-side by our analytics
>   provider (PostHog, EU) and is now declared as Analytics only, not linked to
>   the user, and not used for tracking.
> - Nothing is marked as "Used to Track You", and no data type lists a
>   developer-advertising or marketing purpose.
>
> The new build also includes a Privacy Manifest (PrivacyInfo.xcprivacy)
> declaring NSPrivacyTracking = false and these exact data types.
>
> **Guideline 2.5.4 — Background Audio**
>
> The app has a genuine persistent-audio feature called Pocket Mode: a
> hands-free ear-training drill in which a recorded voice asks for a scale
> degree, pauses, then speaks the answer, continuing with the screen locked so
> the user can train with the phone in their pocket. This is the purpose of the
> `audio` background mode. The feature is free and requires no account. A
> screen recording made on a physical device, ending with a navigation to the
> Home Screen while the audio continues, is attached in the App Review
> Information notes.
>
> To reach it:
> 1. Open the app and complete the single welcome screen ("Start training").
> 2. On the Training tab, scroll down to the Pocket Mode card and tap it.
> 3. Leave the defaults and tap START TRAINING.
> 4. A voice begins asking for scale degrees and answering them.
> 5. Lock the screen or go to the Home Screen — the voice keeps playing.
>
> Please ensure the device is not set to silent and the volume is up. We also
> hardened the audio session so the playback category is set at app launch
> rather than on first playback.
>
> Thank you.
