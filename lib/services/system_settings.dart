import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:url_launcher/url_launcher.dart';

/// Opens this app's page in the OS settings.
///
/// Both platforms ask for notification permission exactly once. After a "no"
/// the app can never ask again — every later request returns false without
/// showing anything — so the only repair is the system settings, and telling
/// someone to go and find them is not the same as taking them there.
abstract final class SystemSettings {
  static const _channel = MethodChannel('improvy/system_settings');

  static Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Apple's own URL for it, and the only one they allow.
        return await launchUrl(Uri.parse('app-settings:'));
      }
      // Android needs an Intent, which no URL can express — see
      // MainActivity.kt.
      return await _channel.invokeMethod<bool>('openNotificationSettings') ?? false;
    } catch (_) {
      return false;
    }
  }
}
