import 'dart:ui';

import 'app_localizations.dart';

/// Holds the localizations for the active language so code that has no
/// BuildContext (the data layer's exception messages) can still produce
/// translated text. Updated by the locale provider whenever the language changes.
class AppL10n {
  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  static AppLocalizations get current => _current;

  static void setLocale(Locale locale) {
    _current = lookupAppLocalizations(locale);
  }
}
