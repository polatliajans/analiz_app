import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_provider.dart';

const startupTabKey = 'startup_tab';

/// Which tab the app opens on at cold start.
enum StartupTab { home, chart }

/// Reads the saved startup tab; anything missing/unknown (existing users)
/// means [StartupTab.home].
StartupTab readStartupTab(SharedPreferences prefs) =>
    prefs.getString(startupTabKey) == 'chart'
    ? StartupTab.chart
    : StartupTab.home;

class StartupTabNotifier extends Notifier<StartupTab> {
  @override
  StartupTab build() => readStartupTab(ref.read(sharedPreferencesProvider));

  Future<void> select(StartupTab tab) async {
    state = tab;
    await ref
        .read(sharedPreferencesProvider)
        .setString(startupTabKey, tab.name);
  }
}

final startupTabProvider = NotifierProvider<StartupTabNotifier, StartupTab>(
  StartupTabNotifier.new,
);
