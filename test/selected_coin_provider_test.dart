import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kriptoanaliz/data/coin_api.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';

Coin _coin(int id, String symbol, String market, [double? volume]) => Coin(
  id: id,
  symbol: symbol,
  name: symbol,
  marketType: market,
  lastPrice: 1,
  priceChangePercent24h: 0,
  volume24h: volume,
);

class _FakeCoinApi extends CoinApi {
  final Map<String, List<Coin>> data;
  _FakeCoinApi(this.data);

  @override
  Future<List<Coin>> fetchCoins({String? marketType}) async =>
      data[marketType] ?? [];
}

Future<ProviderContainer> _container(
  Map<String, Object> prefsInit,
  Map<String, List<Coin>> coins,
) async {
  SharedPreferences.setMockInitialValues(prefsInit);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      coinApiProvider.overrideWithValue(_FakeCoinApi(coins)),
    ],
  );
}

void main() {
  final spot = [
    _coin(1, 'ETHUSDT', 'spot', 500),
    _coin(2, 'BTCUSDT', 'spot', 100),
  ];
  final futures = [_coin(10, 'SOLUSDT', 'futures', 50)];

  test('first launch defaults to BTCUSDT spot', () async {
    final c = await _container({}, {'spot': spot, 'futures': futures});
    addTearDown(c.dispose);
    final coin = await c.read(selectedCoinProvider.future);
    expect(coin?.symbol, 'BTCUSDT');
  });

  test('falls back to highest-volume spot coin when BTCUSDT missing', () async {
    final c = await _container({}, {
      'spot': [spot[0], _coin(3, 'XRPUSDT', 'spot', 10)],
    });
    addTearDown(c.dispose);
    expect((await c.read(selectedCoinProvider.future))?.symbol, 'ETHUSDT');
  });

  test('restores the saved coin', () async {
    final c = await _container(
      {lastCoinSymbolKey: 'SOLUSDT', lastCoinMarketKey: 'futures'},
      {'spot': spot, 'futures': futures},
    );
    addTearDown(c.dispose);
    final coin = await c.read(selectedCoinProvider.future);
    expect(coin?.symbol, 'SOLUSDT');
    expect(coin?.marketType, 'futures');
  });

  test('saved coin no longer listed falls back to default', () async {
    final c = await _container(
      {lastCoinSymbolKey: 'GONEUSDT', lastCoinMarketKey: 'futures'},
      {'spot': spot, 'futures': futures},
    );
    addTearDown(c.dispose);
    expect((await c.read(selectedCoinProvider.future))?.symbol, 'BTCUSDT');
  });

  test('select() updates state and persists', () async {
    final c = await _container({}, {'spot': spot, 'futures': futures});
    addTearDown(c.dispose);
    await c.read(selectedCoinProvider.future);
    await c.read(selectedCoinProvider.notifier).select(futures[0]);
    expect(c.read(selectedCoinProvider).value?.symbol, 'SOLUSDT');
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString(lastCoinSymbolKey), 'SOLUSDT');
    expect(prefs.getString(lastCoinMarketKey), 'futures');
  });

  test('timeframe defaults to 1h, persists and restores', () async {
    final c = await _container({}, {});
    addTearDown(c.dispose);
    expect(c.read(timeframeProvider), '1h');
    await c.read(timeframeProvider.notifier).select('4h');
    expect(c.read(timeframeProvider), '4h');
    expect(c.read(sharedPreferencesProvider).getString(lastTimeframeKey), '4h');

    final c2 = await _container({lastTimeframeKey: '1d'}, {});
    addTearDown(c2.dispose);
    expect(c2.read(timeframeProvider), '1d');
    final c3 = await _container({lastTimeframeKey: 'bogus'}, {});
    addTearDown(c3.dispose);
    expect(c3.read(timeframeProvider), '1h');
  });
}
