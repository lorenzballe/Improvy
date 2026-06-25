import 'package:flutter/services.dart';

class HapticsService {
  static void impactLight() {
    HapticFeedback.lightImpact();
  }

  static void impactMedium() {
    HapticFeedback.mediumImpact();
  }

  static void impactHeavy() {
    HapticFeedback.heavyImpact();
  }

  static void success() {
    HapticFeedback.mediumImpact();
  }

  static void error() {
    HapticFeedback.vibrate();
  }
}
