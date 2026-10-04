import 'package:kriptoanaliz/utils/signup_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts matching passwords of sufficient length', () {
    expect(validateSignUpPasswords('abcdefgh', 'abcdefgh'), isNull);
  });

  test('rejects short passwords', () {
    expect(validateSignUpPasswords('abc', 'abc'), SignUpPasswordError.tooShort);
  });

  test('rejects mismatched passwords', () {
    expect(
      validateSignUpPasswords('abcdefgh', 'abcdefgi'),
      SignUpPasswordError.mismatch,
    );
  });

  test('mismatch is case sensitive and empty confirmation fails', () {
    expect(
      validateSignUpPasswords('abcdefgh', 'ABCDEFGH'),
      SignUpPasswordError.mismatch,
    );
    expect(
      validateSignUpPasswords('abcdefgh', ''),
      SignUpPasswordError.mismatch,
    );
  });
}
