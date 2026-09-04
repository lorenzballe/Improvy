# iOS widgets

Twelve widgets, built with the app. Nothing here needs Xcode any more.

* `ImprovyKit.swift` — the shared data access, design tokens and pieces.
* `ImprovyWidgets.swift` — the twelve widgets and the bundle.
* `Info.plist`, `ImprovyWidget.entitlements` — the extension's own.
* `../add_widget_target.rb` — the script that put the target in the project.

The extension target `ImprovyWidget` (`com.improvy.app.ImprovyWidget`) is in
`Runner.xcodeproj` and is embedded in Runner, so `flutter build ipa` builds and
ships it. `test/native_widgets_test.dart` fails the build if any of that is
removed, or if a widget exists on one platform and not the other.

## The one thing that is not in this repo

Entitlements are only half of an App Group. The other half lives in your Apple
developer account, and a provisioning profile that does not carry the group
makes the widgets install and then show placeholders forever.

**Do this once**, at <https://developer.apple.com/account/resources>:

1. **Identifiers → App Groups → +** — create `group.com.improvy.app.widget`
   (if it is not there already).
2. **Identifiers → App IDs → `com.improvy.app`** → tick **App Groups** →
   *Configure* → select that group → Save.
3. The same for **`com.improvy.app.ImprovyWidget`**. That App ID is created by
   the first Codemagic build that runs after this change (`fetch-signing-files
   --create`), so if it is not listed yet, run the build once, let it create the
   ID, then come back and tick the box.

Codemagic fetches a profile for both bundle IDs (`codemagic.yaml`, the signing
step). Existing profiles are re-created there each run, so the group is picked
up on the next build after step 2 — no manual profile juggling.

## Checking it works

* Open the app once first. The widgets are empty until the app has written its
  first payload (`WidgetService.sync`, which runs at launch and on resume).
* Long-press the home screen → **+** → search **Improvy**. All twelve appear.
* Tapping must land somewhere sensible: the question opens its reveal card, the
  daily opens today's challenge, the weakest key opens that key.
* A widget stuck on placeholder text is the App Group, nine times out of ten.

## Adding a widget

1. Write it in `ImprovyWidgets.swift` and add it to `ImprovyWidgetBundle`.
2. Add the `(Android provider, iOS kind)` pair to `WidgetService._widgets`.
3. Write the Android side — provider, layout, manifest receiver, info XML.

`test/native_widgets_test.dart` checks all of that and says which step is
missing.
