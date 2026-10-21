import 'package:flutter/material.dart';
import 'package:k_chart/flutter_k_chart.dart';

import '../l10n/app_localizations.dart';
import '../models/candle.dart';
import '../models/chart_signal.dart';
import '../theme/app_theme.dart';

class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final List<ChartSignal> signals;
  final int timeframeMs;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.signals,
    required this.timeframeMs,
  });

  /// Finds the index (into [candles]) of the candle whose openTime is
  /// nearest to [signal.candleTime], within half a timeframe. Returns null
  /// if no candle matches.
  int? _matchCandleIndex(ChartSignal signal) {
    final targetMs = signal.candleTime.millisecondsSinceEpoch;
    final toleranceMs = timeframeMs / 2;

    int? bestIndex;
    int? bestDiff;
    for (var i = 0; i < candles.length; i++) {
      final diff = (candles[i].openTime - targetMs).abs();
      if (diff <= toleranceMs && (bestDiff == null || diff < bestDiff)) {
        bestIndex = i;
        bestDiff = diff;
      }
    }
    return bestIndex;
  }

  List<ChartMarker> _buildMarkers() {
    final markers = <ChartMarker>[];
    for (final signal in signals) {
      final index = _matchCandleIndex(signal);
      if (index == null) continue;
      markers.add(
        ChartMarker(
          index: index,
          isBuy: signal.signalType == 'buy',
          strength: signal.strength,
        ),
      );
    }
    return markers;
  }

  List<KLineEntity> _buildEntities() {
    return candles
        .map(
          (candle) => KLineEntity.fromCustom(
            time: candle.openTime,
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close,
            vol: 0,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noCandleData));
    }

    final palette = ChartPalette.of(Theme.of(context).brightness);
    final chartColors = ChartColors()
      ..upColor = palette.up
      ..dnColor = palette.down
      ..nowPriceUpColor = palette.up
      ..nowPriceDnColor = palette.down
      ..nowPriceTextColor = palette.nowPriceText
      ..bgColor = [palette.background, palette.background]
      ..defaultTextColor = palette.text
      ..gridColor = palette.grid
      ..selectFillColor = palette.selectFill
      ..selectBorderColor = palette.selectBorder
      ..hCrossColor = palette.crossLine
      ..vCrossColor = palette.crossLine.withValues(alpha: 0.12)
      ..crossTextColor = palette.crossText
      ..infoWindowNormalColor = palette.infoText
      ..infoWindowTitleColor = palette.infoText
      ..maxColor = palette.infoText
      ..minColor = palette.infoText;

    return KChartWidget(
      _buildEntities(),
      ChartStyle(),
      chartColors,
      isTrendLine: false,
      isLine: false,
      mainState: MainState.NONE,
      secondaryState: SecondaryState.NONE,
      volHidden: true,
      hideGrid: false,
      showNowPrice: true,
      isTapShowInfoDialog: true,
      verticalTextAlignment: VerticalTextAlignment.right,
      markers: _buildMarkers(),
    );
  }
}
