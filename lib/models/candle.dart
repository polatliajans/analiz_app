class Candle {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;

  const Candle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// Binance kline row: [openTime, open, high, low, close, volume, ...].
  /// openTime is a JSON number; OHLC values are JSON strings.
  factory Candle.fromKline(List<dynamic> kline) {
    return Candle(
      openTime: kline[0] as int,
      open: double.parse(kline[1].toString()),
      high: double.parse(kline[2].toString()),
      low: double.parse(kline[3].toString()),
      close: double.parse(kline[4].toString()),
    );
  }
}
