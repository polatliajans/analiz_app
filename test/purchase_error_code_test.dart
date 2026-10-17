import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/data/purchase_api.dart';

void main() {
  test('detects purchase_already_processed code', () {
    expect(
      isPurchaseAlreadyProcessed(
        '{"code":"purchase_already_processed","message":"x"}',
      ),
      isTrue,
    );
  });

  test('other or malformed bodies are not matched', () {
    expect(isPurchaseAlreadyProcessed('{"message":"invalid"}'), isFalse);
    expect(isPurchaseAlreadyProcessed('not json'), isFalse);
    expect(isPurchaseAlreadyProcessed('[]'), isFalse);
    expect(isPurchaseAlreadyProcessed(''), isFalse);
  });
}
