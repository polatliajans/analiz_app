import 'coin.dart';

class RadarItem {
  final int id;
  final String term;
  final String timeframe;
  final int technicalScore;
  final double? rsi;
  final double? lastClose;
  final DateTime detectedAt;
  final Coin coin;

  const RadarItem({
    required this.id,
    required this.term,
    required this.timeframe,
    required this.technicalScore,
    required this.rsi,
    required this.lastClose,
    required this.detectedAt,
    required this.coin,
  });

  factory RadarItem.fromJson(Map<String, dynamic> json) {
    return RadarItem(
      id: json['id'] as int,
      term: json['term'] as String,
      timeframe: json['timeframe'] as String,
      technicalScore: json['technical_score'] as int,
      rsi: (json['rsi'] as num?)?.toDouble(),
      lastClose: (json['last_close'] as num?)?.toDouble(),
      detectedAt: DateTime.parse(json['detected_at'] as String),
      coin: Coin.fromJson(json['coin'] as Map<String, dynamic>),
    );
  }
}
