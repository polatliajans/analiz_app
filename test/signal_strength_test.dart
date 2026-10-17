import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/utils/signal_strength.dart';

void main() {
  test('ChartSignal.fromJson reads strength and defaults to 1', () {
    final withStrength = ChartSignal.fromJson({
      'candle_time': '2026-01-01T00:00:00Z',
      'signal_type': 'sell',
      'strength': 3,
    });
    expect(withStrength.strength, 3);
    final legacy = ChartSignal.fromJson({
      'candle_time': '2026-01-01T00:00:00Z',
      'signal_type': 'buy',
    });
    expect(legacy.strength, 1);
    final nullStrength = ChartSignal.fromJson({
      'candle_time': '2026-01-01T00:00:00Z',
      'signal_type': 'buy',
      'strength': null,
    });
    expect(nullStrength.strength, 1);
  });

  test('normalizeStrength clamps to 1..3', () {
    expect(normalizeStrength(0), 1);
    expect(normalizeStrength(2), 2);
    expect(normalizeStrength(9), 3);
  });
}
