import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/coin_overview.dart';
import 'api_http.dart';

class CoinOverviewException implements Exception {
  final String message;
  final int? statusCode;
  CoinOverviewException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// `GET /api/coins/{coin}/overview`. A server that does not know the endpoint
/// yet (404/405/501) yields [CoinOverview.empty] instead of an error, so the
/// tabs show their empty state.
class CoinOverviewApi {
  Future<CoinOverview> fetch(int coinId, {String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/coins/$coinId/overview');
    final response = await ApiHttp.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    final status = response.statusCode;
    if (status == 404 || status == 405 || status == 501) {
      return CoinOverview.empty;
    }
    if (status != 200) {
      throw CoinOverviewException(
        AppL10n.current.errorServer(status),
        statusCode: status,
      );
    }
    return CoinOverview.fromBody(response.body);
  }
}
