// Renders the raw phone screenshots (1080x2400, dark theme, demo data) used
// to build the Play Store images, for en / tr / es, with the real localized
// widgets. Opt-in:
//   STORE_SHOTS=1 flutter test test/store_screenshots
// Output: store_assets/screenshots/raw/<lang>/NN-name.png (git-ignored);
// then run assets/brand/compose_screenshots.js (see store_assets/screenshots/README.md).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/data/app_config_api.dart';
import 'package:kriptoanaliz/data/binance_klines_api.dart';
import 'package:kriptoanaliz/data/chart_signal_api.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/data/price_alert_api.dart';
import 'package:kriptoanaliz/data/watchlist_api.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/candle.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/models/price_alert.dart';
import 'package:kriptoanaliz/models/radar_item.dart';
import 'package:kriptoanaliz/models/structured_analysis.dart';
import 'package:kriptoanaliz/providers/analysis_history_provider.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/chart_data_provider.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/coin_overview_provider.dart';
import 'package:kriptoanaliz/providers/guest_market_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/live_chart_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/radar_provider.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/store_product_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/providers/watchlist_provider.dart';
import 'package:kriptoanaliz/utils/price_alert_logic.dart';
import 'package:kriptoanaliz/screens/chart_screen.dart';
import 'package:kriptoanaliz/screens/glossary_screen.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:kriptoanaliz/screens/radar_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/screens/watchlist_screen.dart';
import 'package:kriptoanaliz/widgets/analysis_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/chart_harness.dart'
    show FakeStream, FakeOverview, FakeAlertsApi, FakeHistory;
import '../helpers/home_fakes.dart';
import 'demo_data.dart';
import 'demo_data2.dart';
import 'shot_support.dart';

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

/// Demo persona: no name, a placeholder e-mail (never shown).
const demoMember = Member(
  id: 1,
  email: 'demo@example.com',
  role: 'user',
  creditBalance: 120,
);

const proMember = Member(
  id: 2,
  email: 'demo@example.com',
  role: 'pro',
  creditBalance: 120,
);

Future<ProviderContainer> makeContainer(
  WidgetTester tester, {
  List<Override> extra = const [],
  Member? member = demoMember,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      adsControllerProvider.overrideWith(_NoAds.new),
      authProvider.overrideWith(() => FakeAuth(member)),
      ...extra,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

class _Klines extends BinanceKlinesApi {
  @override
  Future<List<Candle>> fetchKlines({
    required String symbol,
    required String marketType,
    required String timeframe,
    int limit = 300,
  }) async {
    final rows = demoCandles();
    final end = DateTime.utc(2026, 10, 23, 20);
    return [
      for (var i = 0; i < rows.length; i++)
        Candle(
          openTime: end
              .subtract(Duration(hours: 4 * (rows.length - 1 - i)))
              .millisecondsSinceEpoch,
          open: rows[i][0],
          high: rows[i][1],
          low: rows[i][2],
          close: rows[i][3],
        ),
    ];
  }
}

class _Signals extends ChartSignalApi {
  @override
  Future<List<ChartSignal>> fetchSignals({
    required int coinId,
    required String timeframe,
    String? token,
  }) async {
    final end = DateTime.utc(2026, 10, 23, 20);
    DateTime at(int i) => end.subtract(Duration(hours: 4 * (89 - i)));
    return [
      ChartSignal(candleTime: at(64), signalType: 'sell', strength: 1),
      ChartSignal(candleTime: at(72), signalType: 'sell', strength: 2),
      ChartSignal(candleTime: at(88), signalType: 'buy', strength: 3),
    ];
  }
}

class _Selected extends SelectedCoinNotifier {
  final Coin coin;
  _Selected(this.coin);
  @override
  Future<Coin?> build() async => coin;
}

class _Config extends AppConfigApi {
  @override
  Future<AppConfig> fetch({String? token}) async => AppConfig.safeDefaults;
}

class _Watch extends WatchlistApi {
  final List<Coin> coins;
  _Watch(this.coins);
  @override
  Future<List<Coin>> fetchWatchlist(String token) async => coins;
}

class _Alerts extends PriceAlertApi {
  final List<PriceAlert> alerts;
  _Alerts(this.alerts);
  @override
  Future<PriceAlertList> fetchAlerts(String token) async =>
      PriceAlertList(alerts: alerts);
}

const _btcSpot = Coin(
  id: 1,
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  marketType: 'spot',
  lastPrice: 80567.3,
  priceChangePercent24h: -0.96,
  volume24h: 1.2e9,
);
const _ethFut = Coin(
  id: 7,
  symbol: 'ETHUSDT',
  name: 'Ethereum',
  marketType: 'futures',
  lastPrice: 2310.5,
  priceChangePercent24h: -1.4,
  volume24h: 6.4e8,
);

Coin _c(
  int id,
  String sym,
  String name,
  double p,
  double ch,
  double v, [
  String mt = 'spot',
]) => Coin(
  id: id,
  symbol: sym,
  name: name,
  marketType: mt,
  lastPrice: p,
  priceChangePercent24h: ch,
  volume24h: v,
);

Future<void> _settle(WidgetTester tester, [int steps = 15]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _pumpChart(
  WidgetTester tester,
  String lang,
  Coin coin,
  Map<String, dynamic> overview,
) async {
  final c = await makeContainer(
    tester,
    member: proMember,
    extra: [
      selectedCoinProvider.overrideWith(() => _Selected(coin)),
      binanceKlinesApiProvider.overrideWithValue(_Klines()),
      chartSignalApiProvider.overrideWithValue(_Signals()),
      klineStreamProvider.overrideWithValue(FakeStream()),
      coinOverviewApiProvider.overrideWithValue(
        FakeOverview(() async => CoinOverview.parse(overview)),
      ),
      analysisHistoryApiProvider.overrideWithValue(FakeHistory(const [])),
      priceAlertApiProvider.overrideWithValue(
        FakeAlertsApi(() async => const PriceAlertList()),
      ),
      appConfigApiProvider.overrideWithValue(_Config()),
    ],
  );
  c.read(homeTabProvider.notifier).select(chartTabIndex);
  await tester.pumpWidget(
    shotApp(lang: lang, home: const ChartScreen(), container: c),
  );
  await _settle(tester, 20);
  await tester.tap(find.text('4h').first);
  await _settle(tester, 20);
  return c;
}

Future<void> _scrollChart(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(CustomScrollView).first, Offset(0, -dy));
  await _settle(tester, 10);
}

void main() {
  setUpAll(loadStoreFonts);
  final skip = !storeShotsEnabled;

  for (final lang in storeShotLangs()) {
    group(lang, () {
      testWidgets('01-home', (tester) async {
        usePhoneSurface(tester);
        final body = jsonEncode(homeJson(lang));
        final api = FakeHomeApi(
          () => Future.value(HomeResponse(homeResponseData(body), body)),
        );
        final c = await makeContainer(
          tester,
          extra: [
            homeApiProvider.overrideWithValue(api),
            guestMarketProvider.overrideWith((ref) async => null),
            homeClockProvider.overrideWithValue(() => homeTestNow),
            coinApiProvider.overrideWithValue(FakeCoinApi([])),
          ],
        );
        await tester.pumpWidget(
          shotApp(lang: lang, home: const HomeScreen(), container: c),
        );
        await tester.pumpAndSettle();
        await savePng(tester, lang, '01-home');
      }, skip: skip);

      testWidgets('02-chart', (tester) async {
        usePhoneSurface(tester);
        final cc = await _pumpChart(tester, lang, _btcSpot, btcOverview(lang));
        await savePng(tester, lang, '02-chart');
        await _disposeChart(tester, cc);
      }, skip: skip);

      testWidgets('03-deep-analysis', (tester) async {
        usePhoneSurface(tester);
        final c = await makeContainer(tester);
        await tester.pumpWidget(
          shotApp(
            lang: lang,
            container: c,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: TextButton(
                    onPressed: () => showAnalysisSheet(
                      ctx,
                      result: 'x',
                      creditCost: 5,
                      structured: StructuredAnalysis.fromJson(
                        deepAnalysis(lang),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await _settle(tester);
        await savePng(tester, lang, '03-deep-analysis');
      }, skip: skip);

      testWidgets('04-coin-summary', (tester) async {
        usePhoneSurface(tester);
        final cc = await _pumpChart(tester, lang, _btcSpot, btcOverview(lang));
        await _scrollChart(tester, 500);
        await savePng(tester, lang, '04-coin-summary');
        await _disposeChart(tester, cc);
      }, skip: skip);

      testWidgets('05-market', (tester) async {
        usePhoneSurface(tester);
        final cc = await _pumpChart(tester, lang, _ethFut, ethOverview());
        await tester.tap(find.byType(Tab).at(2));
        await _settle(tester, 10);
        await _scrollChart(tester, 470);
        await savePng(tester, lang, '05-market');
        await _disposeChart(tester, cc);
      }, skip: skip);

      testWidgets('06-radar', (tester) async {
        usePhoneSurface(tester);
        final ago = DateTime.now().subtract(const Duration(minutes: 7));
        RadarItem it(
          int id,
          String sym,
          int score,
          double chg,
          double rsi, {
          String? trend,
          double? vol,
          int? cm,
        }) => RadarItem(
          id: id,
          term: 'short',
          timeframe: '15m',
          technicalScore: score,
          rsi: rsi,
          lastClose: 1,
          detectedAt: ago,
          trend: trend,
          volumeRatio: vol,
          aiComment: cm == null ? null : radarComments[lang]![cm],
          scoreBreakdown: const {
            'oversold': 22,
            'bollinger': 14,
            'volume': 12,
            'reversal': 10,
          },
          coin: _c(id, sym, sym, 1, chg, 1),
        );
        final items = [
          it(101, 'SOLUSDT', 78, -4.8, 21.3, trend: 'up', vol: 2.4, cm: 0),
          it(102, 'LINKUSDT', 71, -3.9, 23.8, trend: 'up', vol: 1.9, cm: 1),
          it(103, 'AVAXUSDT', 66, -5.2, 24.9, vol: 1.6, cm: 2),
          it(104, 'ADAUSDT', 58, -3.1, 27.4, vol: 1.3),
          it(105, 'DOGEUSDT', 52, -4.4, 28.8, vol: 1.2),
          it(106, 'DOTUSDT', 44, -2.7, 31.0),
        ];
        final c = await makeContainer(
          tester,
          member: const Member(
            id: 2,
            email: 'demo@example.com',
            role: 'pro',
            creditBalance: 120,
          ),
          extra: [
            selectedCoinProvider.overrideWith(() => _Selected(_btcSpot)),
            radarProvider.overrideWith(
              (ref, term) => term == null
                  ? items
                  : items.where((i) => i.term == term).toList(),
            ),
          ],
        );
        await tester.pumpWidget(
          shotApp(lang: lang, home: const RadarScreen(), container: c),
        );
        await _settle(tester, 40);
        await savePng(tester, lang, '06-radar');
      }, skip: skip);

      testWidgets('07-watchlist', (tester) async {
        usePhoneSurface(tester);
        final coins = [
          _btcSpot,
          _ethFut,
          _c(101, 'SOLUSDT', 'Solana', 168.35, 8.42, 3.1e8),
          _c(102, 'LINKUSDT', 'Chainlink', 17.84, 5.38, 9.2e7, 'futures'),
          _c(105, 'DOGEUSDT', 'Dogecoin', 0.1534, 4.12, 1.4e8),
          _c(201, 'XRPUSDT', 'XRP', 0.5412, -3.2, 2.2e8),
          _c(104, 'ADAUSDT', 'Cardano', 0.5821, 4.77, 8.1e7),
        ];
        final c = await makeContainer(
          tester,
          extra: [
            watchlistApiProvider.overrideWithValue(_Watch(coins)),
            priceAlertApiProvider.overrideWithValue(
              _Alerts([
                const PriceAlert(
                  id: 1,
                  coinId: 1,
                  symbol: 'BTCUSDT',
                  marketType: 'spot',
                  targetPrice: 85000,
                  direction: AlertDirection.above,
                  status: PriceAlertStatus.active,
                ),
                const PriceAlert(
                  id: 2,
                  coinId: 7,
                  symbol: 'ETHUSDT',
                  marketType: 'futures',
                  targetPrice: 2200,
                  direction: AlertDirection.below,
                  status: PriceAlertStatus.active,
                ),
              ]),
            ),
          ],
        );
        await tester.pumpWidget(
          shotApp(lang: lang, home: const WatchlistScreen(), container: c),
        );
        await _settle(tester);
        await savePng(tester, lang, '07-watchlist');
      }, skip: skip);

      testWidgets('08-glossary', (tester) async {
        usePhoneSurface(tester);
        final c = await makeContainer(tester);
        await tester.pumpWidget(
          shotApp(lang: lang, home: const GlossaryScreen(), container: c),
        );
        await _settle(tester, 10);
        await savePng(tester, lang, '08-glossary');
      }, skip: skip);

      // App Store set only: the Pro / subscription screen (iOS wording, store
      // price and auto-renew terms) with demo plan data.
      testWidgets('09-pro', (tester) async {
        usePhoneSurface(tester);
        final c = await makeContainer(
          tester,
          extra: [
            purchaseIsIosProvider.overrideWithValue(true),
            inAppPurchaseProvider.overrideWithValue(_NoStore()),
            subscriptionPlanListProvider.overrideWith(
              (ref) async => const [demoProPlan],
            ),
            storePricesProvider.overrideWith(
              (ref, ids) async => const {'ios_pro_monthly': '\$9.99'},
            ),
            storeProductsProvider.overrideWith((ref, ids) async => {}),
          ],
        );
        await tester.pumpWidget(
          shotApp(lang: lang, home: const SubscriptionScreen(), container: c),
        );
        await _settle(tester, 10);
        // The page is longer than the phone: scroll to the end so the plan
        // card, price, auto-renew note, terms and restore button are visible.
        await tester.drag(find.byType(ListView).first, const Offset(0, -380));
        await _settle(tester, 10);
        await savePng(tester, lang, '09-pro');
      }, skip: skip || !iosProfile);
    });
  }
}

/// Inert store plugin: no platform channels, no purchase events.
class _NoStore implements InAppPurchase {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const demoProPlan = SubscriptionPlan(
  id: 1,
  name: 'CryptoAnaliz Pro',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  appleProductId: 'ios_pro_monthly',
  monthlyCredit: 300,
);

/// Unmounts the chart and disposes the container so the live chart's timers
/// are cancelled before the test ends.
Future<void> _disposeChart(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox.shrink());
  c.dispose();
  await tester.pump(const Duration(seconds: 1));
}
