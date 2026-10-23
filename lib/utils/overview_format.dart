import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/candle.dart';
import '../models/chart_signal.dart';

/// "$1.2B" style amount; small values keep two decimals.
String formatCompactUsd(double value, String locale) {
  final abs = value.abs();
  if (abs < 1000) {
    return '\$${NumberFormat('#,##0.##', locale).format(value)}';
  }
  return '\$${NumberFormat.compact(locale: locale).format(value)}';
}

/// "12.3K" style count / amount without currency.
String formatCompactNumber(double value, String locale) {
  if (value.abs() < 1000) {
    return NumberFormat('#,##0.##', locale).format(value);
  }
  return NumberFormat.compact(locale: locale).format(value);
}

/// "+1.23%" / "-0.40%" (zero has no sign).
String formatSignedPct(double value, {int digits = 2}) {
  final text = value.abs().toStringAsFixed(digits);
  if (double.parse(text) == 0) return '$text%';
  return '${value < 0 ? '-' : '+'}$text%';
}

/// Plain percent without a sign: "42%".
String formatPlainPct(double value, {int digits = 0}) =>
    '${value.toStringAsFixed(digits)}%';

/// Ratio like 0.052 or 1.25 with a sensible number of decimals.
String formatRatio(double value) {
  final digits = value.abs() >= 10 ? 1 : (value.abs() >= 1 ? 2 : 3);
  return value.toStringAsFixed(digits);
}

/// Coin / listing age from a day count: days, months or years.
String ageText(AppLocalizations l10n, int days) {
  if (days < 60) return l10n.ovAgeDays(days < 0 ? 0 : days);
  if (days < 730) return l10n.ovAgeMonths((days / 30.44).floor());
  return l10n.ovAgeYears((days / 365.25).floor());
}

/// "5 min ago" / "3 h ago" / "2 d ago".
String relativeAgo(AppLocalizations l10n, DateTime time, DateTime now) {
  final age = now.difference(time);
  if (age < const Duration(minutes: 1)) return l10n.relAgoNow;
  if (age < const Duration(hours: 1)) return l10n.relAgoMinutes(age.inMinutes);
  if (age < const Duration(days: 1)) return l10n.relAgoHours(age.inHours);
  return l10n.relAgoDays(age.inDays);
}

/// Close of the candle the [signal] belongs to (nearest open time within
/// half a timeframe); null when the candle is not in [candles].
double? priceAtSignal(
  List<Candle> candles,
  ChartSignal signal,
  int timeframeMs,
) {
  final target = signal.candleTime.millisecondsSinceEpoch;
  final tolerance = timeframeMs / 2;
  Candle? best;
  var bestDiff = 0;
  for (final c in candles) {
    final diff = (c.openTime - target).abs();
    if (diff <= tolerance && (best == null || diff < bestDiff)) {
      best = c;
      bestDiff = diff;
    }
  }
  return best?.close;
}

/// Percent move from [from] to [to]; null for unusable inputs.
double? movePercent(double? from, double? to) {
  if (from == null || to == null || !from.isFinite || !to.isFinite) {
    return null;
  }
  if (from <= 0) return null;
  return (to - from) / from * 100;
}
