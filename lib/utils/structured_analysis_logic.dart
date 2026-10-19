import '../models/analysis_record.dart';
import '../models/structured_analysis.dart';
import 'price_alert_logic.dart';

/// Confidence clamped to 0..100; null when unknown.
int? clampConfidence(num? value) {
  if (value == null || !value.isFinite) return null;
  return value.round().clamp(0, 100);
}

/// Probability (0..1 or 0..100) normalized to a 0..1 bar fraction.
double? probabilityFraction(num? value) {
  if (value == null || !value.isFinite || value < 0) return null;
  final f = value > 1 ? value / 100 : value.toDouble();
  return f.clamp(0.0, 1.0);
}

/// Whole percent for a probability, e.g. 0.35 or 35 -> 35.
int? probabilityPercent(num? value) {
  final f = probabilityFraction(value);
  return f == null ? null : (f * 100).round();
}

/// Price text for display; a dash for unusable values.
String formatLevel(double? price) {
  if (price == null) return '-';
  final t = formatAlertPrice(price.abs());
  if (t == '0') return '-';
  return price < 0 ? '-$t' : t;
}

/// Signed percent distance of [price] from [current]; null when unusable.
double? distancePercent(double? price, double? current) {
  if (price == null || current == null || !current.isFinite || current <= 0) {
    return null;
  }
  return (price - current) / current * 100;
}

/// "+1.5%" / "-0.3%" text for a distance.
String formatDistance(double? pct) {
  if (pct == null || !pct.isFinite) return '';
  final abs = pct.abs();
  final t = abs >= 10 ? abs.toStringAsFixed(0) : abs.toStringAsFixed(1);
  return '${pct < 0 ? '-' : '+'}$t%';
}

/// Number of drivers per direction (unknown direction counts as neutral).
({int bull, int bear, int neutral}) driverBalance(
  List<AnalysisDriver> drivers,
) {
  var bull = 0, bear = 0, neutral = 0;
  for (final d in drivers) {
    switch (d.direction) {
      case AnalysisBias.bullish:
        bull++;
      case AnalysisBias.bearish:
        bear++;
      case AnalysisBias.neutral:
      case null:
        neutral++;
    }
  }
  return (bull: bull, bear: bear, neutral: neutral);
}

/// Driver tiles start collapsed when they merely agree with the overall bias,
/// except the first one.
bool driverStartsExpanded(int index, AnalysisDriver d, AnalysisBias? bias) =>
    index == 0 || bias == null || d.direction != bias;

enum LevelKind { resistance, support, invalidation }

class LevelEntry {
  final LevelKind kind;
  final double price;
  const LevelEntry(this.kind, this.price);
}

/// All levels in descending price order (resistances on top).
List<LevelEntry> sortedLevels(AnalysisLevels levels) {
  final entries = <LevelEntry>[
    for (final r in levels.resistances) LevelEntry(LevelKind.resistance, r),
    for (final s in levels.supports) LevelEntry(LevelKind.support, s),
    if (levels.invalidation != null)
      LevelEntry(LevelKind.invalidation, levels.invalidation!),
  ];
  entries.sort((a, b) => b.price.compareTo(a.price));
  return entries;
}

/// Whether the rich view is used (otherwise the plain text view).
bool shouldShowStructured(StructuredAnalysis? structured) =>
    structured != null && structured.hasContent;

/// History card badge: deep records with a usable bias only.
bool showsBiasBadge(AnalysisRecord record) =>
    record.isDeep && record.structured?.bias != null;
