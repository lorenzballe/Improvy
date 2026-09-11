import '../firebase_options.dart';

/// What the app knows about its Firebase project beyond the generated
/// options — kept apart from firebase_options.dart so that regenerating that
/// file with `flutterfire configure` cannot wipe these.
abstract final class FirebaseConfig {
  /// The marker every placeholder in firebase_options.dart starts with.
  static const placeholder = 'REPLACE_ME';

  /// True once firebase_options.dart carries real values for this platform.
  ///
  /// Everything that touches Firebase checks this first and stays inert when
  /// it is false, so a build made before the project exists — and every unit
  /// test — behaves exactly like the app did before accounts were added.
  static bool get isConfigured => !isPlaceholder(DefaultFirebaseOptions.currentPlatform.apiKey);

  static bool isPlaceholder(String? value) =>
      value == null || value.isEmpty || value.startsWith(placeholder);

  /// The project's **Web** OAuth client ID. Google Sign-In on Android asks
  /// Credential Manager for an ID token with this as its audience, and
  /// Firebase accepts it because the client belongs to the same project.
  ///
  /// This is the `client_type: 3` entry in google-services.json, under the
  /// app's own `oauth_client` — the same value the console shows under
  /// Authentication → Sign-in method → Google → Web SDK configuration.
  static const googleWebClientId =
      '376089080639-6d9s3vn3hrhnj8274ldnk2dh16bla79h.apps.googleusercontent.com';

  /// The iOS OAuth client, from the same place as the rest of the iOS block.
  static String? get googleIosClientId {
    final id = DefaultFirebaseOptions.ios.iosClientId;
    return isPlaceholder(id) ? null : id;
  }

  /// Apple Sign-In on Android runs through Firebase's hosted handler, which
  /// lives on the project's auth domain.
  static String get authDomain => '${DefaultFirebaseOptions.currentPlatform.projectId}.firebaseapp.com';
}
