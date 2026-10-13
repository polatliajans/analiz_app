import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

const signalMinStrengthKey = 'signal_min_strength';

/// Minimum signal strength shown on the chart: 1 = all, 2 = 2+, 3 = only 3.
class SignalMinStrengthNotifier extends Notifier<int> {
  @override
  int build() {
    final saved = ref.read(sharedPreferencesProvider).getInt(
      signalMinStrengthKey,
    );
    return (saved != null && saved >= 1 && saved <= 3) ? saved : 1;
  }

  Future<void> select(int minStrength) async {
    state = minStrength;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(signalMinStrengthKey, minStrength);
  }
}

final signalMinStrengthProvider =
    NotifierProvider<SignalMinStrengthNotifier, int>(
      SignalMinStrengthNotifier.new,
    );
