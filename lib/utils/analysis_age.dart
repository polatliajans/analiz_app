import '../l10n/app_localizations.dart';

/// "Prepared N min/hr/days ago" text for an analysis generated at
/// [generatedAt]. Returns null when the time is unknown or less than a minute
/// old (nothing worth saying) -- unless the result came from the shared
/// cache ([cached]), when "just prepared" tells the user it is a shared result.
/// [now] is passed in so tests can fix the clock.
String? preparedAgoText(
  AppLocalizations l10n,
  DateTime? generatedAt,
  DateTime now, {
  bool cached = false,
}) {
  if (generatedAt == null) return null;
  final age = now.toUtc().difference(generatedAt.toUtc());
  if (age < const Duration(minutes: 1)) {
    return cached ? l10n.analysisPreparedJustNow : null;
  }
  if (age < const Duration(hours: 1)) {
    return l10n.analysisPreparedMinutes(age.inMinutes);
  }
  if (age < const Duration(days: 1)) {
    return l10n.analysisPreparedHours(age.inHours);
  }
  return l10n.analysisPreparedDays(age.inDays);
}
