import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/radar_item.dart';
import 'package:kriptoanaliz/utils/radar_time.dart';

void main() {
  final now = DateTime(2026, 5, 10, 15, 0);
  RadarAgo? ago(Duration d) => radarAgoOf(now.subtract(d), now);

  test('null detectedAt hides the label', () {
    expect(radarAgoOf(null, now), isNull);
  });

  test('buckets', () {
    expect(ago(Duration.zero), const RadarAgo(RadarAgoKind.now));
    expect(ago(const Duration(seconds: 59)), const RadarAgo(RadarAgoKind.now));
    expect(
      ago(const Duration(minutes: 1)),
      const RadarAgo(RadarAgoKind.minutes, 1),
    );
    expect(
      ago(const Duration(minutes: 12)),
      const RadarAgo(RadarAgoKind.minutes, 12),
    );
    expect(
      ago(const Duration(minutes: 59)),
      const RadarAgo(RadarAgoKind.minutes, 59),
    );
    expect(
      ago(const Duration(minutes: 60)),
      const RadarAgo(RadarAgoKind.hours, 1),
    );
    expect(
      ago(const Duration(hours: 3)),
      const RadarAgo(RadarAgoKind.hours, 3),
    );
    expect(
      ago(const Duration(hours: 23, minutes: 59)),
      const RadarAgo(RadarAgoKind.hours, 23),
    );
    expect(
      ago(const Duration(hours: 24)),
      const RadarAgo(RadarAgoKind.yesterday),
    );
    expect(
      ago(const Duration(hours: 30)),
      const RadarAgo(RadarAgoKind.yesterday),
    );
    expect(ago(const Duration(days: 3)), const RadarAgo(RadarAgoKind.days, 3));
  });

  test('future timestamp (clock skew) counts as now', () {
    expect(
      radarAgoOf(now.add(const Duration(minutes: 5)), now),
      const RadarAgo(RadarAgoKind.now),
    );
  });

  test('UTC input is compared as an instant', () {
    final utc = DateTime.utc(2026, 5, 10, 12, 0);
    final localNow = utc.add(const Duration(minutes: 7)).toLocal();
    expect(radarAgoOf(utc, localNow), const RadarAgo(RadarAgoKind.minutes, 7));
  });

  test('RadarItem.fromJson tolerates missing / bad detected_at', () {
    Map<String, dynamic> json(Object? at) => {
      'id': 1,
      'term': 'short',
      'timeframe': '15m',
      'technical_score': 50,
      'detected_at': at,
      'coin': {
        'id': 1,
        'symbol': 'BTCUSDT',
        'name': 'BTC',
        'market_type': 'spot',
      },
    };
    expect(RadarItem.fromJson(json(null)).detectedAt, isNull);
    expect(RadarItem.fromJson(json('garbage')).detectedAt, isNull);
    expect(RadarItem.fromJson(json(42)).detectedAt, isNull);
    final ok = RadarItem.fromJson(json('2026-05-10T12:00:00Z')).detectedAt;
    expect(ok, DateTime.utc(2026, 5, 10, 12));
  });
}
