import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
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
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw SubscriptionPlanException('Abonelik planları alınamadı: $e');
    }

    if (response.statusCode != 200) {
      throw SubscriptionPlanException(
        'Abonelik planları alınamadı: ${response.statusCode}',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
