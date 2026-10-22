import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_http.dart';

/// Why the server refuses (or does not offer) an ad-funded quick analysis.
enum AdAnalysisError {
  notFree,
  disabled,
  hasCredit,
  capReached,
  emailUnverified,
  notVerified,
  sessionExpired,
  unknown,
}

/// A refused ad-analysis call (session creation or the analysis itself).
class AdAnalysisException implements Exception {
  final AdAnalysisError error;
  final int? statusCode;
  final String? message;

  const AdAnalysisException(this.error, {this.statusCode, this.message});

  /// Maps an error response to a typed exception ([AdAnalysisError.unknown]
  /// when the code is not an ad-analysis one).
  factory AdAnalysisException.fromResponse(http.Response response) {
    final code = _codeOf(response);
    final error = switch (code) {
      'not_free' => AdAnalysisError.notFree,
      'ad_analysis_disabled' => AdAnalysisError.disabled,
      'has_credit' => AdAnalysisError.hasCredit,
      'ad_analysis_cap_reached' => AdAnalysisError.capReached,
      'email_unverified' => AdAnalysisError.emailUnverified,
      'ad_not_verified' => AdAnalysisError.notVerified,
      'ad_session_expired' => AdAnalysisError.sessionExpired,
      _ => AdAnalysisError.unknown,
    };
    return AdAnalysisException(
      error,
      statusCode: response.statusCode,
      message: _messageOf(response),
    );
  }

  @override
  String toString() => 'AdAnalysisException($error, $statusCode)';
}

String? _codeOf(http.Response r) {
  try {
    final j = jsonDecode(r.body);
    if (j is Map<String, dynamic>) return j['code'] as String?;
  } catch (_) {}
  return null;
}

String? _messageOf(http.Response r) {
  try {
    final j = jsonDecode(r.body);
    if (j is Map<String, dynamic>) return j['message'] as String?;
  } catch (_) {}
  return null;
}

/// True when [code] (from a quick-analysis error body) is an ad-analysis one.
bool isAdAnalysisCode(String? code) => const {
  'not_free',
  'ad_analysis_disabled',
  'has_credit',
  'ad_analysis_cap_reached',
  'email_unverified',
  'ad_not_verified',
  'ad_session_expired',
}.contains(code);

/// `GET /api/ad-analysis/status`.
class AdAnalysisStatus {
  final bool enabled;
  final int dailyCap;
  final int usedToday;
  final int remainingToday;
  final bool eligible;

  /// null when eligible; otherwise "pro", "has_credit", "disabled",
  /// "cap_reached" or "email_unverified".
  final String? reason;

  const AdAnalysisStatus({
    this.enabled = false,
    this.dailyCap = 0,
    this.usedToday = 0,
    this.remainingToday = 0,
    this.eligible = false,
    this.reason,
  });

  factory AdAnalysisStatus.fromJson(Map<String, dynamic> json) =>
      AdAnalysisStatus(
        enabled: json['enabled'] as bool? ?? false,
        dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 0,
        usedToday: (json['used_today'] as num?)?.toInt() ?? 0,
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
        eligible: json['eligible'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}

/// `POST /api/ad-analysis/sessions` (201).
class AdAnalysisSession {
  final String id;
  final DateTime? expiresAt;
  final int remainingToday;

  const AdAnalysisSession({
    required this.id,
    this.expiresAt,
    this.remainingToday = 0,
  });

  factory AdAnalysisSession.fromJson(Map<String, dynamic> json) =>
      AdAnalysisSession(
        id: json['session_id'] as String,
        expiresAt: DateTime.tryParse('${json['expires_at']}'),
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      );
}

/// `GET /api/ad-analysis/sessions/{id}`.
class AdSessionState {
  final bool verified;
  final bool used;
  final bool expired;

  const AdSessionState({
    this.verified = false,
    this.used = false,
    this.expired = false,
  });

  factory AdSessionState.fromJson(Map<String, dynamic> json) => AdSessionState(
    verified: json['verified'] as bool? ?? false,
    used: json['used'] as bool? ?? false,
    expired: json['expired'] as bool? ?? false,
  );
}

/// Client for the ad-funded quick analysis endpoints. Abstract so the flow
/// can be tested with a fake.
abstract class AdAnalysisApi {
  Future<AdAnalysisStatus> fetchStatus(String token);

  /// Throws [AdAnalysisException] for 403/422/429.
  Future<AdAnalysisSession> createSession(String token);

  Future<AdSessionState> fetchSession(String token, String sessionId);
}

class HttpAdAnalysisApi implements AdAnalysisApi {
  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  @override
  Future<AdAnalysisStatus> fetchStatus(String token) async {
    final r = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/ad-analysis/status'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw Exception('ad-analysis/status ${r.statusCode}');
    return AdAnalysisStatus.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<AdAnalysisSession> createSession(String token) async {
    final r = await ApiHttp.post(
      Uri.parse('${ApiConfig.baseUrl}/ad-analysis/sessions'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));
    return parseSessionResponse(r);
  }

  @override
  Future<AdSessionState> fetchSession(String token, String sessionId) async {
    final r = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/ad-analysis/sessions/$sessionId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw AdAnalysisException.fromResponse(r);
    }
    return AdSessionState.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  static AdAnalysisSession parseSessionResponse(http.Response r) {
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw AdAnalysisException.fromResponse(r);
    }
    return AdAnalysisSession.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
    );
  }
}
