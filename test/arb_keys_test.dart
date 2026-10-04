import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final arbs = {
    for (final c in ['en', 'tr', 'es']) c: _load(c),
  };

  test('all ARB files define the same keys', () {
    final all = arbs.values.expand(_keys).toSet();
    for (final entry in arbs.entries) {
      final missing = all.difference(_keys(entry.value));
      expect(
        missing,
        isEmpty,
        reason: 'app_${entry.key}.arb is missing: $missing',
      );
    }
  });

  test('no ARB value is empty', () {
    for (final entry in arbs.entries) {
      for (final key in _keys(entry.value)) {
        final value = entry.value[key];
        expect(
          value is String && value.trim().isNotEmpty,
          isTrue,
          reason: 'app_${entry.key}.arb: "$key" is empty',
        );
      }
    }
  });
}
