import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removed strength filter APIs are no longer referenced', () {
    const banned = [
      'signalMinStrength',
      'signal_min_strength',
      'filterByStrength',
      'effectiveMinStrength',
      'isStrength3FilterLocked',
      'strength3FilterRequiresPro',
      'strength3_filter_requires_pro',
      'signalStrengthLabel',
      'signalStrengthAll',
    ];
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      for (final b in banned) {
        if (text.contains(b)) offenders.add('${f.path}: $b');
      }
    }
    expect(offenders, isEmpty);
  });
}
