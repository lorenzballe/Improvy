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

  test('both bundle ids are signed for on Codemagic', () {
    // Adding the extension without fetching its profile fails the build at the
    // signing step, an hour into the pipeline.
    final ci = File('codemagic.yaml').readAsStringSync();
    expect(ci, contains('com.improvy.app.ImprovyWidget'));
    expect(ci, contains(r'for B in "$BUNDLE_ID" "$WIDGET_BUNDLE_ID"'));
  });
}
