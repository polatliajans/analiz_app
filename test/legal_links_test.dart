import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/config/legal_links.dart';

void main() {
  test('builds page URLs with the app language', () {
    expect(
      LegalLinks.page(LegalLinks.privacyPath, 'tr').toString(),
      'https://www.cryptoanaliz.net/privacy?lang=tr',
    );
    expect(
      LegalLinks.page(LegalLinks.termsPath, 'en').toString(),
      'https://www.cryptoanaliz.net/terms?lang=en',
    );
    expect(
      LegalLinks.page(LegalLinks.deleteAccountPath, 'es').toString(),
      'https://www.cryptoanaliz.net/delete-account?lang=es',
    );
    expect(
      LegalLinks.page(LegalLinks.supportPath, 'es').toString(),
      'https://www.cryptoanaliz.net/support?lang=es',
    );
  });

  test('unknown language falls back to en', () {
    expect(
      LegalLinks.page(LegalLinks.privacyPath, 'de').toString(),
      'https://www.cryptoanaliz.net/privacy?lang=en',
    );
  });

  test('support mailto', () {
    expect(LegalLinks.supportMailto.toString(), 'mailto:support@cryptoanaliz.net');
  });
}
