import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';

class DeviceTokenException implements Exception {
  final String message;
  DeviceTokenException(this.message);

  @override
  String toString() => message;
}

class DeviceTokenApi {
  Future<void> register({
    required String token,
    required String fcmToken,
    required String platform,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/device-tokens');

    final http.Response response;
    try {
      response = await ApiHttp.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        body: {'fcm_token': fcmToken, 'platform': platform},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw DeviceTokenException(AppL10n.current.errorDeviceTokenFailed('$e'));
    }

    if (response.statusCode == 403) {
      throw DeviceTokenException(AppL10n.current.errorProOnly);
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DeviceTokenException(
        AppL10n.current.errorServer(response.statusCode),
      );
    }
  }
}
