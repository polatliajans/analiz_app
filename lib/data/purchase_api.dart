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

/// The machine-readable `code` of a server error body, or null.
String? purchaseErrorCode(String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map && json['code'] is String) return json['code'] as String;
  } catch (_) {}
  return null;
}

/// True when the server rejected the token with `purchase_already_processed`.
bool isPurchaseAlreadyProcessed(String body) =>
    purchaseErrorCode(body) == 'purchase_already_processed';

/// 422: the Apple subscription is linked to a different member account.
const codeSubscriptionBoundToOtherAccount =
    'subscription_bound_to_other_account';

/// 409: the member already has an active Pro subscription from the other
/// store (Google Play vs App Store).
const codeSubscriptionActiveOtherStore = 'subscription_active_other_store';

class PurchaseException implements Exception {
  final String message;

  /// The server already credited this purchase earlier; the store transaction
  /// can safely be finished.
  final bool alreadyProcessed;

  /// The server rejected the purchase for good (422 invalid / refunded):
  /// retrying can never succeed.
  final bool permanent;

  /// Server `code` (e.g. [codeSubscriptionBoundToOtherAccount]), if any.
  final String? code;
  PurchaseException(
    this.message, {
    this.alreadyProcessed = false,
    this.permanent = false,
    this.code,
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

/// "You already have an active Pro subscription via the other store".
String activeOtherStoreText() => AppL10n.current.purchaseActiveOtherStore(
  isIOS ? 'Google Play' : 'App Store',
  isIOS ? 'App Store' : 'Google Play',
);
