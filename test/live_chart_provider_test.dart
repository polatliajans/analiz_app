import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/data/binance_klines_api.dart';
import 'package:kriptoanaliz/data/chart_signal_api.dart';
import 'package:kriptoanaliz/data/kline_stream.dart';
import 'package:kriptoanaliz/models/candle.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/chart_data_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/live_chart_provider.dart';

const _coin = Coin(
  id: 1,
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  marketType: 'spot',
  lastPrice: 1,
  priceChangePercent24h: 0,
  volume24h: 1,
);
const _params = ChartDataParams(coin: _coin, timeframe: '1h');

Candle _c(int t, double close) =>
    Candle(openTime: t, open: 1, high: 9, low: 0, close: close);

KlineUpdate _u(int t, double close) => KlineUpdate(
  openTime: t,
  open: 1,
  high: 9,
  low: 0,
  close: close,
  isClosed: false,
);

class _FakeKlines extends BinanceKlinesApi {
  int calls = 0;
  List<int> limits = [];
  List<Candle> data = [_c(0, 10), _c(60, 11)];

  @override
  Future<List<Candle>> fetchKlines({
    required String symbol,
    required String marketType,
    required String timeframe,
    int limit = 300,
  }) async {
    calls++;
    limits.add(limit);
    return data;
  }
}

class _FakeSignals extends ChartSignalApi {
  int calls = 0;
  bool fail = false;
  String? lastToken;

  @override
  Future<List<ChartSignal>> fetchSignals({
    required int coinId,
    required String timeframe,
    String? token,
  }) async {
    calls++;
    lastToken = token;
    if (fail) throw Exception('x');
    return [
      ChartSignal(candleTime: DateTime.utc(2024), signalType: 'buy'),
      if (token != null)
        ChartSignal(
          candleTime: DateTime.utc(2024, 1, 2),
          signalType: 'sell',
          strength: 3,
        ),
    ];
  }
}

/// Whether new [_Setup]s start with a signed-in free member (guests never
/// request signals).
bool _startSignedIn = true;

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => _startSignedIn
      ? const AuthState(
          token: 't-user',
          member: Member(id: 1, email: 'a@b.c', role: 'user', creditBalance: 0),
        )
      : const AuthState();

  void signIn(String role) => state = AuthState(
    token: 't-$role',
    member: Member(id: 1, email: 'a@b.c', role: role, creditBalance: 0),
  );

  void signOut() => state = const AuthState();
}

class _FakeStream implements KlineStream {
  int connects = 0;
  bool failImmediately = false;
  StreamController<LiveEvent>? current;

  @override
  Stream<LiveEvent> connect({
    required String marketType,
    required String symbol,
    required String timeframe,
  }) {
    connects++;
    final c = StreamController<LiveEvent>();
    current = c;
    if (failImmediately) {
      scheduleMicrotask(() {
        c.addError(Exception('down'));
        c.close();
      });
    }
    return c.stream;
  }
}

class _Setup {
  final klines = _FakeKlines();
  final signals = _FakeSignals();
  final stream = _FakeStream();
  late final ProviderContainer container;

  _Setup({bool signedIn = true}) {
    _startSignedIn = signedIn;
    container = ProviderContainer(
      overrides: [
        binanceKlinesApiProvider.overrideWithValue(klines),
        chartSignalApiProvider.overrideWithValue(signals),
        klineStreamProvider.overrideWithValue(stream),
        authProvider.overrideWith(_FakeAuth.new),
      ],
    );
    // The app now opens on Home; these tests exercise a visible chart tab.
    container.read(homeTabProvider.notifier).select(chartTabIndex);
    container.listen(liveChartProvider(_params), (_, _) {});
  }

  LiveChartState get state => container.read(liveChartProvider(_params));
}

void main() {
  test('mergeSignals replaces same key, keeps others, sorts by time', () {
    final a = ChartSignal(
      candleTime: DateTime.utc(2024, 1, 2),
      signalType: 'buy',
    );
    final old = ChartSignal(
      candleTime: DateTime.utc(2024, 1, 1),
      signalType: 'sell',
    );
    final a2 = ChartSignal(
      candleTime: DateTime.utc(2024, 1, 2),
      signalType: 'buy',
      strength: 3,
    );
    final out = mergeSignals([a, old], [a2]);
    expect(out.length, 2);
    expect(out.first.signalType, 'sell');
    expect(out.last.strength, 3);
  });

  testWidgets('loads history, connects and applies throttled live events', (
    tester,
  ) async {
    final s = _Setup();
    await tester.pump();
    await tester.pump();

    expect(s.state.loading, false);
    expect(s.state.candles.length, 2);
    expect(s.state.price, 11);
    expect(s.stream.connects, 1);
    expect(s.signals.calls, 1);
    expect(s.state.signals.length, 2);

    s.stream.current!.add(_u(60, 12));
    await tester.pump();
    expect(s.state.price, 12);
    expect(s.state.direction, 1);

    // Inside the throttle window the new value is not published yet.
    s.stream.current!.add(_u(60, 5));
    await tester.pump();
    expect(s.state.price, 12);
    await tester.pump(liveUiThrottle);
    expect(s.state.price, 5);
    expect(s.state.direction, -1);

    s.stream.current!.add(
      const TickerUpdate(lastPrice: 110, openPrice24h: 100),
    );
    await tester.pump(liveUiThrottle);
    expect(s.state.change24h, closeTo(10, 1e-9));

    s.stream.current!.add(_u(120, 6));
    await tester.pump(liveUiThrottle);
    expect(s.state.candles.length, 3);
    s.container.dispose();
  });

  testWidgets('refetches signals with the token when the role changes', (
    tester,
  ) async {
    final s = _Setup();
    await tester.pump();
    await tester.pump();
    expect(s.signals.lastToken, 't-user');
    expect(s.state.signals.length, 2);

    final auth = s.container.read(authProvider.notifier) as _FakeAuth;
    auth.signIn('pro');
    await tester.pump();
    await tester.pump();
    expect(s.signals.lastToken, 't-pro');
    expect(s.state.signals.map((x) => x.strength), contains(3));

    final callsSignedIn = s.signals.calls;
    auth.signOut();
    await tester.pump();
    await tester.pump();
    expect(s.signals.calls, callsSignedIn, reason: 'guests never call');
    expect(s.state.signals, isEmpty);
    s.container.dispose();
  });

  testWidgets('guests never request signals', (tester) async {
    final s = _Setup(signedIn: false);
    await tester.pump();
    await tester.pump();
    expect(s.state.candles, isNotEmpty);
    expect(s.signals.calls, 0);
    expect(s.state.signals, isEmpty);
    await tester.pump(signalRefreshInterval);
    expect(s.signals.calls, 0);
    s.container.dispose();
  });

  testWidgets('closes the stream when the chart tab is hidden, reopens later', (
    tester,
  ) async {
    final s = _Setup();
    await tester.pump();
    await tester.pump();
    expect(s.stream.current!.hasListener, true);
    final callsBefore = s.klines.calls;

    s.container.read(homeTabProvider.notifier).select(radarTabIndex);
    await tester.pump();
    expect(s.stream.current!.hasListener, false);

    s.container.read(homeTabProvider.notifier).select(chartTabIndex);
    await tester.pump();
    await tester.pump();
    expect(s.stream.connects, 2);
    expect(s.stream.current!.hasListener, true);
    expect(s.klines.calls, callsBefore + 1);
    s.container.dispose();
  });

  testWidgets('falls back to REST polling after repeated failures', (
    tester,
  ) async {
    final s = _Setup();
    s.stream.failImmediately = true;
    await tester.pump();
    await tester.pump();
    expect(s.state.polling, false);

    await tester.pump(const Duration(seconds: 1)); // 2nd attempt fails
    await tester.pump(const Duration(seconds: 2)); // 3rd attempt fails
    await tester.pump();
    expect(s.stream.connects, 3);
    expect(s.state.polling, true);

    s.klines.limits.clear();
    s.klines.data = [_c(60, 13), _c(120, 14)];
    await tester.pump(pollingInterval);
    await tester.pump(liveUiThrottle);
    expect(s.klines.limits, contains(2));
    expect(s.state.price, 14);
    expect(s.state.candles.last.openTime, 120);

    // The socket comes back: polling stops once a message arrives.
    s.stream.failImmediately = false;
    final before = s.stream.connects;
    while (s.stream.connects == before) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();
    s.stream.current!.add(_u(120, 15));
    await tester.pump(liveUiThrottle);
    await tester.pump(liveUiThrottle);
    expect(s.state.polling, false);
    expect(s.state.price, 15);
    s.container.dispose();
  });

  testWidgets('failed signal refresh keeps old signals', (tester) async {
    final s = _Setup();
    await tester.pump();
    await tester.pump();
    expect(s.signals.calls, 1);

    s.signals.fail = true;
    await tester.pump(signalRefreshInterval);
    expect(s.signals.calls, 2);
    expect(s.state.signals.length, 2);
    s.container.dispose();
  });
}
