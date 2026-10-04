import 'dart:convert';
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/coin.dart';

class WatchlistException implements Exception {
  final String message;
  WatchlistException(this.message);

  @override
  String toString() => message;
}

class WatchlistApi {
  Future<List<Coin>> fetchWatchlist(String token) async {
    final response = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/watchlist'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw WatchlistException(AppL10n.current.errorWatchlistFailed);
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Coin.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> follow(String token, int coinId) async {
    final response = await ApiHttp.post(
      Uri.parse('${ApiConfig.baseUrl}/watchlist'),
      headers: {'Authorization': 'Bearer $token'},
      body: {'coin_id': '$coinId'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 422) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw WatchlistException(
        json['message'] as String? ?? AppL10n.current.errorFollowFailed,
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw WatchlistException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }
  }

  Future<void> unfollow(String token, int coinId) async {
    final response = await ApiHttp.delete(
      Uri.parse('${ApiConfig.baseUrl}/watchlist/$coinId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw WatchlistException(AppL10n.current.errorUnfollowFailed);
    }
  }
}
