/// Pure relative-time bucketing for the radar "detected" label.
enum RadarAgoKind { now, minutes, hours, yesterday, days }

class RadarAgo {
  final RadarAgoKind kind;
  final int n;
  const RadarAgo(this.kind, [this.n = 0]);

  @override
  bool operator ==(Object other) =>
      other is RadarAgo && other.kind == kind && other.n == n;

  @override
  int get hashCode => Object.hash(kind, n);

  @override
  String toString() => 'RadarAgo($kind, $n)';
}

/// Buckets [detectedAt] relative to [now]. Returns null when [detectedAt] is
/// null (label hidden). Future timestamps (clock skew) count as "now".
RadarAgo? radarAgoOf(DateTime? detectedAt, DateTime now) {
  if (detectedAt == null) return null;
  final t = detectedAt.toLocal();
  final n = now.toLocal();
  final diff = n.difference(t);
  if (diff.inMinutes < 1) return const RadarAgo(RadarAgoKind.now);
  if (diff.inMinutes < 60) {
    return RadarAgo(RadarAgoKind.minutes, diff.inMinutes);
  }
  if (diff.inHours < 24) return RadarAgo(RadarAgoKind.hours, diff.inHours);
  final days = DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(t.year, t.month, t.day)).inDays;
  // DST can make a calendar diff round oddly; >= 24h is at least 1 day.
  if (days <= 1) {
    return const RadarAgo(RadarAgoKind.yesterday);
  }
  return RadarAgo(RadarAgoKind.days, days);
}
