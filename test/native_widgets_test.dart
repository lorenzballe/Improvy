import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The home-screen widgets live in three places that cannot see each other:
/// the payload and refresh list in Dart, twelve SwiftUI widgets on iOS, and
/// twelve providers plus manifest receivers on Android. Nothing at build time
/// connects them — a widget missing from one side simply never appears, which
/// is exactly what happened: the iOS extension was never added to the Xcode
/// project and ten of the twelve widgets did not exist on iPhone at all, for
/// months, silently.
///
/// These checks are the connection.
void main() {
  final dart = File('lib/services/widget_service.dart').readAsStringSync();
  final swift = File('ios/ImprovyWidget/ImprovyWidgets.swift').readAsStringSync();
  final kotlin =
      File('android/app/src/main/kotlin/com/improvy/improvy/ImprovyWidgets.kt')
          .readAsStringSync();
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

  /// The (Android provider, iOS kind) pairs the app refreshes.
  final published = RegExp(r"\('(\w+)', '(\w+)'\)")
      .allMatches(dart)
      .map((m) => (m.group(1)!, m.group(2)!))
      .toList();

  test('the app publishes twelve widgets', () {
    expect(published.length, 12);
  });

  group('iOS', () {
    test('the widget extension is in the Xcode project', () {
      // Without a target there is no extension, and no widget can exist on the
      // phone however much Swift is in the repo.
      expect(pbxproj, contains('ImprovyWidget'));
      expect(pbxproj, contains('com.apple.product-type.app-extension'));
      expect(pbxproj, contains('com.improvy.app.ImprovyWidget'));
      // The app's own half of the shared container.
      expect(pbxproj, contains('Runner/Runner.entitlements'));
    });

    test('every kind the app refreshes exists in Swift', () {
      for (final (_, kind) in published) {
        expect(swift, contains('kind: "$kind"'), reason: kind);
      }
    });

    test('every widget in the bundle is one the app refreshes', () {
      final kinds = RegExp(r'kind: "(\w+)"')
          .allMatches(swift)
          .map((m) => m.group(1)!)
          .toSet();
      expect(kinds.length, 12);
      for (final kind in kinds) {
        expect(published.map((p) => p.$2), contains(kind), reason: kind);
      }
      // A widget written but left out of the bundle never appears in the
      // gallery, which looks exactly like a widget that was never written.
      final bundle = swift.split('struct ImprovyWidgetBundle').last;
      for (final kind in kinds) {
        expect(bundle, contains('$kind()'), reason: kind);
      }
    });
  });

  group('Android', () {
    test('every provider the app refreshes exists, and is declared', () {
      for (final (provider, _) in published) {
        expect(kotlin, contains('class $provider'), reason: provider);
        // The manifest names them relative to the package: ".ImprovyFoo".
        expect(manifest, contains('android:name=".$provider"'), reason: provider);
      }
    });
  });

  test('every key the app writes is read by both platforms', () {
    // A payload key added on one side only is a widget that quietly shows
    // nothing on the other — the exact failure this file exists to stop.
    final written = RegExp(r"saveWidgetData<\w+>\(\s*'(\w+)'")
        .allMatches(dart)
        .map((m) => m.group(1)!)
        .toSet();
    expect(written, contains('week_json'));
    final swiftKit = File('ios/ImprovyWidget/ImprovyKit.swift').readAsStringSync();
    // Keys one platform reads and the other has no use for. Each is a
    // difference in how the same thing is drawn, not a gap — and naming the
    // reason here is what keeps this list from becoming a place to hide one.
    const iOSOnly = {
      'labels_json': 'Android localises its widget chrome in res/values-xx',
      'animal_emoji': "Android draws the app's own line art for the animal",
    };
    for (final key in written) {
      final onIos = swift.contains('"$key"') || swiftKit.contains('"$key"');
      expect(onIos, isTrue, reason: '$key is never read on iOS');
      if (iOSOnly.containsKey(key)) continue;
      expect(kotlin, contains('"$key"'), reason: '$key is never read on Android');
    }
  });

  test('a lost payload cannot pass for a good one', () {
    // The whole feature's silent failure: on iOS a signed app that cannot
    // reach the App Group gets a nil UserDefaults suite, and the plugin then
    // drops every write and still answers true. Only reading a value back
    // tells them apart, and only something saying so out loud connects empty
    // widgets to their cause.
    expect(dart, contains('Future<bool> probeSharedStorage()'));
    expect(dart, contains('getWidgetData<String>(_probeKey'));
    expect(dart, contains('widgetStorageUnreachable'));
    // And the catch that used to swallow a failed sync whole.
    expect(dart, contains('Ev.widgetSyncFailed'));
    expect(dart, isNot(contains("if (kDebugMode) debugPrint('[WidgetService] sync failed: \$e');\n    }")),
        reason: 'a release build prints nowhere');
  });

  test('the app can see whether its own extension shipped', () {
    // "Improvy is not in the widget gallery" has three possible causes and
    // none of them is visible from Dart: the extension may not be inside the
    // installed app, it may carry a version iOS refuses to register, or the
    // App Group may not open. The probe answers all three from the platform.
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(appDelegate, contains('improvy/widget_probe'));
    expect(appDelegate, contains('builtInPlugInsURL'),
        reason: 'looking inside Runner.app/PlugIns is the only way to know');
    expect(appDelegate, contains('containerURL(\n        forSecurityApplicationGroupIdentifier:'));
    expect(dart, contains("MethodChannel('improvy/widget_probe')"));
  });

  test('the App Group is the same string everywhere', () {
    const group = 'group.com.improvy.app.widget';
    expect(dart, contains("iOSAppGroupId = '$group'"));
    expect(File('ios/ImprovyWidget/ImprovyKit.swift').readAsStringSync(),
        contains('appGroupId = "$group"'));
    for (final f in [
      'ios/Runner/Runner.entitlements',
      'ios/ImprovyWidget/ImprovyWidget.entitlements',
    ]) {
      expect(File(f).readAsStringSync(), contains(group), reason: f);
    }
  });

  test('the extension takes its version from the app', () {
    // An app extension must carry the same CFBundleShortVersionString and
    // CFBundleVersion as the app around it. Both come from FLUTTER_BUILD_NAME
    // and FLUTTER_BUILD_NUMBER, which Flutter writes into
    // ios/Flutter/Generated.xcconfig at build time — and which are only
    // DEFINED in a target that includes that file.
    //
    // The widget target did not, so the two settings expanded to nothing and
    // the extension shipped with an empty version. Nothing fails at build
    // time: the archive succeeds, the upload succeeds, and App Store Connect
    // marks the build "Invalid Binary" some minutes later, with the reason in
    // an email rather than anywhere in the build log.
    final widgetConfigs = RegExp(
            r'isa = XCBuildConfiguration;\n(.*?)\n\t\t\};',
            dotAll: true)
        .allMatches(pbxproj)
        .map((m) => m.group(1)!)
        .where((b) => b.contains('PRODUCT_BUNDLE_IDENTIFIER = com.improvy.app.ImprovyWidget;'))
        .toList();
    expect(widgetConfigs, hasLength(3), reason: 'Debug, Release and Profile');
    for (final config in widgetConfigs) {
      expect(config, contains(r'CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"'));
      expect(config, contains(r'MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)"'));
      expect(config, contains('baseConfigurationReference'),
          reason: 'without an xcconfig those two variables are undefined here');
      expect(config, matches(RegExp(r'baseConfigurationReference = \w+ /\* (Debug|Release)\.xcconfig')));
    }
    // And the xcconfigs they point at must be the ones that carry the values.
    for (final f in ['ios/Flutter/Debug.xcconfig', 'ios/Flutter/Release.xcconfig']) {
      expect(File(f).readAsStringSync(), contains('#include "Generated.xcconfig"'), reason: f);
    }
  });

  test('both bundle ids are signed for on Codemagic', () {
    // Adding the extension without fetching its profile fails the build at the
    // signing step, an hour into the pipeline.
    final ci = File('codemagic.yaml').readAsStringSync();
    expect(ci, contains('com.improvy.app.ImprovyWidget'));
    expect(ci, contains(r'for B in "$BUNDLE_ID" "$WIDGET_BUNDLE_ID"'));
  });
}
