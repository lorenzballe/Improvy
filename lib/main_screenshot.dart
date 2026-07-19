// Dev-only entrypoint: renders the paywall directly so it can be previewed /
// screenshotted without navigating the app. Not referenced by any production
// build — use `flutter build web --target lib/main_screenshot.dart`.
import 'package:flutter/material.dart';
import 'widgets/paywall_modal.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF06030B),
        body: PaywallModal(onClose: () {}, onPurchase: () async {}),
      ),
    ));
