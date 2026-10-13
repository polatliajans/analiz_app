class ChartSignal {
  final DateTime candleTime;
  final String signalType;

  /// Signal strength 1..3 (older records and missing field count as 1).
  final int strength;

  const ChartSignal({
    required this.candleTime,
    required this.signalType,
    this.strength = 1,
  });

  factory ChartSignal.fromJson(Map<String, dynamic> json) {
    final raw = json['strength'];
    final parsed = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    return ChartSignal(
      candleTime: DateTime.parse(json['candle_time'] as String),
      signalType: json['signal_type'] as String,
      strength: (parsed ?? 1).clamp(1, 3),
    );
  }
}
