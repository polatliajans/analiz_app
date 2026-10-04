import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coin.dart';
import 'coin_list_provider.dart';
import 'locale_provider.dart';

const lastCoinSymbolKey = 'last_coin_symbol';
const lastCoinMarketKey = 'last_coin_market';
const lastTimeframeKey = 'last_timeframe';

const defaultSymbol = 'BTCUSDT';
const defaultMarketType = 'spot';
const chartTimeframes = ['15m', '1h', '4h', '1d'];
const defaultTimeframe = '1h';

/// The coin shown on the chart tab. Restored from the last session; falls
/// back to BTCUSDT spot, then to the highest-volume spot coin.
class SelectedCoinNotifier extends AsyncNotifier<Coin?> {
  Coin? _picked;

  @override
  Future<Coin?> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final symbol = prefs.getString(lastCoinSymbolKey);
    final market = prefs.getString(lastCoinMarketKey);

    Coin? found;
    if (symbol != null && market != null) {
      found = _bySymbol(await _load(market), symbol);
    }
    if (found == null) {
      final spot = await _load(defaultMarketType);
      found = _bySymbol(spot, defaultSymbol) ?? _topByVolume(spot);
    }
    // A coin picked while the list was still loading wins.
    return _picked ?? found;
  }

  Future<List<Coin>> _load(String market) =>
      ref.read(coinListProvider(market).future);

  static Coin? _bySymbol(List<Coin> coins, String symbol) {
    for (final c in coins) {
      if (c.symbol == symbol) return c;
    }
    return null;
  }

  static Coin? _topByVolume(List<Coin> coins) {
    Coin? best;
    for (final c in coins) {
      if (best == null || (c.volume24h ?? -1) > (best.volume24h ?? -1)) {
        best = c;
      }
    }
    return best;
  }

  Future<void> select(Coin coin) async {
    _picked = coin;
    state = AsyncData(coin);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(lastCoinSymbolKey, coin.symbol);
    await prefs.setString(lastCoinMarketKey, coin.marketType);
  }
}

final selectedCoinProvider =
    AsyncNotifierProvider<SelectedCoinNotifier, Coin?>(
      SelectedCoinNotifier.new,
    );

class TimeframeNotifier extends Notifier<String> {
  @override
  String build() {
    final saved = ref.read(sharedPreferencesProvider).getString(
      lastTimeframeKey,
    );
    return chartTimeframes.contains(saved) ? saved! : defaultTimeframe;
  }

  Future<void> select(String timeframe) async {
    state = timeframe;
    await ref
        .read(sharedPreferencesProvider)
        .setString(lastTimeframeKey, timeframe);
  }
}

final timeframeProvider = NotifierProvider<TimeframeNotifier, String>(
  TimeframeNotifier.new,
);
