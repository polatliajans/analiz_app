import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/home_tab_provider.dart';
import 'account_screen.dart';
import 'chart_screen.dart';
import 'radar_screen.dart';
import 'watchlist_screen.dart';

/// App home: bottom navigation with Chart, Radar, Watchlist and Profile tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          ChartScreen(),
          RadarScreen(),
          WatchlistScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: ref.read(homeTabProvider.notifier).select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.candlestick_chart_outlined),
            selectedIcon: const Icon(Icons.candlestick_chart),
            label: l10n.tabChart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.radar_outlined),
            selectedIcon: const Icon(Icons.radar),
            label: l10n.radar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: const Icon(Icons.star),
            label: l10n.tabWatchlist,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
