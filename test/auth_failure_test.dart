import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/services/auth_failure.dart';

void main() {
  group('authErrorKindFromCode', () {
    test('maps known Firebase codes', () {
      expect(
        authErrorKindFromCode('invalid-email'),
        AuthErrorKind.invalidEmail,
      );
      for (final c in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'user-disabled',
      ]) {
        expect(authErrorKindFromCode(c), AuthErrorKind.wrongCredentials);
      }
      expect(
        authErrorKindFromCode('email-already-in-use'),
        AuthErrorKind.emailInUse,
      );
      expect(
        authErrorKindFromCode('weak-password'),
        AuthErrorKind.weakPassword,
      );
      expect(
        authErrorKindFromCode('network-request-failed'),
        AuthErrorKind.network,
      );
      expect(
        authErrorKindFromCode('too-many-requests'),
        AuthErrorKind.tooManyRequests,
      );
      for (final c in ['popup-closed-by-user', 'cancelled', 'canceled']) {
        expect(authErrorKindFromCode(c), AuthErrorKind.cancelled);
      }
    });

    test('unknown codes map to unknown', () {
      expect(authErrorKindFromCode('something-else'), AuthErrorKind.unknown);
    });
  });

  group('authErrorMessage', () {
    for (final lang in ['en', 'tr', 'es']) {
      test('every kind has a non-empty message in $lang', () {
        final l10n = lookupAppLocalizations(Locale(lang));
        for (final kind in AuthErrorKind.values) {
          expect(authErrorMessage(l10n, kind).trim(), isNotEmpty);
        }
      });
    }
  });
}
