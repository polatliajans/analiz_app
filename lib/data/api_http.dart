import 'package:http/http.dart' as http;

import '../services/crash_reporter.dart';

/// Thin wrapper over package:http that tells the server which language the
/// user picked, so API messages come back localized.
class ApiHttp {
  static String languageCode = 'en';

  static Map<String, String> _withLanguage(Map<String, String>? headers) => {
    'Accept-Language': languageCode,
    ...?headers,
  };

  /// Reports unexpected failures (5xx / non-network exceptions) as non-fatal
  /// crash events, then lets the original result or error through unchanged.
  static Future<http.Response> _track(
    Uri uri,
    Future<http.Response> Function() call,
  ) async {
    try {
      final response = await call();
      reportApiStatus(uri, response.statusCode);
      return response;
    } catch (e, st) {
      reportApiException(uri, e, st);
      rethrow;
    }
  }

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      _track(uri, () => http.get(uri, headers: _withLanguage(headers)));

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _track(
    uri,
    () => http.post(uri, headers: _withLanguage(headers), body: body),
  );

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) => _track(
    uri,
    () => http.put(uri, headers: _withLanguage(headers), body: body),
  );

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
  }) => _track(uri, () => http.delete(uri, headers: _withLanguage(headers)));
}
