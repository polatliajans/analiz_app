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
