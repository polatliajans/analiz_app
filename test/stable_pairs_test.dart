import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/utils/stable_pairs.dart';

void main() {
  test('normal coins are not stable pairs', () {
    for (final s in ['BTCUSDT', 'ETHUSDT', 'SOLUSDC', 'ETHBTC', 'BTCFDUSD']) {
      expect(isStablePair(s), isFalse, reason: s);
    }
  });

  test('stable base assets are stable pairs', () {
    for (final s in [
      'USDCUSDT',
      'FDUSDUSDT',
      'TUSDUSDT',
      'DAIUSDT',
      'EURUSDT',
      'USDPUSDT',
      'USDEUSDT',
      'USD1USDT',
      'PYUSDUSDT',
      'AEURUSDT',
      'USDTUSDC',
      'BUSDUSDT',
    ]) {
      expect(isStablePair(s), isTrue, reason: s);
    }
  });

  test('is case-insensitive and tolerates odd input', () {
    expect(isStablePair('usdcusdt'), isTrue);
    expect(isStablePair('USDT'), isFalse);
    expect(isStablePair(''), isFalse);
  });
}
