class ChartSignal {
  final DateTime candleTime;
  final String signalType;

  const ChartSignal({required this.candleTime, required this.signalType});

  factory ChartSignal.fromJson(Map<String, dynamic> json) {
    return ChartSignal(
      candleTime: DateTime.parse(json['candle_time'] as String),
      signalType: json['signal_type'] as String,
    );
  }
}
