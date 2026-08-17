import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/release_notes.dart';

/// The version string is the one number a release cannot get wrong.
///
/// App Store Connect closes a version to new builds the moment one is approved
/// under it, and rejects the upload with "the train version is closed" — after
/// the whole build has run. The bundle version comes from pubspec, the number
/// printed on the What's New sheet comes from [kReleases], and nothing tied
/// them together, so they could drift silently and the sheet could announce a
/// version the binary is not.
void main() {
  final pubspec = File('pubspec.yaml').readAsLinesSync();
  final line = pubspec.firstWhere((l) => l.startsWith('version:'));
  // `version: 1.7.1+74` → name '1.7.1', build '74'
  final value = line.split(':')[1].trim();
  final name = value.split('+').first;
  final build = value.contains('+') ? value.split('+').last : '';

  test('pubspec carries a full version and a build number', () {
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name), isTrue,
        reason: 'version name "$name" is not x.y.z');
    expect(int.tryParse(build), isNotNull,
        reason: 'no build number in "$value" — every upload needs a new one');
  });

  test('the What\'s New sheet announces the version actually shipping', () {
    expect(kReleases, isNotEmpty);
    expect(kReleases.first.version, name,
        reason: 'pubspec says $name, the release notes say '
            '${kReleases.first.version} — the sheet would name the wrong build');
  });

  test('the release list runs newest first, with no repeats', () {
    // The sheet shows kReleases.first as "current". Out of order, an update
    // would greet the user with an older release's notes.
    final versions = kReleases.map((r) => r.version).toList();
    expect(versions.toSet().length, versions.length,
        reason: 'a version is listed twice: $versions');

    List<int> parts(String v) => v.split('.').map(int.parse).toList();
    for (var i = 1; i < versions.length; i++) {
      final a = parts(versions[i - 1]), b = parts(versions[i]);
      final newer = a[0] != b[0]
          ? a[0] > b[0]
          : a[1] != b[1]
              ? a[1] > b[1]
              : a[2] > b[2];
      expect(newer, isTrue,
          reason: '${versions[i - 1]} should come after ${versions[i]}');
    }
  });
}
