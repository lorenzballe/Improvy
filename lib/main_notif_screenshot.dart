// Dev-only entrypoint: renders the notification-priming modal over a dark
// backdrop so its copy/layout can be previewed. Not referenced by any
// production build — `flutter build web --target lib/main_notif_screenshot.dart`.
import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Preview(),
    ));

class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF06030B),
        body: Stack(children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1625),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  const Text('Make it stick',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 10),
                  Text('One quick quiz a day keeps every note sharp and your streak alive. Off whenever you want.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withValues(alpha: 0.65))),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Yes, remind me',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Not now',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5))),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
}
