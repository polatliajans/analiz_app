import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_http.dart';
import '../l10n/app_l10n.dart';
import '../l10n/locale_resolver.dart';

const _localeKey = 'locale';
const _chosenKey = 'language_chosen';

/// Overridden in main() with the instance loaded before runApp, so the first
/// frame already has the right language.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

class LocaleState {
  final Locale locale;
  final bool hasChosen;

  const LocaleState({required this.locale, required this.hasChosen});
}

class LocaleNotifier extends Notifier<LocaleState> {
  @override
  LocaleState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final locale = resolveLocale(
      saved: prefs.getString(_localeKey),
      deviceLocales: PlatformDispatcher.instance.locales,
    );
    _apply(locale);
    return LocaleState(
      locale: locale,
      hasChosen: prefs.getBool(_chosenKey) ?? false,
    );
  }

  void _apply(Locale locale) {
    AppL10n.setLocale(locale);
    ApiHttp.languageCode = locale.languageCode;
  }

  /// Switches the language without saving it (live preview on the first-run screen).
  void preview(Locale locale) {
    _apply(locale);
    state = LocaleState(locale: locale, hasChosen: state.hasChosen);
  }

  /// Saves the language and marks the first-run choice as done.
  Future<void> confirm(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode);
    await prefs.setBool(_chosenKey, true);
    _apply(locale);
    state = LocaleState(locale: locale, hasChosen: true);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);
