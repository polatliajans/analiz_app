import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart/renderer/marker_geometry.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/candle.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/widgets/candlestick_chart.dart';

void main() {
  group('MarkerGeometry', () {
    test('extent grows with strength and includes badge', () {
      expect(MarkerGeometry.extent(3), greaterThan(MarkerGeometry.extent(1)));
      expect(
        MarkerGeometry.extent(1),
        greaterThan(MarkerGeometry.gap + MarkerGeometry.badgeHeight),
      );
      expect(MarkerGeometry.clampLevel(0), 1);
      expect(MarkerGeometry.clampLevel(7), 3);
    });

    test('marker at the extreme low demands room below, not above', () {
      final pad = MarkerGeometry.neededPadding(
        min: 100,
        max: 200,
        heightPx: 300,
        buys: const [MarkerPoint(100, 3)],
        sells: const [],
      );
      expect(pad.below, MarkerGeometry.extent(3));
      expect(pad.above, 0);
    });

    test('marker far from the edge needs no padding', () {
      final pad = MarkerGeometry.neededPadding(
        min: 100,
        max: 200,
        heightPx: 300,
        buys: const [MarkerPoint(150, 3)],
        sells: const [MarkerPoint(150, 3)],
      );
      expect(pad.below, 0);
      expect(pad.above, 0);
    });

    test('expanded range leaves the reserved pixels below the low', () {
      const h = 300.0;
      final below = MarkerGeometry.extent(2);
      final r = MarkerGeometry.expandRange(
        min: 100,
        max: 200,
        heightPx: h,
        belowPx: below,
      );
      expect(r.max, 200);
      final perPx = (r.max - r.min) / h;
      // Pixel distance from the original low (100) to the new bottom edge.
      expect((100 - r.min) / perPx, closeTo(below, 1e-6));
    });

    test('both sides reserve their pixels', () {
      const h = 400.0;
      final r = MarkerGeometry.expandRange(
        min: 10,
        max: 20,
        heightPx: h,
        belowPx: 30,
        abovePx: 40,
      );
      final perPx = (r.max - r.min) / h;
      expect((10 - r.min) / perPx, closeTo(30, 1e-6));
      expect((r.max - 20) / perPx, closeTo(40, 1e-6));
    });

    test('no-op and degenerate inputs return the original range', () {
      var r = MarkerGeometry.expandRange(min: 1, max: 2, heightPx: 100);
      expect([r.min, r.max], [1, 2]);
      r = MarkerGeometry.expandRange(
        min: 5,
        max: 5,
        heightPx: 100,
        belowPx: 30,
      );
      expect([r.min, r.max], [5, 5]);
      r = MarkerGeometry.expandRange(min: 1, max: 2, heightPx: 0, belowPx: 30);
      expect([r.min, r.max], [1, 2]);
    });

    test('reservation is capped so candles stay readable', () {
      const h = 100.0;
      final r = MarkerGeometry.expandRange(
        min: 0,
        max: 10,
        heightPx: h,
        belowPx: 80,
        abovePx: 80,
      );
      final perPx = (r.max - r.min) / h;
      expect(((0 - r.min) + (r.max - 10)) / perPx, closeTo(60, 1e-6));
    });

    test('badge rect sits beyond the arrow on the correct side', () {
      final buy = MarkerGeometry.badgeRect(
        isBuy: true,
        strength: 2,
        textWidth: 6,
      );
      final sell = MarkerGeometry.badgeRect(
        isBuy: false,
        strength: 2,
        textWidth: 6,
      );
      expect(buy.top, greaterThan(MarkerGeometry.gap));
      expect(sell.bottom, lessThan(-MarkerGeometry.gap));
      expect(buy.bottom, lessThanOrEqualTo(MarkerGeometry.extent(2)));
    });
  });

  group('CandlestickChart markers', () {
    const tf = 60000;
    List<Candle> candles() => List.generate(40, (i) {
      // Downtrend to a low at index 30, spike high at index 10.
      final base = 100.0 - i * 0.5;
      final high = i == 10 ? base + 8 : base + 1;
      final low = i == 30 ? base - 6 : base - 1;
      return Candle(
        openTime: i * tf,
        open: base,
        high: high,
        low: low,
        close: base - 0.2,
      );
    });

    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('signals at extreme low/high render without exception '
          '($brightness)', (tester) async {
        final signals = [
          for (final s in [1, 2, 3])
            ChartSignal(
              candleTime: DateTime.fromMillisecondsSinceEpoch(30 * tf),
              signalType: 'buy',
              strength: s,
            ),
          ChartSignal(
            candleTime: DateTime.fromMillisecondsSinceEpoch(10 * tf),
            signalType: 'sell',
            strength: 3,
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: CandlestickChart(
                  candles: candles(),
                  signals: signals,
                  timeframeMs: tf,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(CandlestickChart), findsOneWidget);
      });
    }
  });
}
