import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/price_alert_api.dart';
import 'package:kriptoanaliz/data/watchlist_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/price_alert.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/providers/watchlist_provider.dart';
import 'package:kriptoanaliz/screens/watchlist_screen.dart';
import 'package:kriptoanaliz/utils/home_logic.dart';
import 'package:kriptoanaliz/utils/overview_format.dart' as ov;
import 'package:kriptoanaliz/utils/price_alert_logic.dart';
import 'package:kriptoanaliz/widgets/watchlist_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    token: 'tok',
    member: Member(id: 1, email: 'a@b.c', role: 'user', creditBalance: 1),
  );
}

class _FakeWatchlistApi extends WatchlistApi {
  List<Coin> coins;
  int calls = 0;
  _FakeWatchlistApi(this.coins);

  @override
  Future<List<Coin>> fetchWatchlist(String token) async {
    calls++;
    return coins;
  }
}

class _FakeAlertsApi extends PriceAlertApi {
  final List<PriceAlert> alerts;
  _FakeAlertsApi(this.alerts);

  @override
  Future<PriceAlertList> fetchAlerts(String token) async =>
      PriceAlertList(alerts: alerts);
}

const _btc = Coin(
  id: 1,
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  marketType: 'spot',
  lastPrice: 80515.8,
  priceChangePercent24h: 2.345,
  volume24h: 1039381299.56,
);
const _eth = Coin(
  id: 2,
  symbol: 'ETHUSDT',
  name: 'Ethereum',
  marketType: 'futures',
  lastPrice: 2310.5,
  priceChangePercent24h: -1.2,
  volume24h: 41700000,
);
const _pepe = Coin(
  id: 4,
  symbol: 'PEPEUSDT',
  name: 'Pepe',
  marketType: 'futures',
  lastPrice: 0.00001234,
  priceChangePercent24h: 1234.56,
  volume24h: 987654321012,
);

PriceAlert _alert(int coinId, {bool active = true}) => PriceAlert(
  id: coinId,
  coinId: coinId,
  symbol: 'X',
  marketType: 'spot',
  targetPrice: 1,
  direction: AlertDirection.above,
  status: active ? PriceAlertStatus.active : PriceAlertStatus.triggered,
);

Finder _rich(String text) => find.textContaining(text, findRichText: true);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<Coin> coins,
  List<PriceAlert> alerts = const [],
  double textScale = 1,
  Brightness brightness = Brightness.light,
  String locale = 'en',
  _FakeWatchlistApi? api,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith(_FakeAuth.new),
      watchlistApiProvider.overrideWithValue(api ?? _FakeWatchlistApi(coins)),
      priceAlertApiProvider.overrideWithValue(_FakeAlertsApi(alerts)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
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
        home: const WatchlistScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('formatting helpers', () {
    test('formatVolumeUsd abbreviates with about three significant digits', () {
      expect(formatVolumeUsd(1039381299.56, 'en'), '\$1.04B');
      expect(formatVolumeUsd(41700000, 'en'), '\$41.7M');
      expect(formatVolumeUsd(512000000, 'en'), '\$512M');
      expect(formatVolumeUsd(2500000000000, 'en'), '\$2.5T');
      expect(formatVolumeUsd(950, 'en'), '\$950');
      expect(formatVolumeUsd(41700000, 'es'), '\$41,7M');
    });

    test('formatDistancePct: one decimal below 100, none above', () {
      expect(ov.formatDistancePct(-36.2, 'en'), '-36.2%');
      expect(ov.formatDistancePct(2758.2, 'en'), '+2,758%');
      expect(ov.formatDistancePct(120000, 'en'), '+120,000%');
      expect(ov.formatDistancePct(12.34, 'en'), '+12.3%');
      expect(ov.formatDistancePct(0.01, 'en'), '0.0%');
      expect(ov.formatDistancePct(-36.2, 'tr'), '-36,2%');
      expect(ov.formatDistancePct(2758.2, 'tr'), '+2.758%');
    });

    test('ATH / ATL prices use the shared USD price formatter', () {
      expect(formatUsdPrice(126200, 'en'), '\$126,200');
      expect(formatUsdPrice(2817, 'en'), '\$2,817');
      expect(formatUsdPrice(0.00001234, 'en'), '\$0.00001234');
      // The alert helper stays plain-text for editing prices.
      expect(formatAlertPrice(126200), '126200');
    });
  });

  group('watchlist row', () {
    testWidgets('formats symbol, badge, price, change chip and volume', (
      tester,
    ) async {
      await _pump(tester, coins: [_btc, _eth]);
      expect(_rich('BTC/USDT'), findsOneWidget);
      expect(_rich('ETH/USDT'), findsOneWidget);
      expect(find.text('\$80,515.8'), findsOneWidget);
      expect(find.text('\$2,310.5'), findsOneWidget);
      expect(find.text('+2.35%'), findsOneWidget);
      expect(find.text('-1.20%'), findsOneWidget);
      expect(find.text('Vol \$1.04B'), findsOneWidget);
      expect(find.text('Vol \$41.7M'), findsOneWidget);
      // No raw numbers.
      expect(find.textContaining('80515.8'), findsNothing);
      expect(find.textContaining('1039381299'), findsNothing);
      expect(find.textContaining('Volume:'), findsNothing);
      // Spot / Futures badges.
      expect(find.byKey(const Key('watchlist-market-badge')), findsNWidgets(2));
      expect(find.text('Spot'), findsOneWidget);
      expect(find.text('Futures'), findsOneWidget);
    });

    testWidgets('change chip is green when up and red when down', (
      tester,
    ) async {
      await _pump(tester, coins: [_btc, _eth]);
      Color chipColor(int i) {
        final box = tester.widget<Container>(
          find.byKey(const Key('watchlist-change-chip')).at(i),
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      final up = chipColor(0);
      final down = chipColor(1);
      expect(up.g, greaterThan(up.r), reason: 'green tint');
      expect(down.r, greaterThan(down.g), reason: 'red tint');
      final upText = tester.widget<Text>(find.text('+2.35%'));
      final downText = tester.widget<Text>(find.text('-1.20%'));
      expect(upText.style!.color!.g, greaterThan(upText.style!.color!.r));
      expect(downText.style!.color!.r, greaterThan(downText.style!.color!.g));
    });

    testWidgets('bell only on coins with an active alert', (tester) async {
      await _pump(
        tester,
        coins: [_btc, _eth],
        alerts: [_alert(1), _alert(2, active: false)],
      );
      final bellFinder = find.byKey(const Key('watchlist-alert-bell'));
      expect(bellFinder, findsOneWidget);
      final btcRow = tester.getRect(find.byType(WatchlistRow).first);
      expect(btcRow.contains(tester.getCenter(bellFinder)), isTrue);
    });

    testWidgets('missing numbers show a dash, not zeros', (tester) async {
      await _pump(
        tester,
        coins: [
          const Coin(
            id: 3,
            symbol: 'SOLUSDT',
            name: 'Solana',
            marketType: 'spot',
            lastPrice: null,
            priceChangePercent24h: null,
            volume24h: null,
          ),
        ],
      );
      expect(find.text('—'), findsNWidgets(2));
      expect(find.textContaining('Vol'), findsNothing);
    });

    testWidgets('tapping a row opens the chart for that coin', (tester) async {
      final c = await _pump(tester, coins: [_btc, _eth]);
      await tester.tap(_rich('ETH/USDT'));
      await tester.pump();
      expect(c.read(homeTabProvider), chartTabIndex);
      expect(c.read(selectedCoinProvider).value?.symbol, 'ETHUSDT');
    });

    testWidgets('pull to refresh reloads the list', (tester) async {
      final api = _FakeWatchlistApi([_btc]);
      await _pump(tester, coins: const [], api: api);
      expect(api.calls, 1);
      api.coins = [_btc, _eth];
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(api.calls, 2);
      expect(_rich('ETH/USDT'), findsOneWidget);
    });

    for (final locale in ['en', 'tr', 'es']) {
      for (final brightness in Brightness.values) {
        testWidgets('1.6 text scale: no overflow ($locale, $brightness)', (
          tester,
        ) async {
          await _pump(
            tester,
            coins: [_btc, _eth, _pepe],
            alerts: [_alert(1), _alert(4)],
            textScale: 1.6,
            locale: locale,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(WatchlistRow), findsNWidgets(3));
          expect(
            find.byKey(const Key('watchlist-alert-bell')),
            findsNWidgets(2),
          );
        });
      }
    }
  });

  group('empty state', () {
    for (final locale in ['en', 'tr', 'es']) {
      testWidgets('icon and hint ($locale)', (tester) async {
        await _pump(tester, coins: const [], locale: locale);
        expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
        expect(find.byKey(const Key('watchlist-empty')), findsOneWidget);
        if (locale == 'en') {
          expect(
            find.text('You are not following any coins yet'),
            findsOneWidget,
          );
          expect(
            find.text("Tap the star on a coin's chart to add it here."),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no overflow at 1.6 text scale', (tester) async {
      await _pump(tester, coins: const [], textScale: 1.6);
      expect(tester.takeException(), isNull);
    });
  });
}
