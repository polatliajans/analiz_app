import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_logic.dart';
import '../ads/banner_ad_slot.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../providers/home_tab_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/coin_list_item.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myWatchlist)),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, ref, watchlistAsync, l10n)),
          const BannerAdSlot(
            placementKey: AdPlacementKeys.bannerWatchlist,
            tabIndex: watchlistTabIndex,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Coin>> watchlistAsync,
    AppLocalizations l10n,
  ) {
    return watchlistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorOccurred('$error'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(watchlistProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (coins) {
        if (coins.isEmpty) {
          return Center(child: Text(l10n.watchlistEmpty));
        }
        return ListView.separated(
          itemCount: coins.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final coin = coins[index];
            return CoinListItem(
              coin: coin,
              onTap: () {
                ref.read(selectedCoinProvider.notifier).select(coin);
                ref.read(homeTabProvider.notifier).select(chartTabIndex);
                // When opened from the profile page, return to the shell.
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            );
          },
        );
      },
    );
  }
}
