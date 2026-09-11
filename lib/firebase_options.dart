// Firebase project configuration — one block per platform.
//
// Project `improvy-f470f`. Both platforms register under the SAME identifier,
// com.improvy.app: that is `applicationId` on Android (the Kotlin namespace
// com.improvy.improvy is only where the sources live) and
// PRODUCT_BUNDLE_IDENTIFIER on iOS.
//
// Regenerate with `flutterfire configure` on a machine with the Flutter SDK
// (it overwrites this whole file — that is fine, nothing else lives here) or
// copy the values out of google-services.json and GoogleService-Info.plist by
// hand. FIREBASE_SETUP.md maps every field to where it comes from.
//
// None of these values is a secret: they identify the project, they do not
// authorise anything. They ship inside the published app either way. What
// protects the data is firestore.rules.
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
    apiKey: 'AIzaSyC_Vo90VIrNYLxkatgBSRNruUq_uaQ6uhA',
    appId: '1:376089080639:android:9fd793d96d5e3c792c198a',
    messagingSenderId: '376089080639',
    projectId: 'improvy-f470f',
    storageBucket: 'improvy-f470f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJURFAgpeYOqkKLgRbSeHNVMU2qIg8-2M',
    appId: '1:376089080639:ios:b1d4dafe4c9f769d2c198a',
    messagingSenderId: '376089080639',
    projectId: 'improvy-f470f',
    storageBucket: 'improvy-f470f.firebasestorage.app',
    iosClientId: '376089080639-sjcuk0sml31vmtrlcq04ogrqfk99ut72.apps.googleusercontent.com',
    iosBundleId: 'com.improvy.app',
  );

  /// The app does not ship a web build. This exists so that a debug run in a
  /// browser does not die on a missing platform, and carries the project's
  /// own values rather than invented ones.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCJURFAgpeYOqkKLgRbSeHNVMU2qIg8-2M',
    appId: '1:376089080639:ios:b1d4dafe4c9f769d2c198a',
    messagingSenderId: '376089080639',
    projectId: 'improvy-f470f',
    authDomain: 'improvy-f470f.firebaseapp.com',
    storageBucket: 'improvy-f470f.firebasestorage.app',
  );
}
