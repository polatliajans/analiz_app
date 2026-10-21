import 'package:intl/intl.dart';

import '../data/glossary_data.dart';
import '../l10n/app_localizations.dart';

/// Relative "N min/h/days ago" text for a past time.
String relativeAgo(AppLocalizations l10n, DateTime at, DateTime now) {
  final age = now.difference(at);
  if (age < const Duration(minutes: 1)) return l10n.agoNow;
  if (age < const Duration(hours: 1)) return l10n.agoMinutes(age.inMinutes);
  if (age < const Duration(days: 1)) return l10n.agoHours(age.inHours);
  return l10n.agoDays(age.inDays);
}

/// "In N min/h/days" text for an upcoming event. Uses [date] when known,
/// otherwise [hoursUntil]; null when neither is available.
String? relativeUntil(
  AppLocalizations l10n,
  DateTime? date,
  double? hoursUntil,
  DateTime now,
) {
  final Duration left;
  if (date != null) {
    left = date.difference(now);
  } else if (hoursUntil != null) {
    left = Duration(minutes: (hoursUntil * 60).round());
  } else {
    return null;
  }
  if (left < const Duration(hours: 1)) {
    final m = left.inMinutes < 1 ? 1 : left.inMinutes;
    return l10n.homeInMinutes(m);
  }
  if (left < const Duration(hours: 48)) return l10n.homeInHours(left.inHours);
  return l10n.homeInDays(left.inDays);
}

enum FearGreedLevel { extremeFear, fear, neutral, greed, extremeGreed }

/// Level for a 0-100 Fear & Greed value (alternative.me bands).
FearGreedLevel fearGreedLevelForValue(int value) {
  if (value <= 24) return FearGreedLevel.extremeFear;
  if (value <= 46) return FearGreedLevel.fear;
  if (value <= 54) return FearGreedLevel.neutral;
  if (value <= 75) return FearGreedLevel.greed;
  return FearGreedLevel.extremeGreed;
}

/// Level for the API's English label, falling back to the value's band.
FearGreedLevel fearGreedLevel(String? label, int value) {
  final l = label?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (l) {
    case 'extremefear':
      return FearGreedLevel.extremeFear;
    case 'fear':
      return FearGreedLevel.fear;
    case 'neutral':
      return FearGreedLevel.neutral;
    case 'greed':
      return FearGreedLevel.greed;
    case 'extremegreed':
      return FearGreedLevel.extremeGreed;
  }
  return fearGreedLevelForValue(value);
}

String fearGreedText(AppLocalizations l10n, FearGreedLevel level) {
  switch (level) {
    case FearGreedLevel.extremeFear:
      return l10n.homeFngExtremeFear;
    case FearGreedLevel.fear:
      return l10n.homeFngFear;
    case FearGreedLevel.neutral:
      return l10n.homeFngNeutral;
    case FearGreedLevel.greed:
      return l10n.homeFngGreed;
    case FearGreedLevel.extremeGreed:
      return l10n.homeFngExtremeGreed;
  }
}

/// Deterministic "term of the day": the same term all day, rotating daily.
GlossaryTerm termOfTheDay(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final index = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  return glossaryTerms[index % glossaryTerms.length];
}

/// USD price with sensible precision for both BTC and sub-cent coins.
String formatUsdPrice(double price, String locale) {
  final abs = price.abs();
  final digits = abs >= 1000
      ? 2
      : abs >= 1
      ? 3
      : abs >= 0.01
      ? 4
      : 8;
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = abs >= 1000 ? 0 : 2
    ..maximumFractionDigits = digits;
  return '\$${f.format(price)}';
}

/// Signed percentage like +1.02% / -0.50%.
String formatSignedPct(double pct, String locale) {
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;
  final sign = pct > 0 ? '+' : '';
  return '$sign${f.format(pct)}%';
}

String formatPlainPct(double pct, String locale) {
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 1
    ..maximumFractionDigits = 1;
  return '${f.format(pct)}%';
}

/// Compact USD amount like $2.74T.
String formatCompactUsd(double usd, String locale) =>
    NumberFormat.compactCurrency(
      locale: locale,
      symbol: '\$',
      decimalDigits: 2,
    ).format(usd);

/// Quote assets a Binance symbol may end with, longest first so that e.g.
/// FDUSD wins over USD-like shorter suffixes.
const _quoteAssets = <String>[
  'FDUSD',
  'USDT',
  'USDC',
  'BUSD',
  'TUSD',
  'USDP',
  'DAI',
  'TRY',
  'EUR',
  'BRL',
  'BTC',
  'ETH',
  'BNB',
];

/// Splits "BTCUSDT" into ("BTC", "USDT"). Unknown quotes (or a symbol that is
/// only a quote) come back whole as the base with an empty quote.
(String base, String quote) splitSymbol(String symbol) {
  final s = symbol.trim().toUpperCase();
  for (final q in _quoteAssets) {
    if (s.length > q.length && s.endsWith(q)) {
      return (s.substring(0, s.length - q.length), q);
    }
  }
  return (s, '');
}

/// Short volume like 1.2B / 345M / 12.3K (no currency sign).
String formatVolumeShort(double v, String locale) {
  final abs = v.abs();
  const steps = <(double, String)>[
    (1e12, 'T'),
    (1e9, 'B'),
    (1e6, 'M'),
    (1e3, 'K'),
  ];
  for (final (size, suffix) in steps) {
    if (abs >= size) {
      final scaled = v / size;
      final f = NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = 0
        ..maximumFractionDigits = scaled.abs() >= 100 ? 0 : 1;
      return '${f.format(scaled)}$suffix';
    }
  }
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 0;
  return f.format(v);
}
