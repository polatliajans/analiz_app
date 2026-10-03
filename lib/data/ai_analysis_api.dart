import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/ai_analysis_result.dart';

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
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/coins/$coinId/analyses');

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Authorization': 'Bearer $token'},
            body: {'timeframe': timeframe},
          )
          .timeout(const Duration(seconds: 50));
    } catch (e) {
      throw AiAnalysisException('Analiz isteği gönderilemedi: $e');
    }

    if (response.statusCode == 402) {
      throw AiAnalysisException('Yetersiz kredi.');
    }
    if (response.statusCode == 502) {
      throw AiAnalysisException('Analiz şu anda kullanılamıyor.');
    }
    if (response.statusCode != 200) {
      throw AiAnalysisException('Sunucu hatası: ${response.statusCode}');
    }

    return AiAnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
