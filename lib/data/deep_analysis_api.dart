import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/deep_analysis_job.dart';
import 'plan_errors.dart';

class DeepAnalysisException implements Exception {
  final String message;
  DeepAnalysisException(this.message);

  @override
  String toString() => message;
}

/// 409: the member already has a queued/running deep analysis.
class DeepAnalysisInProgressException implements Exception {
  final String message;
  DeepAnalysisInProgressException(this.message);

  @override
  String toString() => message;
}

/// The job does not exist (404, e.g. it belongs to another account).
class DeepAnalysisJobNotFoundException implements Exception {
  @override
  String toString() => 'deep analysis job not found';
}

class DeepAnalysisApi {
  /// Starts a background deep analysis; returns the queued job (HTTP 202).
  Future<DeepAnalysisJob> startDeepAnalysis({
    required String token,
    required int coinId,
    required String timeframe,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/coins/$coinId/deep-analyses');

    final http.Response response;
    try {
      response = await ApiHttp.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        body: {'timeframe': timeframe},
      ).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw DeepAnalysisException(
        AppL10n.current.errorDeepAnalysisRequestFailed('$e'),
      );
    }
    return parseStartResponse(response);
  }

  /// Current state of a job. Network errors propagate as-is so callers can
  /// treat them as transient.
  Future<DeepAnalysisJob> fetchDeepAnalysisJob({
    required String token,
    required int jobId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/deep-analyses/jobs/$jobId');
    final response = await ApiHttp.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    return parseJobResponse(response);
  }

  static DeepAnalysisJob parseStartResponse(http.Response response) {
    if (isProRequired(response)) throw ProRequiredException();
    if (response.statusCode == 402) throw InsufficientCreditException();
    if (response.statusCode == 409) {
      throw DeepAnalysisInProgressException(_messageOf(response));
    }
    if (response.statusCode == 502) {
      throw DeepAnalysisException(AppL10n.current.errorDeepAnalysisUnavailable);
    }
    if (response.statusCode != 202 && response.statusCode != 200) {
      throw DeepAnalysisException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DeepAnalysisJob.fromJson(body['job'] as Map<String, dynamic>);
  }

  static DeepAnalysisJob parseJobResponse(http.Response response) {
    if (response.statusCode == 404) throw DeepAnalysisJobNotFoundException();
    if (response.statusCode != 200) {
      throw DeepAnalysisException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }
    return DeepAnalysisJob.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static String _messageOf(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {}
    return AppL10n.current.deepAnalysisAlreadyRunning;
  }
}
