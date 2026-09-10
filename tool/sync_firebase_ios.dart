// Brings the iOS project in step with lib/firebase_options.dart.
//
//   dart run tool/sync_firebase_ios.dart          # apply
//   dart run tool/sync_firebase_ios.dart --check  # exit 1 if anything is off
//
// Two things on iOS cannot be set from Dart and depend on values that only
// exist once the Firebase project does:
//
//   1. Google Sign-In returns to the app through a custom URL scheme that is
//      the iOS OAuth client ID written backwards. Without it the sign-in
//      sheet opens, the person picks an account, and nothing comes back.
//   2. Sign in with Apple needs its entitlement on the app. The entitlement
//      only signs if the App ID carries the capability in the Apple
//      developer account, so it is added HERE, at the same moment as the
//      rest, and not before — a build made before the project exists must
//      still sign.
//
// Both are idempotent, both are no-ops while firebase_options.dart is still
// placeholders, and Codemagic runs this before pod install so that nobody has
// to remember to.
import 'dart:io';

const _options = 'lib/firebase_options.dart';
const _plist = 'ios/Runner/Info.plist';
const _entitlements = 'ios/Runner/Runner.entitlements';

void main(List<String> args) {
  final check = args.contains('--check');
  final options = File(_options).readAsStringSync();
  final iosClientId = RegExp(r"iosClientId:\s*'([^']+)'").firstMatch(options)?.group(1);
  if (iosClientId == null || iosClientId.startsWith('REPLACE_ME')) {
    stdout.writeln('firebase_options.dart is still placeholders — nothing to sync.');
    return;
  }
  final reversed = reverseClientId(iosClientId);

  var changed = false;
  changed |= _syncPlist(reversed, check: check);
  changed |= _syncEntitlements(check: check);

  if (check && changed) {
    stderr.writeln('ios/ is out of step with $_options — run: dart run tool/sync_firebase_ios.dart');
    exit(1);
  }
  stdout.writeln(changed ? 'ios/ updated.' : 'ios/ already in step.');
}

/// `123-abc.apps.googleusercontent.com` → `com.googleusercontent.apps.123-abc`
String reverseClientId(String clientId) => clientId.split('.').reversed.join('.');

bool _syncPlist(String scheme, {required bool check}) {
  final f = File(_plist);
  final s = f.readAsStringSync();
  if (s.contains('<string>$scheme</string>')) return false;
  if (check) {
    stderr.writeln('$_plist lacks the Google Sign-In URL scheme $scheme');
    return true;
  }
  // Drop any previous reversed client id (the project was re-created), then
  // add this one as its own URL type beside improvy://.
  final cleaned = s.replaceAll(
    RegExp(r'\t\t<dict>\n\t\t\t<key>CFBundleTypeRole</key>\n\t\t\t<string>Editor</string>\n\t\t\t<key>CFBundleURLName</key>\n\t\t\t<string>google-sign-in</string>\n[\s\S]*?\t\t</dict>\n'),
    '',
  );
  const marker = '\t<key>CFBundleURLTypes</key>\n\t<array>\n';
  if (!cleaned.contains(marker)) {
    throw StateError('$_plist has no CFBundleURLTypes array to add to');
  }
  final entry = '$marker'
      '\t\t<!-- Google Sign-In returns here. Generated from firebase_options.dart\n'
      '\t\t     by tool/sync_firebase_ios.dart; do not edit by hand. -->\n'
      '\t\t<dict>\n'
      '\t\t\t<key>CFBundleTypeRole</key>\n'
      '\t\t\t<string>Editor</string>\n'
      '\t\t\t<key>CFBundleURLName</key>\n'
      '\t\t\t<string>google-sign-in</string>\n'
      '\t\t\t<key>CFBundleURLSchemes</key>\n'
      '\t\t\t<array>\n'
      '\t\t\t\t<string>$scheme</string>\n'
      '\t\t\t</array>\n'
      '\t\t</dict>\n';
  f.writeAsStringSync(cleaned.replaceFirst(marker, entry));
  stdout.writeln('$_plist: added URL scheme $scheme');
  return true;
}

bool _syncEntitlements({required bool check}) {
  final f = File(_entitlements);
  final s = f.readAsStringSync();
  const key = 'com.apple.developer.applesignin';
  if (s.contains('<key>$key</key>')) return false;
  if (check) {
    stderr.writeln('$_entitlements lacks $key');
    return true;
  }
  const marker = '\t<key>com.apple.security.application-groups</key>';
  if (!s.contains(marker)) throw StateError('$_entitlements: unexpected shape');
  final entry = '\t<!-- Sign in with Apple. Needs the capability on the App ID in the\n'
      '\t     Apple developer account, like App Groups — see FIREBASE_SETUP.md. -->\n'
      '\t<key>$key</key>\n'
      '\t<array>\n'
      '\t\t<string>Default</string>\n'
      '\t</array>\n'
      '$marker';
  f.writeAsStringSync(s.replaceFirst(marker, entry));
  stdout.writeln('$_entitlements: added $key');
  return true;
}
