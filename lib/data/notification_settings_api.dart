import 'dart:convert';

import '../config/api_config.dart';
import 'api_http.dart';

const notificationSettingKeys = [
  'announcements',
  'credits',
  'signals',
  'alerts',
];

class NotificationSettings {
  final Map<String, bool> values;
  final Set<String> proOnly;

  const NotificationSettings({required this.values, required this.proOnly});

  /// Missing keys mean "on".
  bool isOn(String key) => values[key] ?? true;

  bool isProOnly(String key) => proOnly.contains(key);

  NotificationSettings withValue(String key, bool value) =>
      NotificationSettings(values: {...values, key: value}, proOnly: proOnly);

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['settings'];
    final values = <String, bool>{};
    if (raw is Map) {
      for (final key in notificationSettingKeys) {
        final v = raw[key];
        if (v is bool) values[key] = v;
      }
    }
    final pro = json['pro_only'];
    return NotificationSettings(
      values: values,
      proOnly: pro is List
          ? pro.whereType<String>().toSet()
          : {'signals', 'alerts'},
    );
  }
}

class NotificationSettingsException implements Exception {
  final int? statusCode;
  const NotificationSettingsException([this.statusCode]);

  @override
  String toString() => 'NotificationSettingsException($statusCode)';
}

class NotificationSettingsApi {
  static Uri get _uri =>
      Uri.parse('${ApiConfig.baseUrl}/notification-settings');

  Map<String, String> _headers(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
  };

  Future<NotificationSettings> fetch(String token) async {
    final response = await ApiHttp.get(
      _uri,
      headers: _headers(token),
    ).timeout(const Duration(seconds: 15));
    return _parse(response.statusCode, response.body);
  }

  /// Sends any subset of the boolean settings.
  Future<NotificationSettings> update(
    String token,
    Map<String, bool> changes,
  ) async {
    final response = await ApiHttp.put(
      _uri,
      headers: _headers(token, json: true),
      body: jsonEncode(changes),
    ).timeout(const Duration(seconds: 15));
    return _parse(response.statusCode, response.body);
  }

  NotificationSettings _parse(int status, String body) {
    if (status != 200) throw NotificationSettingsException(status);
    try {
      return NotificationSettings.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const NotificationSettingsException();
    }
  }
}
