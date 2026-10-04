import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';

void main() {
  test('fromJson parses a full record', () {
    final r = AnalysisRecord.fromJson({
      'id': 7,
      'type': 'deep',
      'coin_id': 3,
      'symbol': 'BTCUSDT',
      'market_type': 'futures',
      'timeframe': '4h',
      'result': 'text',
      'credit_cost': 5,
      'created_at': '2026-10-04T10:30:00.000000Z',
    });
    expect(r.id, 7);
    expect(r.isDeep, isTrue);
    expect(r.coinId, 3);
    expect(r.symbol, 'BTCUSDT');
    expect(r.marketType, 'futures');
    expect(r.timeframe, '4h');
    expect(r.result, 'text');
    expect(r.creditCost, 5);
    expect(
      r.createdAt.isAtSameMomentAs(DateTime.utc(2026, 10, 4, 10, 30)),
      isTrue,
    );
    expect(r.createdAt.isUtc, isFalse);
  });

  test('fromJson tolerates null timeframe and quick type', () {
    final r = AnalysisRecord.fromJson({
      'id': 1,
      'type': 'quick',
      'coin_id': 1,
      'symbol': 'ETHUSDT',
      'market_type': 'spot',
      'timeframe': null,
      'result': 'x',
      'credit_cost': 1,
      'created_at': '2026-10-04T10:30:00+00:00',
    });
    expect(r.timeframe, isNull);
    expect(r.isDeep, isFalse);
  });
}
