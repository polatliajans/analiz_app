// Machine-readable deep analysis (schema_version 1). Every field is optional:
// parsing never throws on missing or malformed data.

enum AnalysisBias {
  bullish,
  bearish,
  neutral;

  static AnalysisBias? fromApi(Object? value) {
    if (value is! String) return null;
    switch (value.trim().toLowerCase()) {
      case 'bullish':
        return AnalysisBias.bullish;
      case 'bearish':
        return AnalysisBias.bearish;
      case 'neutral':
        return AnalysisBias.neutral;
    }
    return null;
  }
}

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

double? _num(Object? v) {
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is String) {
    final d = double.tryParse(v.trim());
    return (d != null && d.isFinite) ? d : null;
  }
  return null;
}

int? _int(Object? v) => _num(v)?.round();

List<String> _strList(Object? v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (_str(e) != null) _str(e)!,
  ];
}

List<double> _numList(Object? v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (_num(e) != null) _num(e)!,
  ];
}

List<Map<String, dynamic>> _mapList(Object? v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

class AnalysisDriver {
  final String? title;
  final String? detail;
  final AnalysisBias? direction;
  final List<String> evidence;

  const AnalysisDriver({
    this.title,
    this.detail,
    this.direction,
    this.evidence = const [],
  });

  factory AnalysisDriver.fromJson(Map<String, dynamic> j) => AnalysisDriver(
    title: _str(j['title']),
    detail: _str(j['detail']),
    direction: AnalysisBias.fromApi(j['direction']),
    evidence: _strList(j['evidence']),
  );

  bool get isEmpty => title == null && detail == null && evidence.isEmpty;
}

class AnalysisScenario {
  final String? description;
  final double? triggerLevel;
  final double? target;
  final double? probability;

  const AnalysisScenario({
    this.description,
    this.triggerLevel,
    this.target,
    this.probability,
  });

  factory AnalysisScenario.fromJson(Map<String, dynamic> j) => AnalysisScenario(
    description: _str(j['description']),
    triggerLevel: _num(j['trigger_level']),
    target: _num(j['target']),
    probability: _num(j['probability']),
  );

  bool get isEmpty =>
      description == null &&
      triggerLevel == null &&
      target == null &&
      probability == null;
}

class AnalysisLevels {
  final double? priceAtAnalysis;
  final List<double> supports;
  final List<double> resistances;
  final double? invalidation;

  const AnalysisLevels({
    this.priceAtAnalysis,
    this.supports = const [],
    this.resistances = const [],
    this.invalidation,
  });

  factory AnalysisLevels.fromJson(Map<String, dynamic> j) => AnalysisLevels(
    priceAtAnalysis: _num(j['price_at_analysis']),
    supports: _numList(j['supports']),
    resistances: _numList(j['resistances']),
    invalidation: _num(j['invalidation']),
  );

  bool get isEmpty =>
      supports.isEmpty && resistances.isEmpty && invalidation == null;
}

class AnalysisSource {
  final String? name;
  final String? url;
  final String? note;

  const AnalysisSource({this.name, this.url, this.note});

  factory AnalysisSource.fromJson(Map<String, dynamic> j) => AnalysisSource(
    name: _str(j['name']),
    url: _str(j['url']),
    note: _str(j['note']),
  );
}

class StructuredAnalysis {
  final String? symbol;
  final String? marketType;
  final String? timeframe;
  final AnalysisBias? bias;
  final int? confidence;
  final int? horizonCandles;
  final String? horizonLabel;
  final String? summary;
  final List<AnalysisDriver> drivers;
  final AnalysisScenario? bull;
  final AnalysisScenario? base;
  final AnalysisScenario? bear;
  final AnalysisLevels levels;
  final List<String> risks;
  final List<String> watch;
  final List<String> missingSources;
  final String? dataQualityNotes;
  final List<AnalysisSource> sources;
  final String? disclaimer;

  const StructuredAnalysis({
    this.symbol,
    this.marketType,
    this.timeframe,
    this.bias,
    this.confidence,
    this.horizonCandles,
    this.horizonLabel,
    this.summary,
    this.drivers = const [],
    this.bull,
    this.base,
    this.bear,
    this.levels = const AnalysisLevels(),
    this.risks = const [],
    this.watch = const [],
    this.missingSources = const [],
    this.dataQualityNotes,
    this.sources = const [],
    this.disclaimer,
  });

  factory StructuredAnalysis.fromJson(Map<String, dynamic> j) {
    AnalysisScenario? scenario(Object? v) {
      if (v is! Map) return null;
      final s = AnalysisScenario.fromJson(Map<String, dynamic>.from(v));
      return s.isEmpty ? null : s;
    }

    final Map scenarios = j['scenarios'] is Map ? j['scenarios'] as Map : {};
    final Map quality = j['data_quality'] is Map
        ? j['data_quality'] as Map
        : {};
    final levels = j['levels'] is Map
        ? AnalysisLevels.fromJson(Map<String, dynamic>.from(j['levels'] as Map))
        : const AnalysisLevels();

    return StructuredAnalysis(
      symbol: _str(j['symbol']),
      marketType: _str(j['market_type']),
      timeframe: _str(j['timeframe']),
      bias: AnalysisBias.fromApi(j['bias']),
      confidence: _int(j['confidence']),
      horizonCandles: _int(j['horizon_candles']),
      horizonLabel: _str(j['horizon_label']),
      summary: _str(j['summary']),
      drivers: [
        for (final d in _mapList(j['drivers']))
          if (!AnalysisDriver.fromJson(d).isEmpty) AnalysisDriver.fromJson(d),
      ],
      bull: scenario(scenarios['bull']),
      base: scenario(scenarios['base']),
      bear: scenario(scenarios['bear']),
      levels: levels,
      risks: _strList(j['risks']),
      watch: _strList(j['watch']),
      missingSources: _strList(quality['missing_sources']),
      dataQualityNotes: _str(quality['notes']),
      sources: [
        for (final s in _mapList(j['sources']))
          if (AnalysisSource.fromJson(s).name != null ||
              AnalysisSource.fromJson(s).url != null)
            AnalysisSource.fromJson(s),
      ],
      disclaimer: _str(j['disclaimer']),
    );
  }

  /// Parses an arbitrary decoded JSON value. Returns null when it is not a
  /// map or carries nothing displayable, so callers fall back to plain text.
  static StructuredAnalysis? tryParse(Object? raw) {
    if (raw is! Map) return null;
    try {
      final s = StructuredAnalysis.fromJson(Map<String, dynamic>.from(raw));
      return s.hasContent ? s : null;
    } catch (_) {
      return null;
    }
  }

  bool get hasScenarios => bull != null || base != null || bear != null;

  bool get hasContent =>
      bias != null ||
      summary != null ||
      drivers.isNotEmpty ||
      hasScenarios ||
      !levels.isEmpty ||
      risks.isNotEmpty ||
      watch.isNotEmpty;
}
