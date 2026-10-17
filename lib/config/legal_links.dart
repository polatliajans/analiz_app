/// Public legal/support pages hosted on the CryptoAnaliz website.
class LegalLinks {
  static const String baseUrl = 'https://www.cryptoanaliz.net';
  static const String supportEmail = 'support@cryptoanaliz.net';

  static const String privacyPath = 'privacy';
  static const String termsPath = 'terms';
  static const String deleteAccountPath = 'delete-account';
  static const String supportPath = 'support';

  static const Set<String> _langs = {'tr', 'en', 'es'};

  /// Builds `https://www.cryptoanaliz.net/<path>?lang=<code>`; unknown
  /// languages fall back to English.
  static Uri page(String path, String languageCode) {
    final lang = _langs.contains(languageCode) ? languageCode : 'en';
    return Uri.parse('$baseUrl/$path?lang=$lang');
  }

  static Uri get supportMailto => Uri(scheme: 'mailto', path: supportEmail);
}
