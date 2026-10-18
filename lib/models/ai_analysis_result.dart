import 'structured_analysis.dart';

class AiAnalysisResult {
  final int id;
  final String result;
  final int creditCost;
  final StructuredAnalysis? structured;

  const AiAnalysisResult({
    required this.id,
    required this.result,
    required this.creditCost,
    this.structured,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      id: json['id'] as int,
      result: json['result'] as String,
      creditCost: json['credit_cost'] as int,
      structured: StructuredAnalysis.tryParse(json['structured']),
    );
  }
}
