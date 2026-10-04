import 'dart:convert';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/analysis_record.dart';
import 'api_http.dart';

class AnalysisHistoryException implements Exception {
  final String message;
  AnalysisHistoryException(this.message);

  @override
  String toString() => message;
}

class AnalysisHistoryApi {
  Future<List<AnalysisRecord>> fetch(String token, {int? coinId}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/analyses',
    ).replace(queryParameters: coinId == null ? null : {'coin_id': '$coinId'});
    final response = await ApiHttp.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw AnalysisHistoryException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((j) => AnalysisRecord.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
