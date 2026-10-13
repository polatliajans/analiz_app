import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/data/ticker_api.dart';
import 'package:kriptoanaliz/models/coin.dart';

void main() {
  test('parseTickerMap maps symbol to price and percent', () {
    const body =
        '[{"symbol":"BTCUSDT","lastPrice":"65000.10","priceChangePercent":"-1.25"},'
        '{"symbol":"ETHUSDT","lastPrice":"3000","priceChangePercent":"2"}]';
    final map = parseTickerMap(body);
    expect(map.length, 2);
    expect(map['BTCUSDT']!.lastPrice, 65000.10);
    expect(map['BTCUSDT']!.changePercent, -1.25);
    expect(map['ETHUSDT']!.changePercent, 2);
  });

  test('parseTickerMap skips malformed rows and bad payloads', () {
    expect(
      parseTickerMap(
        '[{"symbol":"A","lastPrice":"x","priceChangePercent":"1"},{"foo":1},'
        '{"symbol":"B","lastPrice":"1","priceChangePercent":"0"}]',
      ).keys,
      ['B'],
    );
    expect(parseTickerMap('{"code":-1}'), isEmpty);
    expect(parseTickerMap('garbage'), isEmpty);
  });

  test('applyTickers overrides price/percent only where a ticker exists', () {
    const a = Coin(
      id: 1,
      symbol: 'AAA',
      name: 'a',
      marketType: 'spot',
      lastPrice: 1,
      priceChangePercent24h: 1,
      volume24h: 7,
    );
    final b = Coin(
      id: 2,
      symbol: 'BBB',
      name: 'b',
      marketType: 'spot',
      lastPrice: 2,
      priceChangePercent24h: 2,
      volume24h: 8,
    );
    final out = applyTickers(
      [a, b],
      {'AAA': const TickerQuote(lastPrice: 10, changePercent: -3)},
    );
    expect(out[0].lastPrice, 10);
    expect(out[0].priceChangePercent24h, -3);
    expect(out[0].volume24h, 7);
    expect(out[1], same(b));
  });
}
