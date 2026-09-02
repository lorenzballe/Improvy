import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'services/keep_alive_audio.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'screens/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  // Nothing between here and runApp may take the app down. Every one of these
  // talks to a platform plugin, and a device that refuses one of them (an old
  // Android, a revoked permission, a store that will not answer) must cost that
  // one feature — not the launch. Without this an exception here left the app
  // opening and vanishing a second later, with no screen ever shown.
  Future<void> attempt(String what, Future<void> Function() run) async {
    try {
      await run();
    } catch (e, s) {
      debugPrint('[startup] $what failed: $e\n$s');
      // A device where storage, the store or notifications quietly fail looks
      // exactly like a device where the user simply stopped playing. This is
      // the only way to tell the two apart.
      AnalyticsService.instance.error(Ev.startupStepFailed, e, {'step': what});
    }
  }

  // Before anything creates an audio player: Pocket Mode's voice has to keep
  // speaking with the screen locked, which needs the playback category in
  // force from the start rather than from the first tap on Play.
  await attempt('audio session', KeepAliveAudio.configureSession);

  final storage = StorageService();
  await attempt('storage', storage.init);

  // Local reminders — must be ready BEFORE provider.init(), which resyncs
  // the pending notifications from the loaded stats. No-op stub on web.
  await attempt('notifications', NotificationService.init);

  final provider = AppProvider(storage);
  await attempt('provider', provider.init);

  // Production services. RevenueCat keeps provider.isPro in sync with the user's
  // real entitlements (purchase / restore / remote updates); PostHog = analytics.
  PurchaseService.instance.onProChanged = provider.setIsPro;
  await attempt('purchases', PurchaseService.instance.init);
  await attempt('analytics', AnalyticsService.instance.init);
  // No manual app_open: captureApplicationLifecycleEvents gives
  // Application Opened / Installed / Updated / Backgrounded, which is both
  // more than this said and more reliable about when it happened.
  provider.syncAnalyticsProfile();

  // Home-screen widgets: pick up the tap that launched us (if any), then push
  // the current state out. Both are best-effort — a widget must never be able
  // to hold up the app starting.
  await attempt('widgets', WidgetService.instance.listenForTaps);
  WidgetService.instance.sync(provider);

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const ImprovyApp(),
    ),
  );
}

class ImprovyApp extends StatelessWidget {
  const ImprovyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Improvy',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _StableInsets(child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(surface: Color(0xFF0F0A1A)),
        scaffoldBackgroundColor: const Color(0xFF0F0A1A),
        useMaterial3: true,
        fontFamily: 'Lexend',
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Lexend'),
      ),
      home: const RootScreen(),
    );
  }
}

/// Neutralises two device quirks app-wide:
///  • clamps the system font-scale to a modest range (the design is tight, so
///    the layout adapts a little instead of breaking under huge accessibility
///    sizes — the screens handle the rest);
///  • latches the LARGEST system-bar insets seen. On some phones the gesture /
///    navigation bar inset flickers between its real height and 0 in edge-to-edge
///    mode, which made SafeArea content (and the bottom bar) oscillate up and
///    down. The app is portrait-locked, so the max is always the real height;
///    we keep feeding that stable value so nothing jumps. The soft keyboard
///    (viewInsets) is left untouched so it can still resize the view normally.
class _StableInsets extends StatefulWidget {
  final Widget child;
  const _StableInsets({required this.child});

  @override
  State<_StableInsets> createState() => _StableInsetsState();
}

class _StableInsetsState extends State<_StableInsets> {
  double _bottom = 0;
  double _top = 0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    // Only grow the latch while the keyboard is closed (otherwise viewPadding
    // already reflects real system bars, not a transient flicker).
    if (!keyboardOpen) _bottom = max(_bottom, mq.viewPadding.bottom);
    _top = max(_top, mq.viewPadding.top);

    final stableBottom = keyboardOpen ? mq.padding.bottom : _bottom;
    return MediaQuery(
      data: mq.copyWith(
        // 1.3, up from 1.1. The design is tight, but ignoring a reader who
        // has asked the OS for larger type is not tightness, it is a wall —
        // and every screen already scales its headline into the room it has.
        textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
        padding: mq.padding.copyWith(top: _top, bottom: stableBottom),
        viewPadding: mq.viewPadding.copyWith(
          top: _top,
          bottom: keyboardOpen ? mq.viewPadding.bottom : _bottom,
        ),
      ),
      child: widget.child,
    );
  }
}
