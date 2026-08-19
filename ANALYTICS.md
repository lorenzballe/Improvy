# Analytics — what Improvy measures, and why

Every event the app sends is declared in `Ev` (`lib/services/analytics_service.dart`)
and nowhere else, so a typo is a compile error rather than a second event that
looks like the first one in the dashboard. `test/analytics_test.dart` fails if
that ever stops being true.

---

## The three configuration facts that mattered more than any event

**Person profiles were off.** The SDK defaults to `identifiedOnly`, and an app
with no login never identifies anyone — so PostHog was discarding every person
profile. No retention curve, no cohorts, and any person property set would have
gone straight in the bin. Now `always`: an anonymous device is still a person
worth counting.

**Lifecycle events were off.** `Application Installed`, `Updated`, `Opened` and
`Backgrounded` now arrive for free, and they are both more than the single
manual `app_open` said and more reliable about when it happened. That manual
event is gone; use `Application Opened`.

**Crashes were not reported.** Flutter and platform errors are now captured as
`$exception`. A one-person app has no other way to learn that a device is
failing.

---

## The five questions this is built to answer

### 1. Does a new arrival ever become a user?

```
Application Installed → onboarding_completed → session_started → first_session_completed
```

`first_session_completed` fires once, ever. It is the activation line: everyone
before it is a download, everyone after it is a user. If installs are healthy
and this is not, the problem is the first five minutes, not the marketing.

### 2. Do they come back?

Person properties carry `streak`, `daily_streak`, `total_sessions`,
`dailies_played`. Retention is PostHog's built-in report over
`Application Opened`; `streak_milestone` (3, 7, 14, 30, 60, 100, 365) marks the
moments worth a notification or a share prompt.

### 3. What do they actually play — and does it work?

`session_finished` used to carry nothing at all. It now carries mode, key,
difficulty, correct, total, accuracy, seconds, whether it was the daily,
whether adaptive difficulty was on, and which session number it was. That one
event answers which modes get used, which keys are hard, whether accuracy
improves with session number, and whether adaptive difficulty helps or hurts.

`pocket_session_started` carries the full configuration — delay, degree count,
shuffle, endless or fixed — so the defaults can be set from what people choose
rather than from taste.

### 4. What do free users want that they cannot have?

`locked_feature_tapped` is the single most useful event here: it is the only one
that says what people **want** rather than what they settle for. Every locked
door names itself — `note_to_number`, `custom_mode`, `chromatic_key`,
`adaptive_difficulty`, `pocket_all_degrees` — and the paywall inherits that name
as its `source`, which is then carried through `pro_purchase_start` and
`pro_purchase_success`.

```
locked_feature_tapped → paywall_shown → pro_purchase_start → pro_purchase_success
                                     ↘ paywall_dismissed (with seconds_visible)
```

A conversion rate with no source cannot tell you which door sells. This one can.

### 5. Is it broken on someone else's phone?

`startup_step_failed`, `audio_session_failed`, `question_unspeakable`,
`$exception`. A device where storage, the store or audio quietly fails looks
exactly like a device where the user simply stopped playing. These are the only
way to tell those two apart.

---

## Person properties

Pushed by `AppProvider.syncAnalyticsProfile()` after anything that changes the
answer — session end, purchase, settings change, launch. Never on a timer.

| Property | Why it is worth having |
|---|---|
| `is_pro`, `level`, `animal` | segment anything by paid and by progress |
| `total_progress`, `accuracy` | is this person actually getting better |
| `streak`, `daily_streak` | habit, the thing the app lives on |
| `total_sessions`, `total_attempts`, `dailies_played` | depth of use |
| `keys_played`, `keys_mastered` | breadth — do they leave C |
| `notation`, `simple_notes`, `adaptive_difficulty`, `keyboard_from_tonic`, `notif_daily_on` | do the people who turn X on stay longer |
| `first_seen`, `first_version` *(set once)* | stable cohorts that never move |

`is_pro` and `level` are **also** super properties, so they ride on every single
event and any chart can be split by them without a join.

---

## What you have to do in PostHog — the app cannot do these

1. **Project settings → check the EU host.** The key in the app points at
   `eu.i.posthog.com`. If the project is on US cloud, nothing arrives.
2. **Person profiles.** Nothing to switch — the app now asks for `always`. Just
   confirm people appear under *People* after a day.
3. **Autocapture: leave it off for mobile.** It does not apply, and screen
   views now arrive as proper `$screen` events.
4. **Build these four insights.** They are the whole dashboard:
   - *Activation funnel*: `Application Installed` → `onboarding_completed` →
     `first_session_completed`, over 7 days.
   - *Money funnel*: `locked_feature_tapped` → `paywall_shown` →
     `pro_purchase_success`, **broken down by `source`**.
   - *Retention*: on `Application Opened`, weekly.
   - *Health*: a table of `$exception`, `startup_step_failed`,
     `audio_session_failed` by `$app_version`.
5. **One cohort worth saving**: `total_sessions >= 10 AND is_pro = false`.
   These are the people who love it and have not paid — the most valuable list
   in the account.
6. **Do not turn on session replay.** It is off deliberately: it would record
   the screen, and the privacy label says the app collects nothing of the kind.

---

## What arrives without a single line of code

Worth knowing before adding anything: PostHog's mobile SDK attaches a static
context to **every** event, and the server derives more from the request IP.
Nothing here needs a permission and nothing here was written by us.

| | |
|---|---|
| App | `$app_version`, `$app_build`, `$app_name`, `$app_namespace` |
| Device | `$device_manufacturer`, `$device_model`, `$device_type`, `$screen_width`, `$screen_height` |
| OS | `$os_name`, `$os_version` |
| Setting | `$locale`, `$timezone`, network type |
| Where | `$geoip_country_name`, `$geoip_subdivision_1_name` (region), `$geoip_city_name`, `$geoip_time_zone`, and an approximate `$geoip_latitude` / `$geoip_longitude` |

That last row **is** approximate location, and it is already on. Confirm it in
30 seconds: *Activity → Live events →* open any event and read the property
list. The exact names may differ slightly by SDK version; the list on screen is
the authority, not this table.

## Location: what we do not ask for, and why

The app requests **no location permission** and should not start.

GeoIP already answers every question worth asking — which countries to
translate for, which timezones to schedule reminders in, where growth is coming
from — at city resolution, with no prompt and no permission to decline.

Asking for real GPS would mean a permission dialog most people refuse, a purpose
string in Info.plist, a *Precise Location* row on the App Store label, and a
genuine review risk: Apple's 5.1.1 requires data collection to be tied to a
feature the user can see, and a scale trainer has no such feature. Two
rejections have already cost this app weeks. It would buy nothing that the row
above does not already give.

**Session replay** is the other thing deliberately left off. It records the
screen. For a tap-a-note app the insight is small next to the cost: a privacy
label change, a policy change, and a lot of video of people tapping notes. It is
one line in `init()` the day that trade looks worth it.

## Feature flags — the thing that was actually missing

`AnalyticsService.flag('name')` and `.variant('name')`. Already in the SDK,
nothing to install.

This is the one professional habit the app had no way to practise: changing the
paywall wording, the daily's difficulty or the onboarding order for half the
users and reading which half converts — without shipping a build and waiting a
week for review. A flag that fails to load falls back to whatever ships today,
so it can never break the app.

## Privacy

Unchanged, and the events above keep it that way: no name, no email, no
identifier tied to a person, no free text a user typed. PostHog's server-side
GeoIP stays on and is declared as *Coarse Location — analytics only, not linked
to identity, not used for tracking* in the privacy manifest, the App Store
Connect label and the site policy. The app requests no location permission and
has no other source of location.
