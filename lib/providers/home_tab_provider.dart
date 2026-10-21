import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';
import 'startup_tab_provider.dart';

const homeTabIndex = 0;
const chartTabIndex = 1;
const radarTabIndex = 2;
const watchlistTabIndex = 3;
const profileTabIndex = 4;

class HomeTabNotifier extends Notifier<int> {
  /// Cold start opens the tab chosen in Settings (Home when never chosen).
  @override
  int build() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      return readStartupTab(prefs) == StartupTab.chart
          ? chartTabIndex
          : homeTabIndex;
    } catch (_) {
      return homeTabIndex;
    }
  }

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(
  HomeTabNotifier.new,
);
