import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/ai_analysis_result.dart';
import 'ad_analysis_api.dart';
import 'plan_errors.dart';

class AiAnalysisException implements Exception {
  final String message;
  AiAnalysisException(this.message);

  @override
  String toString() => message;
}

class AiAnalysisApi {
  Future<AiAnalysisResult> requestAnalysis({
    required String token,
    required int coinId,
    required String timeframe,
    String? adSessionId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/coins/$coinId/analyses');

    final http.Response response;
    try {
      response = await ApiHttp.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        body: {
          'timeframe': timeframe,
          'ad_session_id': ?adSessionId,
        },
      ).timeout(const Duration(seconds: 50));
    } catch (e) {
      throw AiAnalysisException(
        AppL10n.current.errorAnalysisRequestFailed('$e'),
      );
    }

    return parseResponse(response, withAdSession: adSessionId != null);
  }

  /// Maps a quick-analysis response to a result or a typed exception.
  static AiAnalysisResult parseResponse(
    http.Response response, {
    bool withAdSession = false,
  }) {
    if (isProRequired(response)) throw ProRequiredException();
    if (withAdSession && isAdAnalysisCode(errorCodeOf(response))) {
      throw AdAnalysisException.fromResponse(response);
    }
    if (response.statusCode == 402) throw InsufficientCreditException();
    if (response.statusCode == 502) {
      throw AiAnalysisException(AppL10n.current.errorAnalysisUnavailable);
    }
    if (response.statusCode != 200) {
      throw AiAnalysisException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }

    return AiAnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
