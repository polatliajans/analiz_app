import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/data/kline_stream.dart';
import 'package:kriptoanaliz/models/candle.dart';

Candle _c(int t, double o, double h, double l, double c) =>
    Candle(openTime: t, open: o, high: h, low: l, close: c);

KlineUpdate _u(int t, double c, {bool closed = false}) => KlineUpdate(
  openTime: t,
  open: 1,
  high: 9,
  low: 0.5,
  close: c,
  isClosed: closed,
);

void main() {
  group('parseKlineMessage', () {
    test('parses combined-stream envelope', () {
      const raw =
          '{"stream":"btcusdt@kline_1m","data":{"e":"kline","k":{"t":1700000000000,'
          '"o":"10.5","h":"11","l":"10","c":"10.8","v":"3","x":false}}}';
      final u = parseKlineMessage(raw)!;
      expect(u.openTime, 1700000000000);
      expect(u.open, 10.5);
      expect(u.high, 11);
      expect(u.low, 10);
      expect(u.close, 10.8);
      expect(u.isClosed, false);
    });

    test('parses bare event and closed flag', () {
      const raw =
          '{"e":"kline","k":{"t":5,"o":"1","h":"2","l":"0.5","c":"1.5","x":true}}';
      expect(parseKlineMessage(raw)!.isClosed, true);
    });

    test('returns null for other events, garbage and malformed kline', () {
      expect(
        parseKlineMessage(
          '{"stream":"x@miniTicker","data":{"e":"24hrMiniTicker","c":"1","o":"1"}}',
        ),
        isNull,
      );
      expect(parseKlineMessage('not json'), isNull);
      expect(parseKlineMessage('[1,2]'), isNull);
      expect(
        parseKlineMessage('{"data":{"e":"kline","k":{"t":1,"o":"x"}}}'),
        isNull,
      );
    });
  });

  group('parseMiniTickerMessage', () {
    test('parses envelope and computes change percent', () {
      const raw =
          '{"stream":"btcusdt@miniTicker","data":{"e":"24hrMiniTicker","c":"110","o":"100"}}';
      final t = parseMiniTickerMessage(raw)!;
      expect(t.lastPrice, 110);
      expect(t.openPrice24h, 100);
      expect(t.changePercent, closeTo(10, 1e-9));
    });

    test('zero open gives null change; non ticker gives null', () {
      const raw = '{"e":"24hrMiniTicker","c":"5","o":"0"}';
      expect(parseMiniTickerMessage(raw)!.changePercent, isNull);
      expect(parseMiniTickerMessage('{"e":"kline"}'), isNull);
      expect(parseMiniTickerMessage('oops'), isNull);
    });
  });

  group('applyKlineUpdate', () {
    final base = [_c(0, 1, 2, 1, 1.5), _c(60, 1.5, 2, 1, 1.8)];

    test('updates the last candle in place without mutating input', () {
      final out = applyKlineUpdate(base, _u(60, 1.9));
      expect(out.length, 2);
      expect(out.last.close, 1.9);
      expect(out.last.high, 9);
      expect(base.last.close, 1.8);
    });

    test('appends a newer candle', () {
      final out = applyKlineUpdate(base, _u(120, 2.2));
      expect(out.length, 3);
      expect(out.last.openTime, 120);
    });

    test('closing update keeps list shape', () {
      final out = applyKlineUpdate(base, _u(60, 1.7, closed: true));
      expect(out.length, 2);
      expect(out.last.close, 1.7);
    });

    test('out-of-order update replaces matching older candle', () {
      final out = applyKlineUpdate(base, _u(0, 1.1));
      expect(out.length, 2);
      expect(out.first.close, 1.1);
      expect(out.last.close, 1.8);
    });

    test('out-of-order update with unknown time is ignored', () {
      final out = applyKlineUpdate(base, _u(30, 1.1));
      expect(out.length, 2);
      expect(out.map((c) => c.openTime), [0, 60]);
    });

    test('empty list gets the candle', () {
      expect(applyKlineUpdate(const [], _u(5, 1)).length, 1);
    });

    test('caps list length by dropping the oldest', () {
      final big = [for (var i = 0; i < maxLiveCandles; i++) _c(i, 1, 1, 1, 1)];
      final out = applyKlineUpdate(big, _u(maxLiveCandles, 2));
      expect(out.length, maxLiveCandles);
      expect(out.first.openTime, 1);
      expect(out.last.openTime, maxLiveCandles);
    });
  });

  group('nextBackoff', () {
    test('doubles from 1s and caps at 15s', () {
      expect(
        [for (var i = 0; i < 7; i++) nextBackoff(i).inSeconds],
        [1, 2, 4, 8, 15, 15, 15],
      );
    });

    test('handles negative and huge attempts', () {
      expect(nextBackoff(-3), const Duration(seconds: 1));
      expect(nextBackoff(1000), const Duration(seconds: 15));
    });
  });

  group('streamUrl', () {
    test('spot and futures hosts, lowercase symbol', () {
      expect(
        klineStreamUri(
          marketType: 'spot',
          symbol: 'BTCUSDT',
          timeframe: '1m',
        ).toString(),
        'wss://stream.binance.com:9443/stream?streams=btcusdt@kline_1m/btcusdt@miniTicker',
      );
      expect(
        klineStreamUri(
          marketType: 'futures',
          symbol: 'ETHUSDT',
          timeframe: '1w',
        ).toString(),
        'wss://fstream.binance.com/market/stream?streams=ethusdt@kline_1w/ethusdt@miniTicker',
      );
    });
  });
}
