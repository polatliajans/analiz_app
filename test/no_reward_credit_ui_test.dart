import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the old "watch an ad for credits" UI is gone', () {
    const banned = [
      'RewardedAdButton',
      'rewardedWatchButton',
      'rewardedEarnedPending',
      'rewardedOfferProvider',
      'refreshBalanceAfterReward',
      'canOfferRewarded',
    ];
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File) continue;
      if (f.path.contains('app_localizations')) continue;
      if (!f.path.endsWith('.dart') && !f.path.endsWith('.arb')) continue;
      final text = f.readAsStringSync();
      for (final b in banned) {
        if (text.contains(b)) offenders.add('${f.path}: $b');
      }
    }
    expect(offenders, isEmpty);
  });
}
