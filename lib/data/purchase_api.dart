import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';

class PurchaseResult {
  final int creditBalance;
  final bool alreadyProcessed;

  const PurchaseResult({
    required this.creditBalance,
    required this.alreadyProcessed,
  });

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      creditBalance: json['credit_balance'] as int,
      alreadyProcessed: json['already_processed'] as bool,
    );
  }
}

class PurchaseException implements Exception {
  final String message;
  PurchaseException(this.message);

  @override
  String toString() => message;
}

class PurchaseApi {
  Future<PurchaseResult> verifyCreditPackagePurchase({
    required String token,
    required int creditPackageId,
    required String purchaseToken,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/purchases/credit-packages/$creditPackageId',
    );

    final http.Response response;
    try {
      response = await ApiHttp.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        body: {'purchase_token': purchaseToken},
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PurchaseException(AppL10n.current.errorPurchaseVerifyFailed('$e'));
    }

    if (response.statusCode == 422) {
      throw PurchaseException(AppL10n.current.errorPurchaseInvalid);
    }
    if (response.statusCode == 502) {
      throw PurchaseException(AppL10n.current.errorPlayVerificationUnreachable);
    }
    if (response.statusCode != 200) {
      throw PurchaseException(AppL10n.current.errorServer(response.statusCode));
    }

    return PurchaseResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
