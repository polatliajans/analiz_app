import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_logic.dart';
import '../ads/banner_ad_slot.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../providers/home_tab_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/watchlist_row.dart';

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
        Future<void> refresh() async {
          ref.invalidate(watchlistProvider);
          ref.invalidate(priceAlertsProvider);
          try {
            await ref.read(watchlistProvider.future);
          } catch (_) {}
        }

        if (coins.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: _EmptyState(l10n: l10n),
                ),
              ),
            ),
          );
        }
        final alertCoinIds = <int>{
          for (final a in ref.watch(priceAlertsProvider).value?.active ?? [])
            a.coinId,
        };
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: coins.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final coin = coins[index];
              return WatchlistRow(
                coin: coin,
                hasAlert: alertCoinIds.contains(coin.id),
                onTap: () {
                  ref.read(selectedCoinProvider.notifier).select(coin);
                  ref.read(homeTabProvider.notifier).select(chartTabIndex);
                  // When opened from the profile page, return to the shell.
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 56, color: muted),
          const SizedBox(height: 16),
          Text(
            l10n.watchlistEmpty,
            key: const Key('watchlist-empty'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.watchlistEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
