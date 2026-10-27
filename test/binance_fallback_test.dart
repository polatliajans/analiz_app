import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kriptoanaliz/data/binance_hosts.dart';
import 'package:kriptoanaliz/data/binance_klines_api.dart';
import 'package:kriptoanaliz/data/kline_stream.dart';
import 'package:kriptoanaliz/data/ticker_api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _klines = '[[1700000000000,"1","2","0.5","1.5","10",1700000059999]]';
const _tickers =
    '[{"symbol":"BTCUSDT","lastPrice":"10","priceChangePercent":"1"}]';

/// Answers per host; records the hosts that were called.
class _Fake {
  final Map<String, Object> byHost; // int status, Exception, or Future
  final calls = <String>[];
  _Fake(this.byHost);

  MockClient get client => MockClient((req) async {
    calls.add(req.url.host);
    final r = byHost[req.url.host];
    if (r is Exception) throw r;
    if (r is int) return http.Response(r == 200 ? _klines : 'err', r);
    return http.Response('missing', 404);
  });
}

void main() {
  group('klines REST', () {
    test('primary ok: no fallback call', () async {
      final f = _Fake({'api.binance.com': 200});
      final c = await BinanceKlinesApi(
        client: f.client,
        hostState: BinanceHostState(),
      ).fetchKlines(symbol: 'BTCUSDT', marketType: 'spot', timeframe: '1h');
      expect(c, hasLength(1));
      expect(f.calls, ['api.binance.com']);
    });

    for (final status in [451, 403, 503]) {
      test(
        '$status on primary falls back to data-api.binance.vision',
        () async {
          final f = _Fake({
            'api.binance.com': status,
            'data-api.binance.vision': 200,
          });
          final c = await BinanceKlinesApi(
            client: f.client,
            hostState: BinanceHostState(),
          ).fetchKlines(symbol: 'BTCUSDT', marketType: 'spot', timeframe: '1h');
          expect(c, hasLength(1));
          expect(f.calls, ['api.binance.com', 'data-api.binance.vision']);
        },
      );
    }

    test(
      'connection failure falls back; later calls go to fallback first',
      () async {
        final state = BinanceHostState();
        final f = _Fake({
          'api.binance.com': http.ClientException('boom'),
          'data-api.binance.vision': 200,
        });
        final api = BinanceKlinesApi(client: f.client, hostState: state);
        await api.fetchKlines(
          symbol: 'BTCUSDT',
          marketType: 'spot',
          timeframe: '1h',
        );
        f.calls.clear();
        await api.fetchKlines(
          symbol: 'BTCUSDT',
          marketType: 'spot',
          timeframe: '1h',
        );
        expect(f.calls, ['data-api.binance.vision']);
      },
    );

    test('primary is retried after the sticky window', () async {
      var now = DateTime(2026);
      final state = BinanceHostState(
        retryPrimaryAfter: const Duration(minutes: 1),
        clock: () => now,
      );
      state.markPrimaryFailed();
      expect(state.useFallbackFirst, isTrue);
      now = now.add(const Duration(minutes: 2));
      expect(state.useFallbackFirst, isFalse);
    });

    test('both hosts blocked: throws ChartDataException', () async {
      final f = _Fake({'api.binance.com': 451, 'data-api.binance.vision': 451});
      expect(
        () => BinanceKlinesApi(
          client: f.client,
          hostState: BinanceHostState(),
        ).fetchKlines(symbol: 'BTCUSDT', marketType: 'spot', timeframe: '1h'),
        throwsA(isA<ChartDataException>()),
      );
    });

    test('a real 400 is not retried on another host', () async {
      final f = _Fake({'api.binance.com': 400});
      await expectLater(
        BinanceKlinesApi(
          client: f.client,
          hostState: BinanceHostState(),
        ).fetchKlines(symbol: 'X', marketType: 'spot', timeframe: '1h'),
        throwsA(isA<ChartDataException>()),
      );
      expect(f.calls, ['api.binance.com']);
    });

    test('futures has no fallback host and fails with a clean error', () async {
      final f = _Fake({'fapi.binance.com': 451});
      await expectLater(
        BinanceKlinesApi(
          client: f.client,
          hostState: BinanceHostState(),
        ).fetchKlines(
          symbol: 'BTCUSDT',
          marketType: 'futures',
          timeframe: '1h',
        ),
        throwsA(isA<ChartDataException>()),
      );
      expect(f.calls, ['fapi.binance.com']);
    });
  });

  group('ticker REST', () {
    test('spot falls back on 451', () async {
      final calls = <String>[];
      final client = MockClient((req) async {
        calls.add(req.url.host);
        return req.url.host == 'api.binance.com'
            ? http.Response('x', 451)
            : http.Response(_tickers, 200);
      });
      final q = await TickerApi(
        client: client,
        hostState: BinanceHostState(),
      ).fetchAll('spot');
      expect(q['BTCUSDT']!.lastPrice, 10);
      expect(calls, ['api.binance.com', 'data-api.binance.vision']);
    });

    test('futures failure throws (callers keep server values)', () async {
      final client = MockClient((req) async => http.Response('x', 451));
      expect(
        TickerApi(client: client).fetchAll('futures'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('stream URIs', () {
    test('spot primary and fallback hosts', () {
      final a = klineStreamUri(
        marketType: 'spot',
        symbol: 'BTCUSDT',
        timeframe: '1m',
      );
      expect(a.host, 'stream.binance.com');
      final b = klineStreamUri(
        marketType: 'spot',
        symbol: 'BTCUSDT',
        timeframe: '1m',
        useFallback: true,
      );
      expect(b.host, 'data-stream.binance.vision');
      expect(b.path, '/stream');
      expect(b.query, 'streams=btcusdt@kline_1m/btcusdt@miniTicker');
    });

    test('futures ignores the fallback flag', () {
      final u = klineStreamUri(
        marketType: 'futures',
        symbol: 'BTCUSDT',
        timeframe: '1m',
        useFallback: true,
      );
      expect(u.host, 'fstream.binance.com');
    });
  });

  group('WebSocketKlineStream fallback', () {
    WebSocketChannel okChannel() => _FakeChannel();

    test('primary connect fails -> connects to the vision host', () async {
      final tried = <String>[];
      final stream = WebSocketKlineStream(
        hostState: BinanceHostState(),
        connector: (uri) async {
          tried.add(uri.host);
          if (uri.host == 'stream.binance.com') throw Exception('451');
          return okChannel();
        },
      );
      final sub = stream
          .connect(marketType: 'spot', symbol: 'BTCUSDT', timeframe: '1m')
          .listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(tried, ['stream.binance.com', 'data-stream.binance.vision']);
      await sub.cancel();
    });

    test('all hosts fail -> stream errors and closes, no crash', () async {
      final stream = WebSocketKlineStream(
        hostState: BinanceHostState(),
        connector: (uri) async => throw Exception('down'),
      );
      final errors = <Object>[];
      final done = Completer<void>();
      stream
          .connect(marketType: 'spot', symbol: 'BTCUSDT', timeframe: '1m')
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await done.future.timeout(const Duration(seconds: 2));
      expect(errors, hasLength(1));
    });

    test('futures only tries its own host', () async {
      final tried = <String>[];
      final stream = WebSocketKlineStream(
        hostState: BinanceHostState(),
        connector: (uri) async {
          tried.add(uri.host);
          throw Exception('down');
        },
      );
      final done = Completer<void>();
      stream
          .connect(marketType: 'futures', symbol: 'BTCUSDT', timeframe: '1m')
          .listen((_) {}, onError: (_) {}, onDone: done.complete);
      await done.future.timeout(const Duration(seconds: 2));
      expect(tried, ['fstream.binance.com']);
    });
  });
}

class _FakeChannel implements WebSocketChannel {
  final _ctrl = StreamController<dynamic>.broadcast();

  @override
  Stream<dynamic> get stream => _ctrl.stream;
  @override
  WebSocketSink get sink => _FakeSink();
  @override
  Future<void> get ready => Future.value();
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  String? get protocol => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}
  @override
  void addError(Object error, [StackTrace? st]) {}
  @override
  Future<void> addStream(Stream<dynamic> stream) async {}
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
  @override
  Future<void> get done => Future.value();
}
