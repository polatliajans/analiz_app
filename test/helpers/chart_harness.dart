import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/analysis_history_api.dart';
import 'package:kriptoanaliz/data/app_config_api.dart';
import 'package:kriptoanaliz/data/binance_klines_api.dart';
import 'package:kriptoanaliz/data/chart_signal_api.dart';
import 'package:kriptoanaliz/data/coin_overview_api.dart';
import 'package:kriptoanaliz/data/kline_stream.dart';
import 'package:kriptoanaliz/data/price_alert_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/candle.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/price_alert.dart';
import 'package:kriptoanaliz/providers/analysis_history_provider.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/chart_data_provider.dart';
import 'package:kriptoanaliz/providers/coin_overview_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/live_chart_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/screens/chart_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../coin_overview_model_test.dart' show fullOverviewJson;

export '../coin_overview_model_test.dart' show fullOverviewJson;

const chartTestCoin = Coin(
  id: 1,
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  marketType: 'spot',
  lastPrice: 120,
  priceChangePercent24h: 1.5,
  volume24h: 1,
);

const chartTestFuturesCoin = Coin(
  id: 1,
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  marketType: 'futures',
  lastPrice: 120,
  priceChangePercent24h: 1.5,
  volume24h: 1,
);

const freeMemberForChart = Member(
  id: 1,
  email: 'a@b.c',
  role: 'user',
  creditBalance: 10,
);
const proMemberForChart = Member(
  id: 1,
  email: 'a@b.c',
  role: 'pro',
  creditBalance: 10,
);

/// Hourly candles starting here; close = 100 + index.
final chartTestStart = DateTime.utc(2026, 10, 21);
List<Candle> chartTestCandles() => [
  for (var i = 0; i < 30; i++)
    Candle(
      openTime: chartTestStart.add(Duration(hours: i)).millisecondsSinceEpoch,
      open: 100.0 + i,
      high: 102.0 + i,
      low: 99.0 + i,
      close: 100.0 + i,
    ),
];

List<ChartSignal> chartTestSignals() => [
  ChartSignal(
    candleTime: chartTestStart.add(const Duration(hours: 5)),
    signalType: 'buy',
    strength: 2,
  ),
  ChartSignal(
    candleTime: chartTestStart.add(const Duration(hours: 12)),
    signalType: 'sell',
    strength: 1,
  ),
  ChartSignal(
    candleTime: chartTestStart.add(const Duration(hours: 20)),
    signalType: 'buy',
    strength: 3,
  ),
];

class FakeKlines extends BinanceKlinesApi {
  int calls = 0;

  @override
  Future<List<Candle>> fetchKlines({
    required String symbol,
    required String marketType,
    required String timeframe,
    int limit = 300,
  }) async {
    calls++;
    return chartTestCandles();
  }
}

class FakeSignals extends ChartSignalApi {
  List<ChartSignal> data = chartTestSignals();
  int calls = 0;

  @override
  Future<List<ChartSignal>> fetchSignals({
    required int coinId,
    required String timeframe,
    String? token,
  }) async {
    calls++;
    return data;
  }
}

class FakeStream implements KlineStream {
  int connects = 0;

  @override
  Stream<LiveEvent> connect({
    required String marketType,
    required String symbol,
    required String timeframe,
  }) {
    connects++;
    return StreamController<LiveEvent>().stream;
  }
}

class _FakeSelectedCoin extends SelectedCoinNotifier {
  final Coin coin;
  _FakeSelectedCoin(this.coin);

  @override
  Future<Coin?> build() async => coin;
}

class FakeOverview extends CoinOverviewApi {
  int calls = 0;
  Future<CoinOverview> Function() handler;
  FakeOverview(this.handler);

  @override
  Future<CoinOverview> fetch(int coinId, {String? token}) {
    calls++;
    return handler();
  }
}

class FakeAlertsApi extends PriceAlertApi {
  int calls = 0;
  Future<PriceAlertList> Function() handler;
  FakeAlertsApi(this.handler);

  @override
  Future<PriceAlertList> fetchAlerts(String token) {
    calls++;
    return handler();
  }
}

/// History API that returns the same records whatever `coin_id` is asked,
/// like a server that ignores the filter.
class FakeHistory extends AnalysisHistoryApi {
  final List<AnalysisRecord> records;
  int calls = 0;
  Object? error;
  int? lastCoinId;
  FakeHistory(this.records);

  @override
  Future<List<AnalysisRecord>> fetch(String token, {int? coinId}) async {
    calls++;
    lastCoinId = coinId;
    if (error != null) throw error!;
    return records;
  }
}

class _FakeAppConfigApi extends AppConfigApi {
  AppConfig config;
  _FakeAppConfigApi(this.config);

  @override
  Future<AppConfig> fetch({String? token}) async => config;
}

class _FakeAuthChart extends AuthNotifier {
  final Member? member;
  _FakeAuthChart(this.member);

  @override
  AuthState build() => member == null
      ? const AuthState()
      : AuthState(token: 'tok', member: member);
}

class ChartHarness {
  final ProviderContainer container;
  final FakeOverview overview;
  final FakeHistory history;
  final FakeAlertsApi alerts;
  final FakeStream stream;
  final FakeKlines klines;
  final FakeSignals signals;
  ChartHarness(
    this.container,
    this.overview,
    this.history,
    this.alerts,
    this.stream,
    this.klines,
    this.signals,
  );
}

Future<ChartHarness> pumpChartScreen(
  WidgetTester tester, {
  Member? member = freeMemberForChart,
  Coin coin = chartTestCoin,
  Future<CoinOverview> Function()? overview,
  List<AnalysisRecord> history = const [],
  Future<PriceAlertList> Function()? alerts,
  AppConfig config = AppConfig.safeDefaults,
  Size size = const Size(360, 800),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  String locale = 'en',
  DateTime Function()? clock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final overviewApi = FakeOverview(
    overview ?? () async => CoinOverview.parse(fullOverviewJson()),
  );
  final historyApi = FakeHistory(history);
  final alertsApi = FakeAlertsApi(alerts ?? () async => const PriceAlertList());
  final stream = FakeStream();
  final klines = FakeKlines();
  final signalsApi = FakeSignals();

  final container = ProviderContainer(
    // No automatic retries: error states must stay put in tests.
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith(() => _FakeAuthChart(member)),
      selectedCoinProvider.overrideWith(() => _FakeSelectedCoin(coin)),
      binanceKlinesApiProvider.overrideWithValue(klines),
      chartSignalApiProvider.overrideWithValue(signalsApi),
      klineStreamProvider.overrideWithValue(stream),
      coinOverviewApiProvider.overrideWithValue(overviewApi),
      analysisHistoryApiProvider.overrideWithValue(historyApi),
      priceAlertApiProvider.overrideWithValue(alertsApi),
      appConfigApiProvider.overrideWithValue(_FakeAppConfigApi(config)),
      if (clock != null) overviewClockProvider.overrideWithValue(clock),
    ],
  );
  _lastContainer = container;
  // The shell would select the chart tab; there is no shell here.
  container.read(homeTabProvider.notifier).select(chartTabIndex);

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
        home: const ChartScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ChartHarness(
    container,
    overviewApi,
    historyApi,
    alertsApi,
    stream,
    klines,
    signalsApi,
  );
}

ProviderContainer? _lastContainer;

/// Unmounts the app and disposes the container so the live chart's timers
/// are cancelled before the test ends.
Future<void> disposeChartScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  _lastContainer?.dispose();
  _lastContainer = null;
  await tester.pump(const Duration(seconds: 1));
}
