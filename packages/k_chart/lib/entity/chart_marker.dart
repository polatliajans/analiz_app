/// A custom marker (e.g. buy/sell signal) to be drawn on top of the main
/// candlestick chart, anchored to a specific candle by [index] (the index
/// into the `datas` list passed to [KChartWidget]).
///
/// [strength] (1..3) scales the arrow size/opacity and is shown as a small
/// digit badge next to the arrow.
class ChartMarker {
  final int index;
  final bool isBuy;
  final int strength;

  const ChartMarker({
    required this.index,
    required this.isBuy,
    this.strength = 1,
  });
}
