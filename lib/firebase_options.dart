// Firebase project configuration — one block per platform.
//
// These are PLACEHOLDERS. Until they are replaced the app runs exactly as it
// did before accounts existed: FirebaseConfig.isConfigured is false, nothing
// here is initialised, and the Account and Promotional Codes cards explain
// that accounts are not available in this build.
//
// To fill it in, either run `flutterfire configure` on a machine with the
// Flutter SDK (it overwrites this whole file — that is fine, nothing else
// lives here) or paste the values from the Firebase console by hand. Both
// paths are written out in FIREBASE_SETUP.md.
//
// None of these values is a secret: they identify the project, they do not
// authorise anything. What protects the data is firestore.rules.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME_ANDROID_API_KEY',
    appId: 'REPLACE_ME_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    storageBucket: 'REPLACE_ME_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME_IOS_API_KEY',
    appId: 'REPLACE_ME_IOS_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    storageBucket: 'REPLACE_ME_PROJECT_ID.firebasestorage.app',
    iosClientId: 'REPLACE_ME_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.improvy.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME_WEB_API_KEY',
    appId: 'REPLACE_ME_WEB_APP_ID',
    messagingSenderId: 'REPLACE_ME_SENDER_ID',
    projectId: 'REPLACE_ME_PROJECT_ID',
    authDomain: 'REPLACE_ME_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_ME_PROJECT_ID.firebasestorage.app',
  );
}
