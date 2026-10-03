import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/chart_signal.dart';
import 'binance_klines_api.dart';

class ChartSignalApi {
  Future<List<ChartSignal>> fetchSignals({
    required int coinId,
    required String timeframe,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/coins/$coinId/chart-signals',
    ).replace(queryParameters: {'timeframe': timeframe});

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ChartDataException('Sinyal verisi alınamadı: $e');
    }

    if (response.statusCode != 200) {
      throw ChartDataException('Sunucu hatası: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => ChartSignal.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
