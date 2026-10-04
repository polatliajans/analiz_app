import 'package:http/http.dart' as http;

/// Thin wrapper over package:http that tells the server which language the
/// user picked, so API messages come back localized.
class ApiHttp {
  static String languageCode = 'en';

  static Map<String, String> _withLanguage(Map<String, String>? headers) => {
    'Accept-Language': languageCode,
    ...?headers,
  };

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      http.get(uri, headers: _withLanguage(headers));

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => http.post(uri, headers: _withLanguage(headers), body: body);

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => http.put(uri, headers: _withLanguage(headers), body: body);

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
  }) => http.delete(uri, headers: _withLanguage(headers));
}
