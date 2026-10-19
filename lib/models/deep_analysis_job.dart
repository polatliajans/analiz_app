import 'ai_analysis_result.dart';

enum DeepAnalysisJobStatus {
  queued,
  running,
  completed,
  failed;

  static DeepAnalysisJobStatus parse(Object? raw) => switch (raw) {
    'queued' => queued,
    'running' => running,
    'completed' => completed,
    // Unknown statuses are treated as failed so polling never spins forever.
    _ => failed,
  };

  bool get isTerminal => this == completed || this == failed;
}

/// Background deep-analysis job as returned by the start (202) and
/// status (200) endpoints.
class DeepAnalysisJob {
  final int id;
  final DeepAnalysisJobStatus status;
  final String? symbol;
  final String? timeframe;
  final int? creditCost;
  final int? creditBalance;
  final AiAnalysisResult? analysis;
  final String? errorCode;

  const DeepAnalysisJob({
    required this.id,
    required this.status,
    this.symbol,
    this.timeframe,
    this.creditCost,
    this.creditBalance,
    this.analysis,
    this.errorCode,
  });

  factory DeepAnalysisJob.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'];
    return DeepAnalysisJob(
      id: (json['id'] as num).toInt(),
      status: DeepAnalysisJobStatus.parse(json['status']),
      symbol: json['symbol'] as String?,
      timeframe: json['timeframe'] as String?,
      creditCost: (json['credit_cost'] as num?)?.toInt(),
      creditBalance: (json['credit_balance'] as num?)?.toInt(),
      analysis: analysis is Map<String, dynamic>
          ? AiAnalysisResult.fromJson(analysis)
          : null,
      errorCode: json['error_code'] as String?,
    );
  }
}
