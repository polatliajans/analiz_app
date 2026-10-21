import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const themeModeKey = 'theme_mode';

/// Reads the saved theme. Anything missing or unknown (including existing
/// users who never chose) means dark, the app's default.
ThemeMode readThemeMode(SharedPreferences prefs) {
  switch (prefs.getString(themeModeKey)) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      return readThemeMode(ref.read(sharedPreferencesProvider));
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  /// Applies the mode immediately and saves it.
  Future<void> select(ThemeMode mode) async {
    state = mode;
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(themeModeKey, mode.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
