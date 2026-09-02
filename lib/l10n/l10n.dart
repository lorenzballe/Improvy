import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.startTraining` instead of
/// `AppLocalizations.of(context).startTraining` at every call site.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Strings for code that has no BuildContext — notifications scheduled from
/// the provider, share text built in a model. Resolves the device locale to
/// the nearest supported one, English when nothing matches.
class L10n {
  L10n._();

  static AppLocalizations get current => forLocale(PlatformDispatcher.instance.locale);

  static AppLocalizations forLocale(Locale locale) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return lookupAppLocalizations(supported);
      }
    }
    return lookupAppLocalizations(const Locale('en'));
  }

  /// Languages whose musicians write Do Re Mi rather than C D E. The app has
  /// both notations; this picks the right one on first run, and the voice in
  /// Pocket Mode follows the notation, so an Italian hears "Do diesis".
  static const solfegeLanguages = {'it', 'es', 'fr', 'pt'};

  static bool prefersSolfege(Locale locale) =>
      solfegeLanguages.contains(locale.languageCode);
}
