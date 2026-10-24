import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';
import 'package:kriptoanaliz/models/price_alert.dart';
import 'package:kriptoanaliz/models/structured_analysis.dart';
import 'package:kriptoanaliz/providers/coin_overview_provider.dart';
import 'package:kriptoanaliz/screens/price_alert_sheet.dart';
import 'package:kriptoanaliz/utils/price_alert_logic.dart';
import 'package:kriptoanaliz/widgets/pro_upsell_sheet.dart';
import 'package:kriptoanaliz/widgets/candlestick_chart.dart';
import 'package:kriptoanaliz/widgets/chart_tabs/signals_tab.dart';

import 'helpers/chart_harness.dart';

final _now = DateTime.utc(2026, 10, 21, 12);

AnalysisRecord _record({
  required int id,
  String type = 'quick',
  int coinId = 1,
  String result = 'Plain result text',
  StructuredAnalysis? structured,
  bool cached = false,
  Duration age = const Duration(hours: 2),
}) => AnalysisRecord(
  id: id,
  type: type,
  coinId: coinId,
  symbol: coinId == 1 ? 'BTCUSDT' : 'ETHUSDT',
  marketType: 'spot',
  timeframe: '1h',
  result: result,
  creditCost: 2,
  createdAt: _now.subtract(age),
  structured: structured,
  cached: cached,
);

List<AnalysisRecord> _records() => [
  _record(
    id: 1,
    type: 'deep',
    result: 'FULL DEEP TEXT',
    structured: StructuredAnalysis.tryParse({
      'bias': 'bullish',
      'confidence': 72,
      'summary': 'Short deep summary',
    }),
    cached: true,
  ),
  _record(id: 2, result: 'First line of quick\nSecond line'),
  _record(id: 3, coinId: 7, result: 'OTHER COIN TEXT'),
];

PriceAlert _alert(
  int id, {
  int coinId = 1,
  double price = 110,
  PriceAlertStatus status = PriceAlertStatus.active,
}) => PriceAlert(
  id: id,
  coinId: coinId,
  symbol: 'BTCUSDT',
  marketType: 'spot',
  targetPrice: price,
  direction: AlertDirection.above,
  status: status,
);

Finder _tabLabel(String label) => find.descendant(
  of: find.byKey(const Key('chart-tab-bar')),
  matching: find.text(label),
);

Finder _buttonLabel(String key, String label) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.text(label));

Finder _costPill(String key, String cost) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.descendant(
    of: find.byKey(const Key('analysis-cost-pill')),
    matching: find.text(cost),
  ),
);

Future<void> _openTab(WidgetTester tester, String label) async {
  final f = _tabLabel(label);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _scrollPageUp(WidgetTester tester, double dy) async {
  await tester.dragFrom(const Offset(180, 740), Offset(0, -dy));
  await tester.pumpAndSettle();
}

void main() {
  group('page structure', () {
    testWidgets('chart, cost buttons, then the sticky tab bar with 5 tabs', (
      tester,
    ) async {
      await pumpChartScreen(tester);
      expect(find.byType(CandlestickChart), findsOneWidget);
      expect(_buttonLabel('quick-analysis-button', 'Quick analysis'), findsOne);
      expect(_buttonLabel('deep-analysis-button', 'Deep analysis'), findsOne);
      expect(_costPill('quick-analysis-button', '2'), findsOne);
      expect(_costPill('deep-analysis-button', '5'), findsOne);
      for (final l in [
        'Summary',
        'My analyses',
        'Market',
        'Signals',
        'Alerts',
      ]) {
        expect(_tabLabel(l), findsOneWidget, reason: l);
      }

      // Order: chart above the buttons above the tab bar.
      final chartY = tester
          .getTopLeft(find.byKey(const Key('chart-area'), skipOffstage: false))
          .dy;
      final btnY = tester
          .getTopLeft(find.byKey(const Key('quick-analysis-button')))
          .dy;
      final barY = tester.getTopLeft(find.byKey(const Key('chart-tab-bar'))).dy;
      expect(chartY, lessThan(btnY));
      expect(btnY, lessThan(barY));
      await disposeChartScreen(tester);
    });

    testWidgets('the tab bar stays pinned under the app bar while scrolling', (
      tester,
    ) async {
      await pumpChartScreen(tester);
      final before = tester
          .getTopLeft(find.byKey(const Key('chart-tab-bar')))
          .dy;
      expect(before, greaterThan(kToolbarHeight));

      await _scrollPageUp(tester, 600);
      final after = tester
          .getTopLeft(find.byKey(const Key('chart-tab-bar')))
          .dy;
      expect(after, kToolbarHeight);
      // The chart scrolled away while the bar stayed.
      expect(
        tester
            .getBottomLeft(
              find.byKey(const Key('chart-area'), skipOffstage: false),
            )
            .dy,
        lessThan(kToolbarHeight + 1),
      );
      expect(tester.takeException(), isNull);
      await disposeChartScreen(tester);
    });

    testWidgets('button costs follow the app config', (tester) async {
      await pumpChartScreen(
        tester,
        config: const AppConfig(
          plan: PlanConfig(quickAnalysisCost: 3, deepAnalysisCost: 7),
        ),
      );
      expect(_costPill('quick-analysis-button', '3'), findsOne);
      expect(_costPill('deep-analysis-button', '7'), findsOne);
      await disposeChartScreen(tester);
    });

    testWidgets('Turkish labels', (tester) async {
      await pumpChartScreen(tester, locale: 'tr');
      expect(_buttonLabel('quick-analysis-button', 'Hızlı analiz'), findsOne);
      expect(_buttonLabel('deep-analysis-button', 'Derin analiz'), findsOne);
      expect(_tabLabel('Özet'), findsOneWidget);
      expect(_tabLabel('Analizlerim'), findsOneWidget);
      expect(_tabLabel('Piyasa'), findsOneWidget);
      expect(_tabLabel('Sinyaller'), findsOneWidget);
      expect(_tabLabel('Alarmlar'), findsOneWidget);
      expect(find.text('Veri: CoinMarketCap, Binance'), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('analysis buttons keep working', () {
    testWidgets('guest quick analysis asks to log in', (tester) async {
      await pumpChartScreen(tester, member: null);
      await tester.tap(find.byKey(const Key('quick-analysis-button')));
      await tester.pump();
      expect(find.text('You need to log in'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('guest deep analysis asks to log in', (tester) async {
      await pumpChartScreen(tester, member: null);
      await tester.tap(find.byKey(const Key('deep-analysis-button')));
      await tester.pump();
      expect(find.text('You need to log in'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('free member sees the Pro upsell for deep analysis', (
      tester,
    ) async {
      await pumpChartScreen(tester);
      // Locked by the default plan: lock + PRO badge on the button.
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      await tester.tap(find.byKey(const Key('deep-analysis-button')));
      await tester.pumpAndSettle();
      expect(find.text('Deep analysis is a Pro feature'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('Pro members are not gated and see no lock', (tester) async {
      await pumpChartScreen(tester, member: proMemberForChart);
      expect(
        find.descendant(
          of: find.byKey(const Key('deep-analysis-button')),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      await disposeChartScreen(tester);
    });

    testWidgets('free plan without the deep gate is not locked', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        config: const AppConfig(
          plan: PlanConfig(deepAnalysisRequiresPro: false),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('deep-analysis-button')),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      await disposeChartScreen(tester);
    });
  });

  group('tab switching', () {
    testWidgets('keeps the chart instance and the live stream', (tester) async {
      final h = await pumpChartScreen(tester, member: proMemberForChart);
      final chartWidget = tester.widget(find.byType(CandlestickChart));
      final chartElement = tester.element(find.byType(CandlestickChart));
      expect(h.stream.connects, 1);
      expect(h.klines.calls, 1);

      for (final l in [
        'My analyses',
        'Market',
        'Signals',
        'Alerts',
        'Summary',
      ]) {
        await _openTab(tester, l);
        expect(
          identical(tester.widget(find.byType(CandlestickChart)), chartWidget),
          isTrue,
          reason: 'chart rebuilt on $l',
        );
        expect(
          identical(
            tester.element(find.byType(CandlestickChart)),
            chartElement,
          ),
          isTrue,
        );
      }
      expect(h.stream.connects, 1, reason: 'stream must not restart');
      expect(h.klines.calls, 1, reason: 'history must not reload');
      await disposeChartScreen(tester);
    });

    testWidgets('tabs load only when first opened', (tester) async {
      final h = await pumpChartScreen(
        tester,
        member: proMemberForChart,
        history: _records(),
      );
      expect(h.overview.calls, 1, reason: 'Summary loads on first display');
      expect(h.history.calls, 0);
      // The app bar bell already loads the alerts for Pro members.
      final alertCallsAtStart = h.alerts.calls;

      await _openTab(tester, 'My analyses');
      expect(h.history.calls, 1);
      expect(h.history.lastCoinId, 1, reason: 'asks the server for this coin');

      await _openTab(tester, 'Alerts');
      expect(h.alerts.calls, alertCallsAtStart, reason: 'shared provider');

      // Back and forth: no refetch.
      await _openTab(tester, 'My analyses');
      await _openTab(tester, 'Alerts');
      await _openTab(tester, 'Summary');
      await _openTab(tester, 'Market');
      expect(h.history.calls, 1);
      expect(h.alerts.calls, alertCallsAtStart);
      expect(h.overview.calls, 1, reason: 'Market shares the cached overview');
      await disposeChartScreen(tester);
    });

    testWidgets('different tab heights share one scroll view', (tester) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        history: _records(),
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
      final summaryEnd = tester
          .getBottomLeft(find.byKey(const Key('overview-attribution')))
          .dy;
      await _openTab(tester, 'Signals');
      expect(find.byKey(const Key('overview-attribution')), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(summaryEnd, greaterThan(0));
      await disposeChartScreen(tester);
    });
  });

  group('analysis buttons and tab bar', () {
    for (final locale in ['en', 'tr', 'es']) {
      testWidgets('buttons sit on one line at 360dp ($locale)', (tester) async {
        await pumpChartScreen(tester, locale: locale);
        final quick = tester.getRect(
          find.byKey(const Key('quick-analysis-button')),
        );
        final deep = tester.getRect(
          find.byKey(const Key('deep-analysis-button')),
        );
        // Side by side, each a single line tall (Material button ~40-52dp).
        expect(quick.top, closeTo(deep.top, 1));
        expect(quick.height, lessThanOrEqualTo(52));
        expect(deep.height, lessThanOrEqualTo(52));
        for (final k in ['quick-analysis-button', 'deep-analysis-button']) {
          final label = find.descendant(
            of: find.byKey(Key(k)),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  (w.data == 'Quick analysis' ||
                      w.data == 'Deep analysis' ||
                      w.data == 'Hızlı analiz' ||
                      w.data == 'Derin analiz' ||
                      w.data == 'Análisis rápido' ||
                      w.data == 'Análisis profundo'),
            ),
          );
          expect(label, findsOneWidget);
          expect(tester.widget<Text>(label).maxLines, 1, reason: k);
          // Label and pill share one row.
          final pill = tester.getRect(
            find.descendant(
              of: find.byKey(Key(k)),
              matching: find.byKey(const Key('analysis-cost-pill')),
            ),
          );
          expect(pill.height, lessThan(30));
        }
        expect(tester.takeException(), isNull);
        await disposeChartScreen(tester);
      });

      testWidgets('buttons do not overflow at 1.6 text scale ($locale)', (
        tester,
      ) async {
        await pumpChartScreen(tester, locale: locale, textScale: 1.6);
        expect(find.byKey(const Key('quick-analysis-button')), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Large text stacks the buttons.
        final quick = tester.getRect(
          find.byKey(const Key('quick-analysis-button')),
        );
        final deep = tester.getRect(
          find.byKey(const Key('deep-analysis-button')),
        );
        expect(deep.top, greaterThan(quick.bottom - 1));
        await disposeChartScreen(tester);
      });
    }

    testWidgets('a Pro-locked deep button still fits on one line', (
      tester,
    ) async {
      await pumpChartScreen(tester, locale: 'es');
      expect(find.byType(ProBadge), findsOneWidget);
      final deep = tester.getRect(
        find.byKey(const Key('deep-analysis-button')),
      );
      expect(deep.height, lessThanOrEqualTo(52));
      expect(tester.takeException(), isNull);
      await disposeChartScreen(tester);
    });

    for (final locale in ['en', 'tr', 'es']) {
      testWidgets('last tab is whole or the bar fades ($locale)', (
        tester,
      ) async {
        await pumpChartScreen(tester, locale: locale);
        final last = {
          'en': 'Alerts',
          'tr': 'Alarmlar',
          'es': 'Alertas',
        }[locale]!;
        final right = tester.getTopRight(_tabLabel(last)).dx;
        final fade = find.byKey(const Key('chart-tab-bar-fade'));
        expect(
          right <= 360 || fade.evaluate().isNotEmpty,
          isTrue,
          reason: 'last tab ends at $right with no fade',
        );
        await disposeChartScreen(tester);
      });
    }

    testWidgets('a clipped tab bar shows the edge fade', (tester) async {
      await pumpChartScreen(tester, size: const Size(300, 800));
      expect(find.byKey(const Key('chart-tab-bar-fade')), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('Summary tab', () {
    for (final scale in [1.0, 1.6]) {
      testWidgets('four change pills share one row (text scale $scale)', (
        tester,
      ) async {
        await pumpChartScreen(tester, textScale: scale);
        final tops = [
          for (final l in ['24h', '7d', '30d', '90d'])
            tester.getTopLeft(find.text(l).first).dy,
        ];
        expect(
          tops.every((t) => (t - tops.first).abs() < 8),
          isTrue,
          reason: 'the 24h/7d/30d/90d pills must sit on a single row: $tops',
        );
        expect(tester.takeException(), isNull);
        await disposeChartScreen(tester);
      });
    }

    testWidgets('full data', (tester) async {
      await pumpChartScreen(tester);
      expect(find.text('Bitcoin'), findsWidgets);
      expect(find.byKey(const Key('overview-rank')), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Market cap'), findsOneWidget);
      expect(find.text('\$1.6T'), findsOneWidget);
      expect(find.text('FDV'), findsOneWidget);
      expect(find.text('Volume / market cap'), findsOneWidget);
      expect(find.text('2.8%'), findsOneWidget);
      expect(find.text('24h volume'), findsOneWidget);
      expect(find.byKey(const Key('overview-supply-progress')), findsOneWidget);
      expect(
        find.text('94% of the max supply is in circulation'),
        findsOneWidget,
      );
      expect(
        find.text('+1.50%'),
        findsNWidgets(2),
        reason: 'header + 24h chip',
      );
      expect(find.text('-12.50%'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('All-time high'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('All-time low'), findsOneWidget);
      // ATH / ATL: currency with separators, readable distance percent.
      expect(find.text('\$126,000'), findsOneWidget);
      expect(find.text('\$67.81'), findsOneWidget);
      expect(find.text('-35.2% from current price'), findsOneWidget);
      expect(find.text('+120,000% from current price'), findsOneWidget);
      expect(find.text('Layer 1'), findsOneWidget);
      expect(find.text('pow'), findsOneWidget);
      expect(find.text('New listing'), findsNothing);
      expect(find.text('Data: CoinMarketCap, Binance'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('null rows are hidden and new listing shows its badge', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        overview: () async => CoinOverview.parse({
          'summary': {
            'name': 'Newcoin',
            'market_cap': 5000000,
            'new_listing': true,
            'listing_age_days': 3,
          },
        }),
      );
      expect(find.text('Newcoin'), findsWidgets);
      expect(find.byKey(const Key('overview-new-listing')), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('Market cap'), findsOneWidget);
      expect(find.text('FDV'), findsNothing);
      expect(find.text('24h volume'), findsNothing);
      expect(find.text('Supply'), findsNothing);
      expect(find.text('Price change'), findsNothing);
      expect(find.byKey(const Key('overview-rank')), findsNothing);
      await disposeChartScreen(tester);
    });

    testWidgets('empty state when summary is null', (tester) async {
      await pumpChartScreen(tester, overview: () async => CoinOverview.empty);
      expect(
        find.text('No summary available for this coin yet.'),
        findsOneWidget,
      );
      await disposeChartScreen(tester);
    });

    testWidgets('skeleton while loading, error with retry afterwards', (
      tester,
    ) async {
      final gate = Completer<CoinOverview>();
      var fail = true;
      final h = await pumpChartScreen(
        tester,
        overview: () => fail
            ? gate.future
            : Future.value(CoinOverview.parse(fullOverviewJson())),
      );
      expect(find.byKey(const Key('tab-skeleton')), findsOneWidget);
      gate.completeError(Exception('down'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-error')), findsOneWidget);
      expect(find.text('Could not load this section.'), findsOneWidget);

      fail = false;
      final retry = find.descendant(
        of: find.byKey(const Key('tab-error')),
        matching: find.text('Try again'),
      );
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-error')), findsNothing);
      expect(find.text('Market cap'), findsOneWidget);
      expect(h.overview.calls, 2);
      await disposeChartScreen(tester);
    });

    testWidgets('glossary help opens the glossary on the term', (tester) async {
      await pumpChartScreen(tester);
      await tester.tap(find.byKey(const Key('glossary-marketcap')));
      await tester.pumpAndSettle();
      expect(find.text('Glossary of technical terms'), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('Market tab', () {
    testWidgets('futures coin shows derivatives, liquidity and activity', (
      tester,
    ) async {
      await pumpChartScreen(tester, coin: chartTestFuturesCoin);
      await _openTab(tester, 'Market');
      expect(find.byKey(const Key('market-futures')), findsOneWidget);
      expect(find.text('Funding rate'), findsOneWidget);
      expect(find.byKey(const Key('market-funding-rate')), findsOneWidget);
      expect(find.text('+0.0100%'), findsOneWidget);
      expect(find.byKey(const Key('market-gauge')), findsOneWidget);
      expect(find.textContaining('Funding is high'), findsOneWidget);
      expect(find.text('Open interest change'), findsOneWidget);
      expect(find.text('+8.00%'), findsOneWidget);
      expect(find.text('Long share 56%'), findsOneWidget);
      expect(find.text('1.27'), findsOneWidget);
      expect(find.text('Taker buy / sell'), findsOneWidget);
      expect(find.text('Basis (futures vs spot)'), findsOneWidget);
      expect(find.byKey(const Key('glossary-funding')), findsOneWidget);
      expect(find.byKey(const Key('glossary-openinterest')), findsOneWidget);
      expect(find.byKey(const Key('glossary-basis')), findsOneWidget);
      expect(find.byKey(const Key('market-spot-note')), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('market-activity')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('market-liquidity')), findsOneWidget);
      expect(find.text('0.8 bps'), findsOneWidget);
      expect(find.text('±1%'), findsOneWidget);
      expect(find.text('±2%'), findsOneWidget);
      expect(find.textContaining('not a signal'), findsOneWidget);
      expect(find.text('1/300'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('spot coin: only liquidity and activity plus a note', (
      tester,
    ) async {
      await pumpChartScreen(tester);
      await _openTab(tester, 'Market');
      expect(find.byKey(const Key('market-spot-note')), findsOneWidget);
      expect(find.byKey(const Key('market-futures')), findsNothing);
      expect(find.text('Funding rate'), findsNothing);
      expect(find.byKey(const Key('market-liquidity')), findsOneWidget);
      expect(find.byKey(const Key('market-activity')), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('real samples reach the UI: SUI futures and BTC spot', (
      tester,
    ) async {
      Future<CoinOverview> sample(String f) async => CoinOverview.parse(
        jsonDecode(File('test/fixtures/$f').readAsStringSync()),
      );
      await pumpChartScreen(
        tester,
        coin: chartTestFuturesCoin,
        overview: () => sample('overview_sui_futures.json'),
      );
      expect(find.text('Data: Binance'), findsOneWidget);
      await _openTab(tester, 'Market');
      expect(find.text('+0.0051%'), findsOneWidget);
      expect(find.text('Long share 67%'), findsOneWidget);
      expect(find.text('2.00'), findsOneWidget, reason: 'top trader 2.002');
      expect(find.text('1.01 bps', skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('market-activity')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('22/740'), findsOneWidget);
      expect(find.text('active futures USDT coins'), findsOneWidget);
      expect(find.byKey(const Key('market-depth-incomplete')), findsNothing);
      await disposeChartScreen(tester);

      await pumpChartScreen(
        tester,
        overview: () => sample('overview_btc_spot.json'),
      );
      await _openTab(tester, 'Market');
      expect(find.byKey(const Key('market-spot-note')), findsOneWidget);
      expect(find.text('±0.1%'), findsOneWidget);
      expect(
        find.text('Depth is thin: only the covered window of ±0.1% is shown'),
        findsOneWidget,
      );
      await disposeChartScreen(tester);
    });

    testWidgets('low funding percentile and negative basis hints', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        coin: chartTestFuturesCoin,
        overview: () async => CoinOverview.parse({
          'market': {
            'futures': {
              'funding_rate_pct': -0.02,
              'funding_percentile': 10,
              'basis_pct': -0.4,
              'taker_buy_sell_24h': 0.5,
            },
          },
        }),
      );
      await _openTab(tester, 'Market');
      expect(find.textContaining('Funding is low'), findsOneWidget);
      expect(find.text('Futures trade below spot (discount).'), findsOneWidget);
      expect(
        find.text('Aggressive sellers dominate recent trades.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('market-liquidity')), findsNothing);
      expect(find.byKey(const Key('market-activity')), findsNothing);
      await disposeChartScreen(tester);
    });

    testWidgets('empty and error states', (tester) async {
      await pumpChartScreen(tester, overview: () async => CoinOverview.empty);
      await _openTab(tester, 'Market');
      expect(find.text('No market data for this coin yet.'), findsOneWidget);
      await disposeChartScreen(tester);

      await pumpChartScreen(
        tester,
        overview: () => Future<CoinOverview>.error(Exception('x')),
      );
      await _openTab(tester, 'Market');
      expect(find.byKey(const Key('tab-error')), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('My analyses tab', () {
    testWidgets('lists this coin only, with chips, bias and summary', (
      tester,
    ) async {
      final h = await pumpChartScreen(
        tester,
        history: _records(),
        clock: () => _now,
      );
      await _openTab(tester, 'My analyses');
      expect(h.history.calls, 1);
      expect(find.text('Deep'), findsOneWidget);
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Short deep summary'), findsOneWidget);
      expect(find.text('First line of quick'), findsOneWidget);
      expect(find.textContaining('Second line'), findsNothing);
      expect(find.textContaining('72%'), findsOneWidget);
      expect(find.byKey(const Key('analysis-cached')), findsOneWidget);
      expect(find.text('2 h ago'), findsNWidgets(2));
      expect(
        find.textContaining('OTHER COIN TEXT'),
        findsNothing,
        reason: 'client-side filter when the server ignores coin_id',
      );
      await disposeChartScreen(tester);
    });

    testWidgets('tapping opens the stored result', (tester) async {
      await pumpChartScreen(tester, history: _records(), clock: () => _now);
      await _openTab(tester, 'My analyses');
      await tester.tap(find.text('First line of quick'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Second line'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('empty state encourages the first analysis', (tester) async {
      await pumpChartScreen(tester, history: [_record(id: 9, coinId: 7)]);
      await _openTab(tester, 'My analyses');
      expect(find.text('No analyses of this coin yet'), findsOneWidget);
      expect(
        find.textContaining('first quick or deep analysis'),
        findsOneWidget,
      );
      await disposeChartScreen(tester);
    });

    testWidgets('guests get a login prompt and no request', (tester) async {
      final h = await pumpChartScreen(tester, member: null);
      await _openTab(tester, 'My analyses');
      expect(
        find.text('Log in to see your analyses of this coin'),
        findsOneWidget,
      );
      expect(find.text('Log in'), findsOneWidget);
      expect(h.history.calls, 0);
      await disposeChartScreen(tester);
    });

    testWidgets('error state with retry', (tester) async {
      final h = await pumpChartScreen(tester, history: _records());
      h.history.error = Exception('down');
      await _openTab(tester, 'My analyses');
      expect(find.byKey(const Key('tab-error')), findsOneWidget);
      h.history.error = null;
      final retry = find.text('Try again');
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tab-error')), findsNothing);
      expect(find.text('Short deep summary'), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('Signals tab', () {
    testWidgets('free members see strength 1-2 with price and move', (
      tester,
    ) async {
      await pumpChartScreen(tester);
      await _openTab(tester, 'Signals');
      // Strength 3 is hidden for Free, 2 rows remain, newest first.
      expect(find.byType(SignalRow), findsNWidgets(2));
      expect(find.text('Strength 3/3'), findsNothing);
      expect(find.text('Buy'), findsOneWidget);
      expect(find.text('Sell'), findsOneWidget);
      expect(find.text('At signal 105'), findsOneWidget);
      expect(find.text('At signal 112'), findsOneWidget);
      // Last close is 129: (129-105)/105.
      expect(find.text('+22.86% since'), findsOneWidget);
      expect(find.text('+15.18% since'), findsOneWidget);
      final sell = tester.getTopLeft(find.text('Sell')).dy;
      final buy = tester.getTopLeft(find.text('Buy')).dy;
      expect(sell, lessThan(buy), reason: 'newest (sell) first');
      await disposeChartScreen(tester);
    });

    testWidgets('Pro members also see the strongest signals', (tester) async {
      await pumpChartScreen(tester, member: proMemberForChart);
      await _openTab(tester, 'Signals');
      expect(find.byType(SignalRow), findsNWidgets(3));
      expect(find.text('Strength 3/3'), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('tapping a row selects it and brings the chart back', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        size: const Size(360, 560),
      );
      await _openTab(tester, 'Signals');
      await _scrollPageUp(tester, 500);
      expect(
        tester
            .getBottomLeft(
              find.byKey(const Key('chart-area'), skipOffstage: false),
            )
            .dy,
        lessThan(kToolbarHeight + 1),
      );
      final row = find.byType(SignalRow).first;
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(
              find.byKey(const Key('chart-area'), skipOffstage: false),
            )
            .dy,
        greaterThan(0),
        reason: 'chart scrolled back into view',
      );
      final card = tester.widget<Card>(
        find
            .descendant(
              of: find.byType(SignalRow).first,
              matching: find.byType(Card),
            )
            .first,
      );
      expect(card.color, isNotNull, reason: 'selected row is highlighted');
      await disposeChartScreen(tester);
    });

    testWidgets('empty state', (tester) async {
      await pumpChartScreen(tester, member: proMemberForChart);
      // 1w has no signal support.
      await tester.scrollUntilVisible(
        find.text('1w'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('1w'));
      await tester.pumpAndSettle();
      await _openTab(tester, 'Signals');
      expect(
        find.textContaining('available in the 15m, 1h, 4h and 1d'),
        findsNothing,
      );
      expect(find.textContaining('15m, 1h, 4h and 1d'), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('Alerts tab', () {
    testWidgets('guests get a login prompt', (tester) async {
      final h = await pumpChartScreen(tester, member: null);
      await _openTab(tester, 'Alerts');
      expect(find.text('Log in to set price alerts'), findsOneWidget);
      expect(h.alerts.calls, 0);
      await disposeChartScreen(tester);
    });

    testWidgets('Free members see the Pro upsell', (tester) async {
      await pumpChartScreen(tester);
      await _openTab(tester, 'Alerts');
      expect(find.byKey(const Key('alerts-pro-upsell')), findsOneWidget);
      expect(find.text('Price alerts are a Pro feature'), findsOneWidget);
      expect(find.byKey(const Key('alerts-add')), findsNothing);
      await disposeChartScreen(tester);
    });

    testWidgets('Pro members see this coin\'s alerts and can add one', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        alerts: () async => PriceAlertList(
          alerts: [
            _alert(1, price: 110),
            _alert(2, coinId: 7, price: 999),
            _alert(3, price: 90, status: PriceAlertStatus.triggered),
          ],
        ),
      );
      await _openTab(tester, 'Alerts');
      expect(find.text('Above 110'), findsOneWidget);
      expect(find.text('Above 90'), findsOneWidget);
      expect(find.text('Above 999'), findsNothing);
      expect(find.text('Triggered'), findsOneWidget);
      expect(find.text('Active alerts for this coin'), findsOneWidget);

      await tester.tap(find.byKey(const Key('alerts-add')));
      await tester.pumpAndSettle();
      expect(find.byType(PriceAlertSheet), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('empty state offers the add button', (tester) async {
      await pumpChartScreen(tester, member: proMemberForChart);
      await _openTab(tester, 'Alerts');
      expect(find.text('No alerts for this coin yet.'), findsOneWidget);
      expect(find.byKey(const Key('alerts-add')), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('error state with retry', (tester) async {
      var fail = true;
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        alerts: () => fail
            ? Future<PriceAlertList>.error(Exception('x'))
            : Future.value(PriceAlertList(alerts: [_alert(1)])),
      );
      await _openTab(tester, 'Alerts');
      expect(find.byKey(const Key('tab-error')), findsOneWidget);
      fail = false;
      final retry = find.text('Try again');
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Above 110'), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('refresh', () {
    testWidgets('pull-to-refresh reloads the active tab', (tester) async {
      var clock = _now;
      final h = await pumpChartScreen(tester, clock: () => clock);
      expect(h.overview.calls, 1);
      // Inside the cache TTL a refresh still refetches (forced).
      clock = clock.add(const Duration(seconds: 5));
      await tester.dragFrom(const Offset(180, 700), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(h.overview.calls, 2);
      await disposeChartScreen(tester);
    });

    testWidgets('data older than 3 minutes is refetched when the tab reopens', (
      tester,
    ) async {
      var clock = _now;
      final h = await pumpChartScreen(tester, clock: () => clock);
      await _openTab(tester, 'Signals');
      clock = clock.add(overviewCacheTtl + const Duration(seconds: 1));
      await _openTab(tester, 'Market');
      expect(h.overview.calls, 2);
      await disposeChartScreen(tester);
    });
  });

  group('layout', () {
    Future<void> walkTabs(WidgetTester tester) async {
      for (final l in [
        'Summary',
        'My analyses',
        'Market',
        'Signals',
        'Alerts',
      ]) {
        await _openTab(tester, l);
        await tester.dragFrom(const Offset(180, 740), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'overflow on $l');
        await tester.dragFrom(const Offset(180, 200), const Offset(0, 900));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('360dp at 1.6 text scale: no overflow in any tab', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        coin: chartTestFuturesCoin,
        history: _records(),
        textScale: 1.6,
        clock: () => _now,
        alerts: () async => PriceAlertList(
          alerts: [
            _alert(1),
            _alert(2, status: PriceAlertStatus.canceled),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      await walkTabs(tester);
      await disposeChartScreen(tester);
    });

    testWidgets('360dp at 1.0 text scale: no overflow in any tab', (
      tester,
    ) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        coin: chartTestFuturesCoin,
        history: _records(),
        clock: () => _now,
        alerts: () async => PriceAlertList(alerts: [_alert(1)]),
      );
      await walkTabs(tester);
      await disposeChartScreen(tester);
    });

    testWidgets('dark theme smoke test, every tab', (tester) async {
      await pumpChartScreen(
        tester,
        member: proMemberForChart,
        coin: chartTestFuturesCoin,
        history: _records(),
        brightness: Brightness.dark,
        clock: () => _now,
        alerts: () async => PriceAlertList(alerts: [_alert(1)]),
      );
      await walkTabs(tester);
      await disposeChartScreen(tester);
    });

    testWidgets('Turkish and Spanish render every tab', (tester) async {
      for (final locale in ['tr', 'es']) {
        await pumpChartScreen(
          tester,
          member: proMemberForChart,
          coin: chartTestFuturesCoin,
          history: _records(),
          locale: locale,
          textScale: 1.6,
          clock: () => _now,
          alerts: () async => PriceAlertList(alerts: [_alert(1)]),
        );
        final labels = locale == 'tr'
            ? ['Özet', 'Analizlerim', 'Piyasa', 'Sinyaller', 'Alarmlar']
            : ['Resumen', 'Mis análisis', 'Mercado', 'Señales', 'Alertas'];
        for (final l in labels) {
          await _openTab(tester, l);
          expect(tester.takeException(), isNull, reason: '$locale $l');
        }
        await disposeChartScreen(tester);
      }
    });
  });

  group('plan costs parsing', () {
    test('defaults when the server says nothing', () {
      expect(PlanConfig.safeDefaults.quickAnalysisCost, 2);
      expect(PlanConfig.safeDefaults.deepAnalysisCost, 5);
      final c = AppConfig.fromJson({
        'plan': {'role': 'user'},
      });
      expect(c.plan.quickAnalysisCost, 2);
      expect(c.plan.deepAnalysisCost, 5);
    });

    test('plan-level, grouped and top-level costs', () {
      expect(
        AppConfig.fromJson({
          'plan': {'quick_analysis_cost': 3, 'deep_analysis_cost': 8},
        }).plan.deepAnalysisCost,
        8,
      );
      final grouped = AppConfig.fromJson({
        'plan': {
          'analysis_costs': {'quick': 4, 'deep': 9},
        },
      }).plan;
      expect(grouped.quickAnalysisCost, 4);
      expect(grouped.deepAnalysisCost, 9);
      final top = AppConfig.fromJson({
        'plan': {'role': 'pro'},
        'quick_analysis_cost': 1,
        'deep_analysis_cost': 6,
      }).plan;
      expect(top.quickAnalysisCost, 1);
      expect(top.deepAnalysisCost, 6);
    });

    test('garbage falls back to defaults and survives the plan cache', () {
      final p = PlanConfig.fromJson({
        'quick_analysis_cost': 'many',
        'deep_analysis_cost': -3,
      });
      expect(p.quickAnalysisCost, 2);
      expect(p.deepAnalysisCost, 5);
      final round = PlanConfig.fromJson(
        const PlanConfig(quickAnalysisCost: 7, deepAnalysisCost: 11).toJson(),
      );
      expect(round.quickAnalysisCost, 7);
      expect(round.deepAnalysisCost, 11);
    });
  });
}
