import 'package:http/http.dart' as http;

import '../config/api_config.dart';

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
      response = await http
          .post(
            uri,
            headers: {'Authorization': 'Bearer $token'},
            body: {'fcm_token': fcmToken, 'platform': platform},
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw DeviceTokenException('Cihaz token\'ı kaydedilemedi: $e');
    }

    if (response.statusCode == 403) {
      throw DeviceTokenException('Bu özellik sadece Pro üyeler içindir.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DeviceTokenException('Sunucu hatası: ${response.statusCode}');
    }
  }
}
