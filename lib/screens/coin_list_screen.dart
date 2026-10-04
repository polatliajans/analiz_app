import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_list_provider.dart';
import '../widgets/coin_list_item.dart';
import '../widgets/email_verification_banner.dart';
import 'account_screen.dart';
import 'chart_screen.dart';
import 'radar_screen.dart';
import 'settings_screen.dart';

class CoinListScreen extends ConsumerStatefulWidget {
  const CoinListScreen({super.key});

  @override
  ConsumerState<CoinListScreen> createState() => _CoinListScreenState();
}

class _CoinListScreenState extends ConsumerState<CoinListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  static const _marketTypes = ['spot', 'futures'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _marketTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coins),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar),
            tooltip: l10n.radar,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RadarScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Spot'),
            Tab(text: 'Futures'),
          ],
        ),
      ),
      body: Column(
        children: [
          const EmailVerificationBanner(),
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
                    (marketType) => _CoinList(
                      marketType: marketType,
                      searchQuery: _searchQuery,
                    ),
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
        final filtered = searchQuery.isEmpty
            ? coins.toList()
            : coins.where((c) => c.symbol.contains(searchQuery)).toList();

        // Default sort: highest 24h volume first. Coins without volume data
        // yet (not synced) sort to the end.
        filtered.sort((a, b) {
          if (a.volume24h == null && b.volume24h == null) return 0;
          if (a.volume24h == null) return 1;
          if (b.volume24h == null) return -1;
          return b.volume24h!.compareTo(a.volume24h!);
        });

        if (filtered.isEmpty) {
          return Center(child: Text(l10n.noCoinsFound));
        }

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final coin = filtered[index];
            return CoinListItem(
              coin: coin,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChartScreen(coin: coin)),
                );
              },
            );
          },
        );
      },
    );
  }
}
