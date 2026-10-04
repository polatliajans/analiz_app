import 'dart:ui';

const supportedAppLocales = [Locale('en'), Locale('tr'), Locale('es')];

bool _isSupported(String code) =>
    supportedAppLocales.any((l) => l.languageCode == code);

/// Saved preference first, then the first supported device language, else English.
Locale resolveLocale({String? saved, required List<Locale> deviceLocales}) {
  if (saved != null && _isSupported(saved)) return Locale(saved);

  for (final locale in deviceLocales) {
    if (_isSupported(locale.languageCode)) return Locale(locale.languageCode);
  }

  return const Locale('en');
}
