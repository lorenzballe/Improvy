// Dev-only entrypoint: renders the "…Of What?" trainer directly (fixed note E,
// chord tones) so the piano-keyboard layout can be previewed / screenshotted.
// Not referenced by any production build —
// `flutter build web --target lib/main_ofwhat_screenshot.dart`.
import 'package:flutter/material.dart';
import 'models/training_mode.dart';
import 'screens/trainer_screen.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TrainerScreen(
        mode: TrainingMode.ofWhat,
        selectedKey: 'C',
        fixedNote: const String.fromEnvironment('FIXED_NOTE', defaultValue: 'E'),
        difficulty: 1,
        numberOfQuestions: 15,
        adaptiveDifficulty: false,
        sessionHistory: const [],
        notation: 'english',
        onExit: () {},
        onAnswer: (_, __, ___) {},
        onFinish: (_) {},
      ),
    ));
