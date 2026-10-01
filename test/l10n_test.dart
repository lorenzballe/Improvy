import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:improvy/providers/app_provider.dart';
import 'package:improvy/services/storage_service.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/screens/explainer_screen.dart';

/// The app is English, with Do Re Mi kept as a notation.
void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

  test('the app speaks English only', () {
    // One language, written with care, rather than six that drift. A string
    // added in English is the whole job.
    expect(AppLocalizations.supportedLocales, [const Locale('en')]);
    final arbs = Directory('lib/l10n')
        .listSync()
        .where((f) => f.path.endsWith('.arb'))
        .map((f) => f.uri.pathSegments.last)
        .toList();
    expect(arbs, ['app_en.arb']);
    expect(en.keys.where((k) => !k.startsWith('@')), isNotEmpty);
  });

  test('every device language gets the English app', () {
    for (final code in ['en', 'it', 'de', 'ja']) {
      expect(L10n.forLocale(Locale(code)).next, 'Next', reason: code);
    }
  });

  test('the languages that write Do Re Mi still get it on first run', () {
    // The notation is not a translation: an Italian musician reads Do Re Mi
    // whatever language the buttons are in, and Pocket Mode's voice follows
    // the notation.
    for (final code in ['it', 'es', 'fr', 'pt']) {
      expect(L10n.prefersSolfege(Locale(code)), isTrue, reason: code);
    }
    for (final code in ['en', 'de', 'ja']) {
      expect(L10n.prefersSolfege(Locale(code)), isFalse, reason: code);
    }
  });

  testWidgets('an Italian phone gets English words', (t) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final provider = AppProvider(storage);
    await provider.init();
    await t.pumpWidget(ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: ExplainerScreen(onDone: () {}),
      ),
    ));
    await t.pump();
    expect(find.textContaining('Every key'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
