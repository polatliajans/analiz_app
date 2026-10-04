import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
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
      response = await ApiHttp.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw CoinApiException(AppL10n.current.errorServerUnreachable('$e'));
    }

    if (response.statusCode != 200) {
      throw CoinApiException(AppL10n.current.errorServer(response.statusCode));
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Coin.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
