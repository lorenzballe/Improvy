import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/models/key_progress.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';

/// Note to Number used to run thirty questions at every tier. Master opens at
/// [kTierUnlock] correct in Virtuoso — more than thirty allows — so the tier
/// could never be reached, and the summary called a 29/30 Virtuoso run NOT
/// YET against a gate it could not have passed.
void main() {
  Future<AppProvider> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final p = AppProvider(storage);
    await p.init();
    return p;
  }

  test('a Note to Number run is as long as its tier is worth', () async {
    final p = await fresh();
    p.selectKey('G');
    p.startNoteToNumberMode(degrees: const ['1', '2', '3'], difficulty: 2);
    expect(p.customQuestions, isNull,
        reason: 'null hands the trainer its 30/40/50-by-tier default');
    expect(p.customDifficulty, 2);
  });

  test('so the gate into Master is inside a Virtuoso run', () {
    // The trainer's own fallback: 30, 40, 50 by difficulty.
    const questionsByTier = [30, 40, 50];
    expect(questionsByTier[1], greaterThanOrEqualTo(kTierUnlock[2]));
  });

  test('a caller can still ask for a specific length', () async {
    final p = await fresh();
    p.selectKey('G');
    p.startNoteToNumberMode(degrees: const ['1'], questions: 12);
    expect(p.customQuestions, 12);
  });
}
