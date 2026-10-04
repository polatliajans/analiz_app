import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/radar_item.dart';

class RadarException implements Exception {
  final String message;
  RadarException(this.message);

  @override
  String toString() => message;
}

class RadarApi {
  Future<List<RadarItem>> fetch({String? term}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/radar',
    ).replace(queryParameters: term != null ? {'term': term} : null);

    final http.Response response;
    try {
      response = await ApiHttp.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw RadarException(AppL10n.current.errorRadarFailed('$e'));
    }

    if (response.statusCode != 200) {
      throw RadarException(
        AppL10n.current.errorRadarFailed('${response.statusCode}'),
      );
    }

    try {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => RadarItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RadarException(AppL10n.current.errorRadarFailed('$e'));
    }
  }
}
