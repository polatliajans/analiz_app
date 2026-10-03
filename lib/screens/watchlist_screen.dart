import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/watchlist_provider.dart';
import '../widgets/coin_list_item.dart';
import 'chart_screen.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Takip Listem')),
      body: watchlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bir hata oluştu: $error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(watchlistProvider),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (coins) {
          if (coins.isEmpty) {
            return const Center(
              child: Text('Henüz takip ettiğin bir coin yok'),
            );
          }
          return ListView.separated(
            itemCount: coins.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final coin = coins[index];
              return CoinListItem(
                coin: coin,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChartScreen(coin: coin)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
