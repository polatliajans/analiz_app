import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/ai_analysis_result.dart';

class DeepAnalysisException implements Exception {
  final String message;
  DeepAnalysisException(this.message);

  @override
  String toString() => message;
}

class DeepAnalysisApi {
  Future<AiAnalysisResult> requestAnalysis({
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
      ).timeout(const Duration(seconds: 70));
    } catch (e) {
      throw DeepAnalysisException(
        AppL10n.current.errorDeepAnalysisRequestFailed('$e'),
      );
    }

    if (response.statusCode == 402) {
      throw DeepAnalysisException(AppL10n.current.errorInsufficientCredit);
    }
    if (response.statusCode == 502) {
      throw DeepAnalysisException(AppL10n.current.errorDeepAnalysisUnavailable);
    }
    if (response.statusCode != 200) {
      throw DeepAnalysisException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }

    return AiAnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
