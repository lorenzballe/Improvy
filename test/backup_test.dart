import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';

/// The backup is the answer to "I paid for a lifetime licence and lost six
/// months of keys". It has to bring everything back, and it has to refuse a
/// wrong file without touching anything.
Future<AppProvider> providerWith() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  await storage.init();
  final p = AppProvider(storage);
  await p.init();
  return p;
}

void main() {
  test('everything that was exported comes back', () async {
    final p = await providerWith();
    p.completeTutorial();
    p.setNotation('DoReMi');
    p.setSimpleNotes(true);
    p.progressData = [
      for (final k in p.progressData)
        if (k.key == 'G')
          k.copyWith(chromaticLevels: [30, 40, 47], ntnDiatonicLevels: [24, 0, 0])
        else
          k,
    ];
    await p.storage.saveProgress(p.progressData);

    final file = p.storage.exportJson();

    // A brand-new phone.
    final q = await providerWith();
    expect(q.tutorialCompleted, isFalse);
    expect(q.progressFor('G').normalProgress, 0);

    await q.storage.importJson(file);
    await q.reloadFromStorage();

    expect(q.tutorialCompleted, isTrue);
    expect(q.notation, 'DoReMi');
    expect(q.simpleNotes, isTrue);
    expect(q.progressFor('G').chromaticLevels, [30, 40, 47]);
    expect(q.progressFor('G').ntnDiatonicLevels, [24, 0, 0]);
    // Chromatic Master at 47/50 credits the diatonic row too: (1 + 1 + .94)/3 both sides.
    expect(q.progressFor('G').normalProgress, 98);
  });

  test('Pro is not in the file — it belongs to the store account', () async {
    final p = await providerWith();
    p.setIsPro(true);
    expect(p.storage.exportJson(), isNot(contains('isPro')));
  });

  test('a file that is not a backup is refused before anything is written',
      () async {
    final p = await providerWith();
    p.setNotation('DoReMi');

    for (final bad in ['not json', '{"app":"other"}', '{"app":"improvy","format":99,"data":{}}', '{"app":"improvy","format":1}']) {
      await expectLater(p.storage.importJson(bad), throwsFormatException);
    }
    // Untouched.
    expect(p.storage.loadNotation(), 'DoReMi');
  });

  test('a bad value inside an otherwise valid file leaves everything alone',
      () async {
    final p = await providerWith();
    p.setNotation('DoReMi');
    final poisoned =
        '{"app":"improvy","format":1,"data":{"musical_journey_notation":"CDE","musical_journey_simple_notes":[1,2]}}';
    await expectLater(p.storage.importJson(poisoned), throwsFormatException);
    expect(p.storage.loadNotation(), 'DoReMi',
        reason: 'validation happens before the first write, not during');
  });

  test('restoring keeps the Pro status the store last reported', () async {
    final p = await providerWith();
    p.setIsPro(true);
    final file = p.storage.exportJson();
    await p.storage.importJson(file);
    await p.reloadFromStorage();
    expect(p.isPro, isTrue);
  });
}
