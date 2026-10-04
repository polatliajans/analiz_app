import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../models/subscription_plan.dart';

class SubscriptionPlanException implements Exception {
  final String message;
  SubscriptionPlanException(this.message);

  @override
  String toString() => message;
}

class SubscriptionPlanApi {
  Future<List<SubscriptionPlan>> fetchActivePlans() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscription-plans');

    final http.Response response;
    try {
      response = await ApiHttp.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw SubscriptionPlanException(AppL10n.current.errorPlansFailed('$e'));
    }

    if (response.statusCode != 200) {
      throw SubscriptionPlanException(
        AppL10n.current.errorPlansFailed('${response.statusCode}'),
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
