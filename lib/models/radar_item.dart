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

  /// Higher-timeframe trend: 'up' | 'down' | null (old server / unknown).
  final String? trend;

  /// Latest volume divided by its average; null when unknown.
  final double? volumeRatio;

  /// Pro only: short localized AI note. Null for guests, free members, old
  /// servers or when the server has none.
  final String? aiComment;

  /// Pro only: per-factor scores (keys like oversold, bollinger, trend,
  /// volume, reversal, support, multiplier, ...). Null when absent.
  final Map<String, double>? scoreBreakdown;

  const RadarItem({
    required this.id,
    required this.term,
    required this.timeframe,
    required this.technicalScore,
    required this.rsi,
    required this.lastClose,
    required this.detectedAt,
    required this.coin,
    this.trend,
    this.volumeRatio,
    this.aiComment,
    this.scoreBreakdown,
  });

  /// Whether there is anything Pro-only to expand.
  bool get hasProDetails =>
      aiComment != null ||
      (scoreBreakdown?.keys.any(_knownFactors.contains) ?? false);

  static const _knownFactors = {
    'oversold',
    'bollinger',
    'trend',
    'volume',
    'reversal',
    'support',
  };

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
      trend: _parseTrend(json['trend']),
      volumeRatio: _parseNum(json['volume_ratio']),
      aiComment: _parseComment(json['ai_comment']),
      scoreBreakdown: _parseBreakdown(json['score_breakdown']),
    );
  }

  static String? _parseTrend(Object? v) =>
      v == 'up' || v == 'down' ? v as String : null;

  static double? _parseNum(Object? v) {
    if (v is num && v.isFinite) return v.toDouble();
    return null;
  }

  static String? _parseComment(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Keeps only numeric, finite entries; unknown keys are harmless.
  static Map<String, double>? _parseBreakdown(Object? v) {
    if (v is! Map) return null;
    final out = <String, double>{};
    v.forEach((k, val) {
      final n = _parseNum(val);
      if (k is String && n != null) out[k] = n;
    });
    return out.isEmpty ? null : out;
  }
}
