import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_list_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../utils/stable_pairs.dart';
import '../widgets/coin_list_item.dart';

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

  static const _marketTypes = ['spot', 'futures'];

  @override
  void initState() {
    super.initState();
    final current = ref.read(selectedCoinProvider).value?.marketType;
    _tabController = TabController(
      length: _marketTypes.length,
      vsync: this,
      initialIndex: current == 'futures' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Spot'),
            Tab(text: 'Futures'),
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
                  (m) => _CoinList(marketType: m, searchQuery: _searchQuery),
                )
                .toList(),
          ),
        ),
      ],
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

        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final coin = filtered[index];
            return CoinListItem(
              coin: coin,
              onTap: () {
                ref.read(selectedCoinProvider.notifier).select(coin);
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}
