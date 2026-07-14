import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
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

  final storage = StorageService();
  await storage.init();

  // Local reminders — must be ready BEFORE provider.init(), which resyncs
  // the pending notifications from the loaded stats. No-op stub on web.
  await NotificationService.init();

  final provider = AppProvider(storage);
  await provider.init();

  // Production services. RevenueCat keeps provider.isPro in sync with the user's
  // real entitlements (purchase / restore / remote updates); PostHog = analytics.
  PurchaseService.instance.onProChanged = provider.setIsPro;
  await PurchaseService.instance.init();
  await AnalyticsService.instance.init();
  AnalyticsService.instance.capture('app_open');

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
        textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1),
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
