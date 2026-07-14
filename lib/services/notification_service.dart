/// Facade for local notifications. The conditional export picks the real
/// implementation on Android/iOS (dart.library.io) and a no-op stub on the
/// web, so flutter_local_notifications is never compiled into the web build.
export 'reminder_plan.dart';
export 'notification_service_stub.dart' if (dart.library.io) 'notification_service_io.dart';
