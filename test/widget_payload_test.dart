@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/models/daily_challenge.dart';
import 'package:improvy/models/training_mode.dart';
import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/widget_service.dart';

import 'site_screens_test.dart' show seeded;

/// Writes the exact payload the app hands the home-screen widgets, for a
/// believable player, to build/widget_payload/<state>.json.
///
/// The widgets only render what this writes, so the renders made from it on a
/// Mac (.github/workflows/widgets.yml) show the real widgets with real data —
/// not a mock of either.
///
///   flutter test test/widget_payload_test.dart --run-skipped
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Map<String, Object?>> capture(AppProvider p) async {
    final out = <String, Object?>{};
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final args = Map<String, Object?>.from(call.arguments as Map);
        out[args['id'] as String] = args['data'];
      }
      if (call.method == 'getWidgetData') {
        final args = Map<String, Object?>.from(call.arguments as Map);
        return out[args['id'] as String];
      }
      return true;
    });
    await WidgetService.instance.sync(p);
    return out;
  }

  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Ten days of dailies, today's included.
  void dailies(AppProvider p, {required bool today}) {
    final now = DateTime.now();
    for (var i = today ? 0 : 1; i < 10; i++) {
      final d = now.subtract(Duration(days: i));
      p.dailyResults[day(d)] = DailyResult(
        dateKey: day(d),
        key: 'E♭',
        answers: [for (var q = 0; q < 10; q++) (q + i) % 7 != 3],
        timeMs: 21000,
        completed: true,
        timestamp: d.millisecondsSinceEpoch,
        mode: TrainingMode.chromatic,
      );
    }
  }

  Future<void> write(String name, Map<String, Object?> payload) async {
    final dir = Directory('build/widget_payload')..createSync(recursive: true);
    File('${dir.path}/$name.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));
  }

  test('a player who has trained today', () async {
    final p = await seeded();
    dailies(p, today: true);
    final payload = await capture(p);
    expect(payload['daily_played'], isTrue);
    expect(payload['keys_json'], isNotNull);
    await write('played', payload);
  });

  test('a streak about to break', () async {
    final p = await seeded();
    dailies(p, today: false);
    // Nothing yet today: the app opens to an unplayed challenge.
    final history = {...p.stats.dailyHistory}..remove(day(DateTime.now()));
    p.stats = p.stats.copyWith(dailyHistory: history);
    final payload = await capture(p);
    expect(payload['daily_played'], isFalse);
    expect(payload['played_today'], isFalse);
    await write('unplayed', payload);
  });
}
