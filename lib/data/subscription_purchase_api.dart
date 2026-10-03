import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class SubscriptionPurchaseResult {
  final String role;
  final bool alreadyProcessed;

  const SubscriptionPurchaseResult({required this.role, required this.alreadyProcessed});

  factory SubscriptionPurchaseResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchaseResult(
      role: json['role'] as String,
      alreadyProcessed: json['already_processed'] as bool,
    );
  }
}

class SubscriptionPurchaseException implements Exception {
  final String message;
  SubscriptionPurchaseException(this.message);

  @override
  String toString() => message;
}

class SubscriptionPurchaseApi {
  Future<SubscriptionPurchaseResult> verifySubscriptionPurchase({
    required String token,
    required int subscriptionPlanId,
    required String purchaseToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/purchases/subscriptions/$subscriptionPlanId');

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Authorization': 'Bearer $token'},
            body: {'purchase_token': purchaseToken},
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw SubscriptionPurchaseException('Abonelik doğrulanamadı: $e');
    }

    if (response.statusCode == 422) {
      throw SubscriptionPurchaseException('Abonelik geçerli değil.');
    }
    if (response.statusCode == 502) {
      throw SubscriptionPurchaseException('Google Play doğrulama servisine ulaşılamadı.');
    }
    if (response.statusCode != 200) {
      throw SubscriptionPurchaseException('Sunucu hatası: ${response.statusCode}');
    }

    return SubscriptionPurchaseResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
