import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/candle.dart';

class ChartDataException implements Exception {
  final String message;
  ChartDataException(this.message);

  @override
  String toString() => message;
}

class BinanceKlinesApi {
  Future<List<Candle>> fetchKlines({
    required String symbol,
    required String marketType,
    required String timeframe,
    int limit = 300,
  }) async {
    final host = marketType == 'futures'
        ? 'https://fapi.binance.com/fapi/v1/klines'
        : 'https://api.binance.com/api/v3/klines';

    final uri = Uri.parse(host).replace(
      queryParameters: {
        'symbol': symbol,
        'interval': timeframe,
        'limit': '$limit',
      },
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw ChartDataException('Mum verisi alınamadı: $e');
    }

    if (response.statusCode != 200) {
      throw ChartDataException('Binance hatası: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((row) => Candle.fromKline(row as List<dynamic>)).toList();
  }
}
