import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/l10n/l10n.dart';
import 'package:improvy/screens/explainer_screen.dart';

/// A translation that drifts is worse than none: the app would fall back to
/// English for one string in the middle of an Italian screen, or crash on a
/// placeholder the translator renamed. These keep the six files in step.
void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final placeholders = RegExp(r'\{(\w+)[,}]');

  for (final locale in ['it', 'es', 'fr', 'de', 'pt']) {
    test('$locale has every key, and every placeholder, that English has', () {
      final f = File('lib/l10n/app_$locale.arb');
      expect(f.existsSync(), isTrue, reason: 'app_$locale.arb is missing');
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final have = d.keys.where((k) => !k.startsWith('@')).toSet();
      expect(keys.difference(have), isEmpty, reason: 'untranslated in $locale');
      expect(have.difference(keys), isEmpty, reason: 'keys in $locale that English lacks');
      for (final k in keys) {
        final pe = placeholders.allMatches(en[k] as String).map((m) => m.group(1)).toSet();
        final pl = placeholders.allMatches(d[k] as String).map((m) => m.group(1)).toSet();
        expect(pl, pe, reason: 'placeholders differ on "$k" in $locale');
      }
    });
  }

  test('every supported locale resolves, and an unknown one falls back to English', () {
    expect(L10n.forLocale(const Locale('it')).next, 'Avanti');
    expect(L10n.forLocale(const Locale('de')).next, 'Weiter');
    expect(L10n.forLocale(const Locale('ja')).next, 'Next');
    // A regional variant maps to its language.
    expect(L10n.forLocale(const Locale('pt', 'BR')).next, 'Seguinte');
  });

  test('the languages that write Do Re Mi get it on first run', () {
    for (final code in ['it', 'es', 'fr', 'pt']) {
      expect(L10n.prefersSolfege(Locale(code)), isTrue, reason: code);
    }
    for (final code in ['en', 'de', 'ja']) {
      expect(L10n.prefersSolfege(Locale(code)), isFalse, reason: code);
    }
  });

  testWidgets('a screen renders in the device language', (t) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: ExplainerScreen(onDone: () {}),
    ));
    await t.pump();
    expect(find.textContaining('Ogni nota'), findsOneWidget);
    expect(find.text('Avanti'), findsOneWidget);
    expect(find.text('Salta'), findsOneWidget);
  });
}
