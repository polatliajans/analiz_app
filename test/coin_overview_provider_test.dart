import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kriptoanaliz/data/coin_overview_api.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/coin_overview_provider.dart';

import 'coin_overview_model_test.dart' show fullOverviewJson;

class FakeOverviewApi extends CoinOverviewApi {
  int calls = 0;
  final List<int> coinIds = [];
  String? lastToken;
  Future<CoinOverview> Function(int call) handler;

  FakeOverviewApi(this.handler);

  @override
  Future<CoinOverview> fetch(int coinId, {String? token}) {
    calls++;
    coinIds.add(coinId);
    lastToken = token;
    return handler(calls);
  }
}

class _Clock {
  DateTime now = DateTime.utc(2026, 10, 21, 10);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

class _NoAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

({ProviderContainer container, FakeOverviewApi api, _Clock clock}) _setup(
  Future<CoinOverview> Function(int call) handler,
) {
  final api = FakeOverviewApi(handler);
  final clock = _Clock();
  final container = ProviderContainer(
    overrides: [
      coinOverviewApiProvider.overrideWithValue(api),
      overviewClockProvider.overrideWithValue(clock.call),
      authProvider.overrideWith(_NoAuth.new),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, api: api, clock: clock);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final data = CoinOverview.parse(fullOverviewJson());

  test('first read loads once and exposes the data', () async {
    final s = _setup((_) async => data);
    final sub = s.container.listen(coinOverviewProvider(1), (_, _) {});
    expect(sub.read().isInitialLoading, isTrue);
    await _settle();
    await _settle();
    final st = sub.read();
    expect(st.loading, isFalse);
    expect(st.data, same(data));
    expect(st.error, isNull);
    expect(s.api.calls, 1);
    expect(s.api.coinIds, [1]);
  });

  test(
    'cache: reads inside the TTL do not refetch, after it they do',
    () async {
      final s = _setup((_) async => data);
      final sub = s.container.listen(coinOverviewProvider(1), (_, _) {});
      await _settle();
      await _settle();
      final notifier = s.container.read(coinOverviewProvider(1).notifier);

      s.clock.advance(const Duration(minutes: 2, seconds: 59));
      await notifier.load();
      expect(s.api.calls, 1, reason: 'still fresh');

      s.clock.advance(const Duration(seconds: 2));
      await notifier.load();
      expect(s.api.calls, 2, reason: 'older than 3 minutes');
      expect(sub.read().fetchedAt, s.clock.now);
    },
  );

  test(
    'force refresh ignores the cache; concurrent loads share a request',
    () async {
      final gate = Completer<CoinOverview>();
      final s = _setup((call) => call == 1 ? Future.value(data) : gate.future);
      s.container.listen(coinOverviewProvider(1), (_, _) {});
      await _settle();
      await _settle();
      final notifier = s.container.read(coinOverviewProvider(1).notifier);

      final a = notifier.load(force: true);
      final b = notifier.load(force: true);
      final c = notifier.load();
      expect(s.api.calls, 2, reason: 'one extra request, shared');
      // Data stays visible while refreshing.
      expect(s.container.read(coinOverviewProvider(1)).data, same(data));
      expect(s.container.read(coinOverviewProvider(1)).loading, isTrue);
      gate.complete(CoinOverview.empty);
      await Future.wait([a, b, c]);
      expect(
        s.container.read(coinOverviewProvider(1)).data,
        same(CoinOverview.empty),
      );
    },
  );

  test('error without data is fatal and retry recovers', () async {
    final s = _setup(
      (call) => call == 1
          ? Future<CoinOverview>.error(Exception('boom'))
          : Future.value(data),
    );
    final sub = s.container.listen(coinOverviewProvider(1), (_, _) {});
    await _settle();
    await _settle();
    expect(sub.read().isFatalError, isTrue);
    expect(sub.read().hasData, isFalse);

    await s.container.read(coinOverviewProvider(1).notifier).retry();
    expect(sub.read().isFatalError, isFalse);
    expect(sub.read().data, same(data));
    expect(s.api.calls, 2);
  });

  test('failed refresh keeps the previous data as stale', () async {
    final s = _setup(
      (call) =>
          call == 1 ? Future.value(data) : Future<CoinOverview>.error('down'),
    );
    final sub = s.container.listen(coinOverviewProvider(1), (_, _) {});
    await _settle();
    await _settle();
    await s.container.read(coinOverviewProvider(1).notifier).load(force: true);
    final st = sub.read();
    expect(st.isStale, isTrue);
    expect(st.isFatalError, isFalse);
    expect(st.data, same(data));
    expect(st.error, isNotNull);

    // A later successful refresh clears the error.
    s.api.handler = (_) async => CoinOverview.empty;
    await s.container.read(coinOverviewProvider(1).notifier).retry();
    expect(sub.read().isStale, isFalse);
    expect(sub.read().data, same(CoinOverview.empty));
  });

  test('coins are cached independently', () async {
    final s = _setup((_) async => data);
    s.container.listen(coinOverviewProvider(1), (_, _) {});
    s.container.listen(coinOverviewProvider(2), (_, _) {});
    await _settle();
    await _settle();
    expect(s.api.coinIds..sort(), [1, 2]);
  });

  test('sends the member token when signed in', () async {
    final api = FakeOverviewApi((_) async => data);
    final container = ProviderContainer(
      overrides: [
        coinOverviewApiProvider.overrideWithValue(api),
        authProvider.overrideWith(_SignedIn.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(coinOverviewProvider(3), (_, _) {});
    await _settle();
    await _settle();
    expect(api.lastToken, 'tok');
  });

  group('CoinOverviewApi over HTTP', () {
    Future<CoinOverview> run(int status, String body) => http.runWithClient(
      () => CoinOverviewApi().fetch(9, token: 't'),
      () => MockClient((request) async {
        expect(request.url.path, endsWith('/coins/9/overview'));
        expect(request.headers['Authorization'], 'Bearer t');
        return http.Response(body, status);
      }),
    );

    test('200 parses', () async {
      final o = await run(200, '{"summary":{"name":"X"}}');
      expect(o.summary!.name, 'X');
    });

    test('404 (server without the endpoint) is an empty overview', () async {
      expect((await run(404, 'not found')).isEmpty, isTrue);
      expect((await run(501, '')).isEmpty, isTrue);
    });

    test('garbage 200 body is an empty overview', () async {
      expect((await run(200, '<html>')).isEmpty, isTrue);
    });

    test('server errors throw', () async {
      expect(run(500, '{}'), throwsA(isA<CoinOverviewException>()));
    });
  });
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(token: 'tok');
}
