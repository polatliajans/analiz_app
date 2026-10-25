import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/analysis_history_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/guest_market_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:kriptoanaliz/widgets/home/home_sections.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

class _Harness {
  final ProviderContainer container;
  final FakeHomeApi api;
  _Harness(this.container, this.api);
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required Future<HomeResponse> Function() handler,
  Map<String, Object> prefs = const {},
  Member? member = testMember,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(360, 3600),
  bool settle = true,
  MutableClock? clock,
  Duration? autoRefresh,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = FakeHomeApi(handler);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      authProvider.overrideWith(() => FakeAuth(member)),
      homeApiProvider.overrideWithValue(api),
      guestMarketProvider.overrideWith((ref) async => null),
      homeAutoRefreshProvider.overrideWithValue(autoRefresh),
      homeClockProvider.overrideWithValue(clock?.call ?? () => homeTestNow),
      coinApiProvider.overrideWithValue(
        FakeCoinApi([
          testCoin(1, 'BTCUSDT'),
          testCoin(7, 'ETHUSDT'),
          testCoin(9, 'DOGEUSDT'),
          testCoin(8, 'SOLUSDT', 'futures'),
        ]),
      ),
      analysisHistoryApiProvider.overrideWithValue(
        FakeHistoryApi([
          AnalysisRecord(
            id: 12,
            type: 'deep',
            coinId: 1,
            symbol: 'SUIUSDT',
            marketType: 'futures',
            timeframe: '4h',
            result: 'FULL ANALYSIS TEXT',
            creditCost: 10,
            createdAt: homeTestNow,
          ),
        ]),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          brightness: brightness,
        ),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return _Harness(container, api);
}

Future<HomeResponse> Function() _ok(Map<String, dynamic> json) =>
    () => Future.value(homeResponse(json));

Map<String, Object> _cache() => {
  homeCacheBodyKey: jsonEncode(fullHomeJson()),
  homeCacheAtKey: homeTestNow
      .subtract(const Duration(minutes: 3))
      .millisecondsSinceEpoch,
  homeCacheUserKey: 1,
};

void main() {
  testWidgets('refreshes by itself while the home tab is visible', (
    tester,
  ) async {
    final clock = MutableClock(homeTestNow);
    final h = await _pump(
      tester,
      handler: _ok(fullHomeJson()),
      clock: clock,
      autoRefresh: const Duration(seconds: 40),
    );
    final before = h.api.calls;
    clock.now = clock.now.add(const Duration(seconds: 41));
    await tester.pump(const Duration(seconds: 41));
    await tester.pump();
    expect(h.api.calls, before + 1, reason: 'periodic refresh fetched once');
    // Leaving the tab pauses it.
    h.container.read(homeTabProvider.notifier).select(chartTabIndex);
    clock.now = clock.now.add(const Duration(seconds: 41));
    await tester.pump(const Duration(seconds: 41));
    expect(h.api.calls, before + 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('full data shows every section', (tester) async {
    await _pump(tester, handler: _ok(fullHomeJson()));

    expect(find.text('Ayse'), findsOneWidget);
    expect(find.text('80 credits'), findsOneWidget);
    expect(find.text('Where you left off'), findsNothing);

    expect(find.text('Fear & Greed'), findsOneWidget);
    expect(find.text('53'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Bull'), findsOneWidget);
    expect(find.text('+1.02%'), findsWidgets);

    expect(find.text('My watchlist'), findsOneWidget);
    expect(find.text('DOGEUSDT'), findsOneWidget);
    expect(find.text('-4.50%'), findsOneWidget);

    expect(find.text('Latest signals from Radar'), findsOneWidget);
    expect(find.text('ETHUSDT'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);

    expect(find.text('Your latest deep analysis'), findsOneWidget);
    expect(find.text('SUIUSDT · Futures · 4h'), findsOneWidget);
    expect(find.text('Bearish'), findsOneWidget);
    expect(find.text('Confidence 54%'), findsOneWidget);
    expect(find.text('Short-term pressure remains downward.'), findsOneWidget);
    expect(find.text('Shared result'), findsOneWidget);

    expect(find.text('Upcoming events'), findsOneWidget);
    expect(find.text('FOMC rate decision + statement'), findsOneWidget);
    expect(find.text('CPI release'), findsOneWidget);

    expect(find.text('Term of the day'), findsOneWidget);
    expect(find.text('Go further with Pro'), findsOneWidget);
    expect(find.textContaining('not investment advice'), findsOneWidget);
    expect(find.textContaining('Alternative.me'), findsOneWidget);
    expect(find.text(fredDisclaimer), findsOneWidget);
    expect(
      fredDisclaimer,
      'This product uses the FRED® API but is not endorsed or certified by '
      'the Federal Reserve Bank of St. Louis.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout order is top to bottom as specified', (tester) async {
    await _pump(tester, handler: _ok(fullHomeJson()));
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    final order = [
      y('Ayse'),
      y('Fear & Greed'),
      y('Market'),
      y('My watchlist'),
      y('Latest signals from Radar'),
      y('Your latest deep analysis'),
      y('Upcoming events'),
      y('Learn'),
      y('Go further with Pro'),
    ];
    final sorted = [...order]..sort();
    expect(order, sorted);
  });

  testWidgets('pro member sees Pro chip and no promo', (tester) async {
    final json = fullHomeJson()..['credits'] = {'balance': 300, 'is_pro': true};
    await _pump(tester, handler: _ok(json));
    expect(find.text('Pro'), findsOneWidget);
    expect(find.text('300 credits'), findsOneWidget);
    expect(find.text('Go further with Pro'), findsNothing);
  });

  testWidgets('empty data shows friendly empty states and hides events', (
    tester,
  ) async {
    await _pump(tester, handler: _ok(emptyHomeJson()));
    expect(find.text('Market data is unavailable right now.'), findsOneWidget);
    expect(
      find.text('Follow coins to see their biggest 24h moves here.'),
      findsOneWidget,
    );
    expect(find.text('Open my watchlist'), findsOneWidget);
    expect(find.text('No new radar signals right now.'), findsOneWidget);
    expect(
      find.textContaining('You have not run a deep analysis yet'),
      findsOneWidget,
    );
    expect(find.text('New analysis'), findsOneWidget);
    expect(find.text('Upcoming events'), findsNothing);
    expect(find.text('Learn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading without cache shows the skeleton', (tester) async {
    final pending = Completer<HomeResponse>();
    await _pump(tester, handler: () => pending.future, settle: false);
    expect(find.byType(HomeSkeleton), findsOneWidget);
    expect(find.text('Fear & Greed'), findsNothing);
    pending.complete(homeResponse(fullHomeJson()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeSkeleton), findsNothing);
    expect(find.text('Fear & Greed'), findsOneWidget);
  });

  testWidgets('refresh error with cached data keeps data + stale note', (
    tester,
  ) async {
    await _pump(
      tester,
      prefs: _cache(),
      handler: () => Future.error(HomeException('offline')),
    );
    expect(find.text('ETHUSDT'), findsOneWidget);
    expect(find.text('Fear & Greed'), findsOneWidget);
    expect(find.textContaining('Not up to date'), findsOneWidget);
    expect(find.text('Could not load the overview'), findsNothing);
  });

  testWidgets('fresh cache + successful refresh shows no stale note', (
    tester,
  ) async {
    await _pump(tester, prefs: _cache(), handler: _ok(fullHomeJson()));
    expect(find.textContaining('Not up to date'), findsNothing);
  });

  testWidgets('error without cache shows retry that refetches', (tester) async {
    final h = await _pump(
      tester,
      handler: () => Future.error(HomeException('offline')),
    );
    expect(find.text('Could not load the overview'), findsOneWidget);
    expect(h.api.calls, 1);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(h.api.calls, 2);
  });

  testWidgets('pull to refresh refetches', (tester) async {
    final h = await _pump(
      tester,
      handler: _ok(fullHomeJson()),
      size: const Size(360, 640),
    );
    expect(h.api.calls, 1);
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(h.api.calls, 2);
  });

  testWidgets('guest sees a login prompt and no request is made', (
    tester,
  ) async {
    final h = await _pump(tester, handler: _ok(fullHomeJson()), member: null);
    expect(
      find.text('Sign in to unlock analysis, watchlist and alerts'),
      findsOneWidget,
    );
    expect(find.text('Log in / Sign up'), findsOneWidget);
    expect(find.text('Fear & Greed'), findsNothing);
    expect(find.text('Learn'), findsOneWidget);
    expect(h.api.calls, 0);
  });

  group('navigation', () {
    testWidgets('radar row opens chart with coin and timeframe', (
      tester,
    ) async {
      final h = await _pump(tester, handler: _ok(fullHomeJson()));
      expect(h.container.read(homeTabProvider), homeTabIndex);
      await tester.tap(find.text('ETHUSDT'));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), chartTabIndex);
      expect(h.container.read(selectedCoinProvider).value!.symbol, 'ETHUSDT');
      expect(h.container.read(selectedCoinProvider).value!.id, 7);
      expect(h.container.read(timeframeProvider), '4h');
      final prefs = h.container.read(sharedPreferencesProvider);
      expect(prefs.getString(lastCoinSymbolKey), 'ETHUSDT');
      expect(prefs.getString(lastTimeframeKey), '4h');
    });

    testWidgets('futures radar row passes the market type', (tester) async {
      final h = await _pump(tester, handler: _ok(fullHomeJson()));
      await tester.tap(find.text('SOLUSDT · Futures'));
      await tester.pumpAndSettle();
      final coin = h.container.read(selectedCoinProvider).value!;
      expect(coin.symbol, 'SOLUSDT');
      expect(coin.marketType, 'futures');
      expect(h.container.read(timeframeProvider), '1h');
    });

    testWidgets('mover row opens chart and keeps the timeframe', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        handler: _ok(fullHomeJson()),
        prefs: {lastTimeframeKey: '1d'},
      );
      await tester.tap(find.text('DOGEUSDT'));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), chartTabIndex);
      expect(h.container.read(selectedCoinProvider).value!.symbol, 'DOGEUSDT');
      expect(h.container.read(timeframeProvider), '1d');
    });

    testWidgets('unknown coin falls back to a bare coin', (tester) async {
      final json = fullHomeJson();
      json['movers'] = [
        {'coin_id': 555, 'symbol': 'NEWUSDT', 'market_type': 'spot'},
      ];
      final h = await _pump(tester, handler: _ok(json));
      await tester.tap(find.text('NEWUSDT'));
      await tester.pumpAndSettle();
      final coin = h.container.read(selectedCoinProvider).value!;
      expect(coin.symbol, 'NEWUSDT');
      expect(coin.id, 555);
      expect(h.container.read(homeTabProvider), chartTabIndex);
    });

    testWidgets('new analysis button opens the chart tab', (tester) async {
      final h = await _pump(tester, handler: _ok(emptyHomeJson()));
      await tester.tap(find.text('New analysis'));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), chartTabIndex);
    });

    testWidgets('empty movers action opens the watchlist tab', (tester) async {
      final h = await _pump(tester, handler: _ok(emptyHomeJson()));
      await tester.tap(find.text('Open my watchlist'));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), watchlistTabIndex);
    });

    testWidgets('last analysis opens the stored result', (tester) async {
      await _pump(tester, handler: _ok(fullHomeJson()));
      await tester.tap(find.text('Short-term pressure remains downward.'));
      await tester.pumpAndSettle();
      expect(find.text('FULL ANALYSIS TEXT'), findsOneWidget);
    });

    testWidgets('term of the day opens the glossary', (tester) async {
      await _pump(tester, handler: _ok(fullHomeJson()));
      await tester.tap(find.text('Open glossary'));
      await tester.pumpAndSettle();
      expect(find.text('Glossary of technical terms'), findsOneWidget);
    });
  });

  testWidgets('refreshes when the tab becomes visible (debounced)', (
    tester,
  ) async {
    final h = await _pump(tester, handler: _ok(fullHomeJson()));
    expect(h.api.calls, 1);
    h.container.read(homeTabProvider.notifier).select(radarTabIndex);
    await tester.pump();
    h.container.read(homeTabProvider.notifier).select(homeTabIndex);
    await tester.pumpAndSettle();
    // The fake clock never advances, so the one-minute debounce applies.
    expect(h.api.calls, 1);
  });

  testWidgets('refreshes when the tab becomes visible after a minute', (
    tester,
  ) async {
    final clock = MutableClock(homeTestNow);
    final h = await _pump(tester, handler: _ok(fullHomeJson()), clock: clock);
    expect(h.api.calls, 1);
    h.container.read(homeTabProvider.notifier).select(radarTabIndex);
    await tester.pump();
    clock.now = clock.now.add(const Duration(minutes: 2));
    h.container.read(homeTabProvider.notifier).select(homeTabIndex);
    await tester.pumpAndSettle();
    expect(h.api.calls, 2);
  });

  for (final locale in ['en', 'tr', 'es']) {
    for (final json in [fullHomeJson, emptyHomeJson]) {
      testWidgets(
        'no overflow at 360dp with 1.6 text scale ($locale, ${json == fullHomeJson ? 'full' : 'empty'})',
        (tester) async {
          await _pump(
            tester,
            handler: _ok(json()),
            locale: locale,
            textScale: 1.6,
            size: const Size(360, 8000),
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(HomeScreen), findsOneWidget);
        },
      );
    }
  }

  testWidgets('dark theme smoke test', (tester) async {
    await _pump(
      tester,
      handler: _ok(fullHomeJson()),
      brightness: Brightness.dark,
    );
    expect(find.text('Fear & Greed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('turkish locale uses translated labels', (tester) async {
    await _pump(tester, handler: _ok(fullHomeJson()), locale: 'tr');
    expect(find.text('Ana Sayfa'), findsNothing);
    expect(find.text('Merhaba'), findsNothing);
    expect(find.text('Ayse'), findsOneWidget);
    expect(find.text('Korku ve Açgözlülük'), findsOneWidget);
    expect(find.text('Nötr'), findsOneWidget);
    expect(find.text('Kaldığın yer'), findsNothing);
    expect(find.textContaining('yatırım tavsiyesi değildir'), findsOneWidget);
  });
}
