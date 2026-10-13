import '../models/chart_signal.dart';

/// Clamps a raw strength to the supported 1..3 range.
int normalizeStrength(int value) => value < 1 ? 1 : (value > 3 ? 3 : value);

/// Keeps only signals whose strength is at least [minStrength].
List<ChartSignal> filterByStrength(List<ChartSignal> signals, int minStrength) {
  if (minStrength <= 1) return signals;
  return signals.where((s) => s.strength >= minStrength).toList();
}
