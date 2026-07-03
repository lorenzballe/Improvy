import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('measure settings card title widths with real Lexend font',
      (tester) async {
    // Load the real Lexend Black (w900) font so measurement matches device.
    final loader = FontLoader('Lexend');
    loader.addFont(rootBundle.load('assets/fonts/Lexend-Black.ttf'));
    await loader.load();

    const style = TextStyle(
      fontFamily: 'Lexend',
      fontSize: 16,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
    );

    double measure(String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    final adaptive = measure('Adaptive Difficulty');
    final keyboard = measure('Keyboard from Tonic');

    // Width budgets (title column width = screen - chrome):
    // scroll padding 48 + card (20 pad + 1 border)*2 = 42
    // + inner container (20 pad + 1 border)*2 = 42
    // + icon 48 + gap 16 + toggle 56  => 252 total chrome
    const chrome = 48 + 42 + 42 + 48 + 16 + 56;
    debugPrint('MEASURE adaptive=${adaptive.toStringAsFixed(1)} '
        'keyboard=${keyboard.toStringAsFixed(1)} '
        'budget360=${360 - chrome} budget411=${411 - chrome}');
  });
}
