import 'dart:convert';

import '../config/api_config.dart';
import 'api_http.dart';

/// Reports that a signed-in member accepted a version of the terms.
abstract class TermsAcceptanceApi {
  /// Throws on any failure (network, non-2xx); the caller retries later.
  Future<void> submit({
    required String token,
    required String version,
    required DateTime acceptedAt,
    required String platform,
  });
}

/// `POST /api/me/terms-acceptance` (auth:sanctum).
class HttpTermsAcceptanceApi implements TermsAcceptanceApi {
  const HttpTermsAcceptanceApi();

  @override
  Future<void> submit({
    required String token,
    required String version,
    required DateTime acceptedAt,
    required String platform,
  }) async {
    final response = await ApiHttp.post(
      Uri.parse('${ApiConfig.baseUrl}/me/terms-acceptance'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version': version,
        'accepted_at': acceptedAt.toUtc().toIso8601String(),
        'platform': platform,
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw StateError('terms-acceptance failed: ${response.statusCode}');
    }
  }
}
