/// A custom marker (e.g. buy/sell signal) to be drawn on top of the main
/// candlestick chart, anchored to a specific candle by [index] (the index
/// into the `datas` list passed to [KChartWidget]).
class ChartMarker {
  final int index;
  final bool isBuy;

  const ChartMarker({required this.index, required this.isBuy});
}
