import 'structured_analysis.dart';

class AiAnalysisResult {
  final int id;
  final String result;
  final int creditCost;
  final StructuredAnalysis? structured;

  /// When the analysis was originally generated (UTC). For a shared-cache hit
  /// this can be minutes old. Null for older servers that do not send it.
  final DateTime? generatedAt;

  const AiAnalysisResult({
    required this.id,
    required this.result,
    required this.creditCost,
    this.structured,
    this.generatedAt,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      id: json['id'] as int,
      result: json['result'] as String,
      creditCost: json['credit_cost'] as int,
      structured: StructuredAnalysis.tryParse(json['structured']),
      generatedAt: _parseDate(json['generated_at']),
    );
  }
}

DateTime? _parseDate(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
