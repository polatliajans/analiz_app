import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_http.dart';
import 'purchase_payload.dart';

import '../config/api_config.dart';
import '../l10n/app_l10n.dart';
import '../utils/platform_info.dart';

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

/// True when the server rejected the token with `purchase_already_processed`.
bool isPurchaseAlreadyProcessed(String body) {
  try {
    final json = jsonDecode(body);
    return json is Map && json['code'] == 'purchase_already_processed';
  } catch (_) {
    return false;
  }
}

class PurchaseException implements Exception {
  final String message;

  /// The server already credited this purchase earlier; the store transaction
  /// can safely be finished.
  final bool alreadyProcessed;

  /// The server rejected the purchase for good (422 invalid / refunded):
  /// retrying can never succeed.
  final bool permanent;
  PurchaseException(
    this.message, {
    this.alreadyProcessed = false,
    this.permanent = false,
  });

  @override
  String toString() => message;
}

class PurchaseApi {
  Future<PurchaseResult> verifyCreditPackagePurchase({
    required String token,
    required int creditPackageId,
    required PurchaseProof proof,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/purchases/credit-packages/$creditPackageId',
    );

    final http.Response response;
    try {
      response = await ApiHttp.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
        body: buildPurchaseBody(proof),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw PurchaseException(AppL10n.current.errorPurchaseVerifyFailed('$e'));
    }

    if ((response.statusCode == 422 || response.statusCode == 409) &&
        isPurchaseAlreadyProcessed(response.body)) {
      throw PurchaseException(
        AppL10n.current.errorPurchaseAlreadyProcessed,
        alreadyProcessed: true,
      );
    }
    if (response.statusCode == 422) {
      throw PurchaseException(
        AppL10n.current.errorPurchaseInvalid,
        permanent: true,
      );
    }
    if (response.statusCode == 502) {
      throw PurchaseException(storeVerificationUnreachableText());
    }
    if (response.statusCode != 200) {
      throw PurchaseException(AppL10n.current.errorServer(response.statusCode));
    }

    return PurchaseResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

/// "Could not reach the store verification service" in the right store's name.
String storeVerificationUnreachableText() => isIOS
    ? AppL10n.current.errorStoreVerificationUnreachableIos
    : AppL10n.current.errorPlayVerificationUnreachable;
