import 'structured_analysis.dart';

class AnalysisRecord {
  final int id;
  final String type;
  final int coinId;
  final String symbol;
  final String marketType;
  final String? timeframe;
  final String result;
  final int creditCost;
  final DateTime createdAt;
  final StructuredAnalysis? structured;

  const AnalysisRecord({
    required this.id,
    required this.type,
    required this.coinId,
    required this.symbol,
    required this.marketType,
    required this.timeframe,
    required this.result,
    required this.creditCost,
    required this.createdAt,
    this.structured,
  });

  bool get isDeep => type == 'deep';

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      id: json['id'] as int,
      type: json['type'] as String,
      coinId: json['coin_id'] as int,
      symbol: json['symbol'] as String,
      marketType: json['market_type'] as String,
      timeframe: json['timeframe'] as String?,
      result: json['result'] as String,
      creditCost: json['credit_cost'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      structured: StructuredAnalysis.tryParse(json['structured']),
    );
  }
}
