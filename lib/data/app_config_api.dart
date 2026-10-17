import 'dart:convert';

import '../config/api_config.dart';
import '../models/app_config.dart';
import 'api_http.dart';

class AppConfigApi {
  /// Fetches plan limits and ad settings. [token] is optional: without it the
  /// server answers as for a guest.
  Future<AppConfig> fetch({String? token}) async {
    final response = await ApiHttp.get(
      Uri.parse('${ApiConfig.baseUrl}/app-config'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('app-config ${response.statusCode}');
    }
    return AppConfig.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
