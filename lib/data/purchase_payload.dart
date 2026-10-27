import 'package:in_app_purchase/in_app_purchase.dart';

import '../utils/platform_info.dart';

/// What the server needs to verify a store purchase.
class PurchaseProof {
  /// Android: the Play purchase token. iOS: the StoreKit transaction id.
  final String token;

  /// iOS only: the base64 App Store receipt (`serverVerificationData`).
  final String? receipt;

  const PurchaseProof(this.token, [this.receipt]);
}

/// Builds the proof from raw store fields. On iOS `purchaseID` is the numeric
/// StoreKit transactionIdentifier and `serverVerificationData` the receipt.
/// Returns null on iOS when the id is missing or not numeric: the receipt is
/// never used as the purchase token (the caller keeps the transaction pending
/// and tells the user instead).
PurchaseProof? purchaseProofFrom({
  required bool ios,
  required String? purchaseId,
  required String serverVerificationData,
}) {
  if (!ios) return PurchaseProof(serverVerificationData);
  final id = purchaseId?.trim();
  if (id == null || id.isEmpty || int.tryParse(id) == null) return null;
  return PurchaseProof(id, serverVerificationData);
}

PurchaseProof? purchaseProofOf(PurchaseDetails purchase, {bool? ios}) =>
    purchaseProofFrom(
      ios: ios ?? isIOS,
      purchaseId: purchase.purchaseID,
      serverVerificationData: purchase.verificationData.serverVerificationData,
    );

/// POST body for `/purchases/credit-packages/{id}` and
/// `/purchases/subscriptions/{id}`. Android keeps its original single-field
/// body; iOS adds `platform` and `receipt`.
Map<String, String> buildPurchaseBody(PurchaseProof proof, {String? platform}) {
  final p = platform ?? platformName();
  if (p != 'ios') return {'purchase_token': proof.token};
  return {
    'platform': 'ios',
    'purchase_token': proof.token,
    'receipt': proof.receipt ?? '',
  };
}
