import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/coin.dart';

class CoinApiException implements Exception {
  final String message;
  CoinApiException(this.message);

  @override
  String toString() => message;
}

class CoinApi {
  Future<List<Coin>> fetchCoins({String? marketType}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/coins').replace(
      queryParameters: marketType != null ? {'market_type': marketType} : null,
    );

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw CoinApiException('Sunucuya bağlanılamadı: $e');
    }

    if (response.statusCode != 200) {
      throw CoinApiException('Sunucu hatası: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((json) => Coin.fromJson(json as Map<String, dynamic>)).toList();
  }
}
