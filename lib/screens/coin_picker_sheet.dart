import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../providers/auth_provider.dart';
import '../providers/coin_list_provider.dart';
import '../providers/live_tickers_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/stable_pairs.dart';
import '../widgets/coin_list_item.dart';
import 'auth_screen.dart';

/// Opens the near-full-screen coin picker. Picking a coin updates
/// [selectedCoinProvider] and closes the sheet.
Future<void> showCoinPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        const FractionallySizedBox(heightFactor: 0.92, child: _CoinPicker()),
  );
}

class _CoinPicker extends ConsumerStatefulWidget {
  const _CoinPicker();

  @override
  ConsumerState<_CoinPicker> createState() => _CoinPickerState();
}

class _CoinPickerState extends ConsumerState<_CoinPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  Timer? _tickerTimer;

  static const _marketTypes = ['spot', 'futures', 'favorites'];

  @override
  void initState() {
    super.initState();
    final current = ref.read(selectedCoinProvider).value?.marketType;
    _tabController = TabController(
      length: _marketTypes.length,
      vsync: this,
      initialIndex: current == 'futures' ? 1 : 0,
    );
    // Keep the live price state alive while the picker is open.
    ref.listenManual(liveTickersProvider, (_, _) {});
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _refreshTickers();
    });
    _refreshTickers();
    _tickerTimer = Timer.periodic(
      tickerRefreshInterval,
      (_) => _refreshTickers(),
    );
  }

  /// Fetches live prices for the markets visible in the current tab.
  void _refreshTickers() {
    final tab = _marketTypes[_tabController.index];
    final markets = tab == 'favorites' ? const ['spot', 'futures'] : [tab];
    ref.read(liveTickersProvider.notifier).refresh(markets);
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Spot'),
              const Tab(text: 'Futures'),
              Tab(text: l10n.favoritesTab),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchSymbol,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toUpperCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _marketTypes
                  .map(
                    (m) => m == 'favorites'
                        ? _FavoritesList(searchQuery: _searchQuery)
                        : _CoinList(marketType: m, searchQuery: _searchQuery),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinList extends ConsumerWidget {
  final String marketType;
  final String searchQuery;

  const _CoinList({required this.marketType, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsAsync = ref.watch(coinListProvider(marketType));
    final l10n = AppLocalizations.of(context)!;

    return coinsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorOccurred('$error'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(coinListProvider(marketType)),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (coins) {
        final filtered = coins
            .where((c) => !isStablePair(c.symbol))
            .where((c) => searchQuery.isEmpty || c.symbol.contains(searchQuery))
            .toList();

        // Highest 24h volume first; coins without volume data go last.
        filtered.sort((a, b) {
          if (a.volume24h == null && b.volume24h == null) return 0;
          if (a.volume24h == null) return 1;
          if (b.volume24h == null) return -1;
          return b.volume24h!.compareTo(a.volume24h!);
        });

        if (filtered.isEmpty) {
          return Center(child: Text(l10n.noCoinsFound));
        }

        return _CoinListView(coins: filtered);
      },
    );
  }
}

class _CoinListView extends ConsumerWidget {
  final List<Coin> coins;

  const _CoinListView({required this.coins});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickers = ref.watch(liveTickersProvider);
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: coins.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final server = coins[index];
        final coin = applyQuote(
          server,
          tickers[server.marketType]?[server.symbol],
        );
        return CoinListItem(
          coin: coin,
          onTap: () {
            ref.read(selectedCoinProvider.notifier).select(coin);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

/// Watchlist coins (spot and futures together); search and the stable-pair
/// filter apply here as well.
class _FavoritesList extends ConsumerWidget {
  final String searchQuery;

  const _FavoritesList({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);

    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.favoritesLoginHint, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => openAuthScreen(context),
                child: Text(l10n.logIn),
              ),
            ],
          ),
        ),
      );
    }

    final async = ref.watch(watchlistProvider);
    return async.when(
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
          return Center(child: Text(l10n.favoritesEmpty));
        }
        final filtered = coins
            .where((c) => !isStablePair(c.symbol))
            .where((c) => searchQuery.isEmpty || c.symbol.contains(searchQuery))
            .toList();
        if (filtered.isEmpty) {
          return Center(child: Text(l10n.noCoinsFound));
        }
        return _CoinListView(coins: filtered);
      },
    );
  }
}
