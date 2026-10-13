import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/signal_strength_filter_provider.dart';
import 'package:kriptoanaliz/utils/signal_strength.dart';

ChartSignal _s(int strength) => ChartSignal(
  candleTime: DateTime.utc(2026, 1, 1),
  signalType: 'buy',
  strength: strength,
);

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

  test('filterByStrength keeps signals at or above the minimum', () {
    final all = [_s(1), _s(2), _s(3), _s(2)];
    expect(filterByStrength(all, 1).length, 4);
    expect(filterByStrength(all, 2).map((s) => s.strength), [2, 3, 2]);
    expect(filterByStrength(all, 3).map((s) => s.strength), [3]);
    expect(filterByStrength(const [], 3), isEmpty);
  });

  test('normalizeStrength clamps to 1..3', () {
    expect(normalizeStrength(0), 1);
    expect(normalizeStrength(2), 2);
    expect(normalizeStrength(9), 3);
  });

  Future<ProviderContainer> container(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('filter provider defaults to 1 (all)', () async {
    final c = await container({});
    addTearDown(c.dispose);
    expect(c.read(signalMinStrengthProvider), 1);
  });

  test('filter provider persists selection', () async {
    final c = await container({});
    addTearDown(c.dispose);
    await c.read(signalMinStrengthProvider.notifier).select(3);
    expect(c.read(signalMinStrengthProvider), 3);
    expect(c.read(sharedPreferencesProvider).getInt(signalMinStrengthKey), 3);
  });

  test('filter provider restores saved value and ignores invalid', () async {
    final c = await container({signalMinStrengthKey: 2});
    addTearDown(c.dispose);
    expect(c.read(signalMinStrengthProvider), 2);
    final bad = await container({signalMinStrengthKey: 7});
    addTearDown(bad.dispose);
    expect(bad.read(signalMinStrengthProvider), 1);
  });
}
