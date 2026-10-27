import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Random URL-safe nonce for Sign in with Apple (the raw value goes to
/// Firebase, its SHA-256 goes to Apple).
String generateAppleNonce([int length = 32, Random? random]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rng = random ?? Random.secure();
  return List.generate(
    length,
    (_) => charset[rng.nextInt(charset.length)],
  ).join();
}

/// Lowercase hex SHA-256 of [input].
String sha256ofString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

/// "Given Family" display name from Apple's first-sign-in name parts, or null
/// when Apple did not provide any (it only does so on the first sign-in).
String? appleDisplayName(String? givenName, String? familyName) {
  final parts = [
    givenName?.trim(),
    familyName?.trim(),
  ].whereType<String>().where((p) => p.isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(' ');
}
