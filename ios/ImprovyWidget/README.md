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
4. **Profiles → delete the widget's profile** (it is named something like
   `com improvy app ImprovyWidget ios_app_store 1788614442`). A profile minted
   before the capability existed does not gain it: Apple marks it invalid and
   it has to be replaced. `fetch-signing-files --create` mints a fresh one on
   the next build only when there is none to find.

Then run the build again.

## The error this produces when step 3 or 4 is skipped

```
Provisioning profile "com improvy app ImprovyWidget ios_app_store …"
  doesn't include the App Groups capability.
  doesn't support the group.com.improvy.app.widget App Group.
  doesn't include the com.apple.security.application-groups entitlement.
```

It comes after `Xcode archive done`, which is worth reading properly: the
extension compiled and archived. Only the signature is missing the capability,
and that lives in the Apple developer account, not in this repo.

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
