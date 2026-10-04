enum SignUpPasswordError { tooShort, mismatch }

const int minPasswordLength = 8;

/// Returns the first problem with the sign-up password pair, or null if valid.
SignUpPasswordError? validateSignUpPasswords(
  String password,
  String confirmation,
) {
  if (password.length < minPasswordLength) return SignUpPasswordError.tooShort;
  if (password != confirmation) return SignUpPasswordError.mismatch;
  return null;
}
