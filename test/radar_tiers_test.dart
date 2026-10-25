import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/radar_item.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/radar_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/screens/radar_screen.dart';
import 'package:kriptoanaliz/utils/radar_tiers.dart';
import 'package:kriptoanaliz/widgets/radar/radar_widgets.dart';

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

class _FakeSelected extends SelectedCoinNotifier {
  @override
  Future<Coin?> build() async => null;

  @override
  Future<void> select(Coin coin) async {
    state = AsyncData(coin);
  }
}

RadarItem _item(
  int id,
  String symbol,
  int score, {
  String term = 'short',
  String tf = '15m',
  double? change = -3.2,
}) => RadarItem(
  id: id,
  term: term,
  timeframe: tf,
  technicalScore: score,
  rsi: 24.5,
  lastClose: 1,
  detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  coin: Coin(
    id: id,
    symbol: symbol,
    name: symbol,
    marketType: 'spot',
    lastPrice: 1,
    priceChangePercent24h: change,
    volume24h: 1,
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<RadarItem> all, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      adsControllerProvider.overrideWith(_NoAds.new),
      selectedCoinProvider.overrideWith(_FakeSelected.new),
      radarProvider.overrideWith(
        (ref, term) =>
            term == null ? all : all.where((i) => i.term == term).toList(),
      ),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const RadarScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return c;
}

void main() {
  test('tier thresholds', () {
    expect(radarStrongMin, 60);
    expect(radarGoodMin, 45);
    expect(radarWatchMin, 35);
    expect(radarTierFor(100), RadarTier.strong);
    expect(radarTierFor(60), RadarTier.strong);
    expect(radarTierFor(59), RadarTier.good);
    expect(radarTierFor(45), RadarTier.good);
    expect(radarTierFor(44), RadarTier.watch);
    expect(radarTierFor(35), RadarTier.watch);
    expect(radarTierFor(34), RadarTier.weak);
    expect(radarTierFor(0), RadarTier.weak);
  });

  test('tier styles differ per tier, strong has a gradient', () {
    for (final b in Brightness.values) {
      final styles = RadarTier.values.map((t) => radarTierStyle(t, b)).toList();
      expect(styles.map((s) => '${s.accent}/${s.accentEnd}').toSet().length, 4);
      expect(radarTierStyle(RadarTier.strong, b).hasGradient, isTrue);
      expect(radarTierStyle(RadarTier.good, b).hasGradient, isFalse);
    }
  });

  testWidgets('hero shows the highest score and opens the chart', (
    tester,
  ) async {
    final c = await _pump(tester, [
      _item(1, 'AAAUSDT', 41),
      _item(2, 'TOPUSDT', 66, term: 'medium', tf: '1h'),
      _item(3, 'BBBUSDT', 52, term: 'long', tf: '4h'),
    ]);
    c.listen(selectedCoinProvider, (_, _) {});
    expect(find.byType(RadarTopPickCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RadarTopPickCard),
        matching: find.text('TOPUSDT'),
      ),
      findsOneWidget,
    );
    expect(find.text('Top pick'.toUpperCase()), findsOneWidget);
    expect(find.text('-3.20%'), findsOneWidget);
    // Hero coin is not repeated in the list.
    expect(find.text('TOPUSDT'), findsOneWidget);
    expect(find.byType(RadarTile), findsNWidgets(2));
    expect(find.text('Strong'), findsOneWidget);

    await tester.tap(find.byType(RadarTopPickCard));
    await tester.pump();
    expect(c.read(selectedCoinProvider).value?.symbol, 'TOPUSDT');
    expect(c.read(homeTabProvider), chartTabIndex);
  });

  testWidgets('term chips show counts and filter', (tester) async {
    await _pump(tester, [
      _item(1, 'AAAUSDT', 41),
      _item(2, 'BBBUSDT', 52, term: 'medium', tf: '1h'),
      _item(3, 'CCCUSDT', 38, term: 'medium', tf: '1h'),
    ]);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('15m'), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('AAAUSDT'), findsNothing);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, []);
    expect(find.byType(RadarEmptyState), findsOneWidget);
    expect(find.text('No oversold coins right now'), findsOneWidget);
    expect(find.byType(RadarTopPickCard), findsNothing);
  });

  testWidgets('info icon opens the explainer sheet', (tester) async {
    await _pump(tester, [_item(1, 'AAAUSDT', 41)]);
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('How radar works'), findsWidgets);
    expect(find.textContaining('not financial advice'), findsOneWidget);
    expect(find.textContaining('60+ Strong'), findsOneWidget);
  });

  for (final locale in ['en', 'tr', 'es']) {
    for (final b in Brightness.values) {
      testWidgets('no overflow at 360dp x1.6 ($locale, ${b.name})', (
        tester,
      ) async {
        final items = [
          _item(1, 'VERYLONGSYMBOLNAMEUSDT', 71, term: 'medium', tf: '1h'),
          _item(2, 'BTCUSDT', 62),
          _item(3, 'ETHUSDT', 50, term: 'long', tf: '4h'),
          _item(4, 'SOLUSDT', 40),
          _item(5, 'XRPUSDT', 31, change: null),
        ];
        await _pump(
          tester,
          items,
          locale: Locale(locale),
          brightness: b,
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty no overflow ($locale, ${b.name})', (tester) async {
        await _pump(
          tester,
          [],
          locale: Locale(locale),
          brightness: b,
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
