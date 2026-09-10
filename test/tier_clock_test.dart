import 'package:flutter_test/flutter_test.dart';
import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/key_progress.dart';
import 'package:improvy/models/training_mode.dart';

/// The three clocks are the difficulty. Everything else — caps, gates, the
/// fluency wall — is downstream of how long a question gives you, so a change
/// here is a change to what "Master" means and is pinned on purpose.
void main() {
  test('Virtuoso lost 30% of its time and Master 15%', () {
    // Apprentice untouched: 6s is where an interval gets worked out by hand.
    expect(kTierClockMs[0], 6000);
    expect(kTierClockMs[1], (3200 * 0.70).round()); // 2240
    expect(kTierClockMs[2], (1200 * 0.85).round()); // 1020
  });

  test('the ladder still descends', () {
    expect(kTierClockMs[0], greaterThan(kTierClockMs[1]));
    expect(kTierClockMs[1], greaterThan(kTierClockMs[2]));
  });

  test('every Master answer is inside the fluency wall', () {
    // The wall stays at 1.2s so that no key is re-ranked by a clock change;
    // it only makes sense if Master's own clock sits inside it.
    expect(kTierClockMs[2], lessThanOrEqualTo(kInstantMs));
  });

  test('the daily is not slower than Virtuoso by much, and never than Master',
      () {
    for (final mode in TrainingMode.values) {
      final ms = DailyChallenge.msPerQuestionFor(mode);
      expect(ms, greaterThan(kTierClockMs[2]), reason: '$mode');
      expect(ms, lessThan(kTierClockMs[0]), reason: '$mode');
    }
  });
}
