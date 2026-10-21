import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/home_data.dart';
import 'api_http.dart';

class HomeException implements Exception {
  final String message;
  final int? statusCode;
  HomeException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// A parsed response together with the raw body (kept for the local cache).
class HomeResponse {
  final HomeData data;
  final String rawBody;
  const HomeResponse(this.data, this.rawBody);
}

class HomeApi {
  Future<HomeResponse> fetch(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/home');
    final response = await ApiHttp.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HomeException(
        AppL10n.current.errorServer(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    try {
      return HomeResponse(HomeData.fromBody(response.body), response.body);
    } on FormatException catch (e) {
      throw HomeException(AppL10n.current.errorServerUnreachable(e.message));
    }
  }
}
