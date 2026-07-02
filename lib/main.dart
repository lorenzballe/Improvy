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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Improvy',
      debugShowCheckedModeBanner: false,
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
