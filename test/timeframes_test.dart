import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/utils/timeframes.dart';

void main() {
  test('chart timeframes list is ordered and complete', () {
    expect(chartTimeframes, ['1m', '5m', '15m', '1h', '4h', '1d', '1w']);
  });

  test('every timeframe has a millisecond duration', () {
    for (final tf in chartTimeframes) {
      expect(timeframeMs[tf], isNotNull, reason: tf);
    }
    expect(timeframeMs['1m'], 60 * 1000);
    expect(timeframeMs['5m'], 5 * 60 * 1000);
    expect(timeframeMs['1w'], 7 * 24 * 60 * 60 * 1000);
  });

  test('signals are only supported on 15m/1h/4h/1d', () {
    expect(chartTimeframes.where(supportsSignals).toList(), [
      '15m',
      '1h',
      '4h',
      '1d',
    ]);
    expect(supportsSignals('1m'), isFalse);
    expect(supportsSignals('1w'), isFalse);
  });
}
