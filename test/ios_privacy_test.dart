@Tags(['ios'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Apple scans the binary for APIs that touch private data and rejects the
/// upload when a matching purpose string is missing from Info.plist — whether
/// or not the app ever calls them.
///
/// Build 35 of 1.14.0 was rejected exactly this way: file_picker, added for
/// the backup restore, links UIImagePickerController and PHPickerViewController
/// on iOS even when only a JSON file is ever asked for. It was replaced with
/// file_selector, which is UIDocumentPickerViewController and nothing else.
///
/// This walks every locked package's iOS sources and fails if one references
/// a guarded API that Info.plist does not explain — so the next dependency
/// that drags one in is caught here, in seconds, rather than by Apple three
/// days later.
///
/// Tagged `ios` and skipped by default (dart_test.yaml): it reads the pub
/// cache, which is present on a build machine after `pub get` but not
/// necessarily on every contributor's.
void main() {
  const guarded = {
    'NSPhotoLibraryUsageDescription':
        r'PHPhotoLibrary|PHPickerViewController|UIImagePickerController',
    'NSCameraUsageDescription':
        r'AVCaptureDevice|UIImagePickerControllerSourceTypeCamera',
    'NSLocationWhenInUseUsageDescription':
        r'CLLocationManager|requestWhenInUseAuthorization',
    'NSMicrophoneUsageDescription': r'AVAudioRecorder|requestRecordPermission',
    'NSContactsUsageDescription': r'CNContactStore',
  };

  test('no package references a guarded iOS API without a purpose string', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();

    // name -> version, from the lockfile's own shape.
    final versions = <String, String>{};
    String? current;
    for (final line in lock.split('\n')) {
      final name = RegExp(r'^  ([a-z0-9_]+):$').firstMatch(line);
      if (name != null) current = name.group(1);
      final v = RegExp(r'^    version: "([^"]+)"$').firstMatch(line);
      if (v != null && current != null) versions[current] = v.group(1)!;
    }

    final cacheRoot = Directory(
        '${Platform.environment['HOME'] ?? ''}/.pub-cache/hosted/pub.dev');
    if (!cacheRoot.existsSync()) {
      markTestSkipped('no pub cache to read');
      return;
    }

    final offenders = <String, Set<String>>{};
    for (final entry in versions.entries) {
      for (final sub in ['ios', 'darwin']) {
        final dir = Directory('${cacheRoot.path}/${entry.key}-${entry.value}/$sub');
        if (!dir.existsSync()) continue;
        for (final f in dir.listSync(recursive: true).whereType<File>()) {
          // A package's own example app and unit tests are not shipped.
          if (f.path.contains('/example/') || f.path.contains('Tests')) continue;
          if (!RegExp(r'\.(m|h|swift|mm)$').hasMatch(f.path)) continue;
          final src = f.readAsStringSync();
          for (final g in guarded.entries) {
            if (RegExp(g.value).hasMatch(src) && !plist.contains(g.key)) {
              offenders.putIfAbsent(g.key, () => {}).add(entry.key);
            }
          }
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'These packages will get the upload rejected (ITMS-90683). '
            'Either drop the package for one that does not link the API, or '
            'add the purpose string to ios/Runner/Info.plist and declare it '
            'in the privacy manifest and the App Store label: $offenders');
  });
}
