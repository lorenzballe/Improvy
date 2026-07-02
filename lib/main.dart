import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/purchase_service.dart';
import 'services/analytics_service.dart';
import 'screens/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));

  final storage = StorageService();
  await storage.init();

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

  /// The UI is a pixel-perfect port laid out against this reference width
  /// (the ~411dp logical width of the design device). Real phones differ in
  /// density, display-zoom and font-size settings, which was reflowing the
  /// whole app (wrapped labels, clipped START buttons, squashed paywall).
  static const double _designWidth = 411.4;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Improvy',
      debugShowCheckedModeBanner: false,
      // Normalise every device to the reference width: the app always lays
      // out at 411.4dp wide and is scaled uniformly to the physical screen —
      // exactly like a web page viewport. System font scaling is neutralised
      // on purpose: the layout is design-locked, same trade-off as the web app.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        if (child == null || mq.size.width <= 0 || mq.size.height <= 0) {
          return child ?? const SizedBox.shrink();
        }
        final scale = mq.size.width / _designWidth;
        final designSize = Size(_designWidth, mq.size.height / scale);
        EdgeInsets shrink(EdgeInsets e) => EdgeInsets.fromLTRB(
            e.left / scale, e.top / scale, e.right / scale, e.bottom / scale);
        return MediaQuery(
          data: mq.copyWith(
            size: designSize,
            devicePixelRatio: mq.devicePixelRatio * scale,
            textScaler: TextScaler.noScaling,
            padding: shrink(mq.padding),
            viewPadding: shrink(mq.viewPadding),
            viewInsets: shrink(mq.viewInsets),
          ),
          child: FittedBox(
            fit: BoxFit.fill,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: designSize.width,
              height: designSize.height,
              child: child,
            ),
          ),
        );
      },
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
