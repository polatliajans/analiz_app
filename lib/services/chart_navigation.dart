import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coin.dart';
import '../providers/coin_list_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../utils/timeframes.dart';

/// Opens the Chart tab for a coin (and optionally a timeframe) from any other
/// tab. The chart tab already follows [selectedCoinProvider] and
/// [timeframeProvider] (both persisted), so this only has to set them and flip
/// [homeTabProvider].
Future<void> openChartFor(
  WidgetRef ref, {
  int? coinId,
  required String symbol,
  String marketType = 'spot',
  String? timeframe,
}) async {
  final tabs = ref.read(homeTabProvider.notifier);
  final selected = ref.read(selectedCoinProvider.notifier);
  final timeframes = ref.read(timeframeProvider.notifier);

  if (timeframe != null && chartTimeframes.contains(timeframe)) {
    unawaited(timeframes.select(timeframe));
  }

  Coin? coin;
  try {
    final coins = await ref
        .read(coinListProvider(marketType).future)
        .timeout(const Duration(seconds: 3));
    for (final c in coins) {
      if (c.symbol == symbol) {
        coin = c;
        break;
      }
    }
  } catch (_) {
    // Coin list unavailable: fall back to a bare coin below.
  }
  coin ??= Coin(
    id: coinId ?? 0,
    symbol: symbol,
    name: symbol,
    marketType: marketType,
    lastPrice: null,
    priceChangePercent24h: null,
    volume24h: null,
  );
  unawaited(selected.select(coin));
  tabs.select(chartTabIndex);
}
