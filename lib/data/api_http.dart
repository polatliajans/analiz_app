import 'package:http/http.dart' as http;

import '../services/crash_reporter.dart';
import '../utils/platform_info.dart';

/// Thin wrapper over package:http that tells the server which language the
/// user picked (so API messages come back localized) and which platform the
/// app runs on (`X-Platform: ios|android`).
class ApiHttp {
  static String languageCode = 'en';

  /// Overridable in tests; defaults to the running platform.
  static String Function() platformResolver = platformName;

  static Map<String, String> _withLanguage(Map<String, String>? headers) =>
      defaultHeaders(headers);

  /// Headers added to every request (caller headers win on conflict).
  static Map<String, String> defaultHeaders([Map<String, String>? headers]) => {
    'Accept-Language': languageCode,
    'X-Platform': platformResolver(),
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
