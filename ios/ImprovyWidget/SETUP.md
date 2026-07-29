# iOS widgets — the one part that needs Xcode

Android is done: the widgets there are plain files in the repo and build with
the app. iOS is not, and can't be — a WidgetKit extension is a **separate build
target**, and targets live inside `Runner.xcodeproj/project.pbxproj`, a file
that must be edited by Xcode itself. Hand-writing it corrupts the project.

Everything else is already written. What follows takes about ten minutes and is
done once.

## 1. Add the widget extension target

1. Open `ios/Runner.xcworkspace` (the **workspace**, not the project).
2. **File → New → Target… → Widget Extension**.
3. Product Name: **`ImprovyWidget`** (exactly — the folder here matches it).
   * Uncheck *Include Configuration Intent*.
   * Uncheck *Include Live Activity*.
   * Team: your own. Embed in Application: **Runner**.
4. When Xcode offers to activate the new scheme, say **Activate**.

Xcode creates its own `ImprovyWidget` folder with a template Swift file.

## 2. Swap in the real sources

1. In Finder, delete the files Xcode just generated inside its `ImprovyWidget`
   group (`ImprovyWidget.swift`, and `ImprovyWidgetBundle.swift` if present) —
   but keep the group itself.
2. Drag `ios/ImprovyWidget/ImprovyWidget.swift` (this folder) into that group,
   with **Copy items if needed** off and target membership = `ImprovyWidget`.
3. Do the same for `Info.plist` and `ImprovyWidget.entitlements`, replacing the
   generated ones, then check the target's Build Settings point at them:
   * `INFOPLIST_FILE` → `ImprovyWidget/Info.plist`
   * `CODE_SIGN_ENTITLEMENTS` → `ImprovyWidget/ImprovyWidget.entitlements`

## 3. Turn on the App Group — on **both** targets

The app writes the widget payload into a shared container and the widget reads
it. Without this the widgets build fine and show nothing.

For **Runner** and then for **ImprovyWidget**:

*Signing & Capabilities → + Capability → App Groups → +* and add:

```
group.com.improvy.app.widget
```

For Runner, also set *Build Settings → Code Signing Entitlements* to
`Runner/Runner.entitlements` (the file is already in the repo with the group in
it) if Xcode created a different one — or just let Xcode add the capability and
keep its file, as long as the group string matches.

> The group ID appears in exactly three places and they must agree:
> `WidgetService.iOSAppGroupId` (Dart), `Improvy.appGroupId` (Swift), and the
> App Groups capability on both targets.

## 4. Deployment target

Set the `ImprovyWidget` target's **Minimum Deployments** to **iOS 16.0** or
higher (WidgetKit needs 14+, and the code uses `containerBackground` behind an
`#available(iOS 17)` check).

## 5. Build and add a widget

```bash
flutter build ios       # or just run from Xcode
```

On the device: long-press the home screen → **+** → search **Improvy** → two
widgets appear, *Question* and *Daily Challenge*, each in small and medium.

## Checking it works

* Open the app once first — the widgets are empty until the app has written
  its first payload (`WidgetService.sync`, which runs at launch and on resume).
* Tapping the Question widget must open the app on the reveal card; tapping the
  Daily widget must land on the Daily Challenge.
* If a widget stays on placeholder text, the App Group is the cause 95% of the
  time: confirm the identical string on both targets.

## Optional: the app's own typeface

The widgets use the system rounded face, which sits close to Lexend. To use the
real thing, drag `assets/fonts/Lexend-Black.ttf` and `Lexend-SemiBold.ttf` into
the `ImprovyWidget` target, add them to the extension's `Info.plist` under
`UIAppFonts`, and replace `.system(size:weight:design:)` with
`.custom("Lexend", size:)` in `ImprovyWidget.swift`.
