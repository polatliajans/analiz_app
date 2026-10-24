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

/// Distance percent like "-36.2%" / "+2,758%": one decimal below 100, none
/// above, with grouping; a value that rounds to zero has no sign.
String formatDistancePct(double value, String locale) {
  final digits = value.abs() < 100 ? 1 : 0;
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = digits
    ..maximumFractionDigits = digits;
  final text = f.format(value.abs());
  final isZero = double.parse(value.abs().toStringAsFixed(digits)) == 0;
  if (isZero) return '$text%';
  return '${value < 0 ? '-' : '+'}$text%';
}

/// Plain percent without a sign: "42%".
String formatPlainPct(double value, {int digits = 0}) =>
    '${value.toStringAsFixed(digits)}%';

/// Basis points: 0.001 -> "0.001", 1.01 -> "1.01", 12 -> "12".
String formatBps(double v) {
  final t = v.toStringAsFixed(v.abs() < 1 ? 3 : 2);
  return t.contains('.')
      ? t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : t;
}

/// Depth window half-width: 1 -> "1", 0.101 -> "0.1", 2.5 -> "2.5".
String formatWindowPct(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final t = v.toStringAsFixed(2);
  return t.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

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
