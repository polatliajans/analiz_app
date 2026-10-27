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

/// Builds the proof from raw store fields. On iOS `purchaseID` is the
/// transactionIdentifier and `serverVerificationData` the receipt; if StoreKit
/// gave no id the receipt doubles as the token so the server can still resolve
/// the transaction.
PurchaseProof purchaseProofFrom({
  required bool ios,
  required String? purchaseId,
  required String serverVerificationData,
}) {
  if (!ios) return PurchaseProof(serverVerificationData);
  final id = (purchaseId == null || purchaseId.isEmpty)
      ? serverVerificationData
      : purchaseId;
  return PurchaseProof(id, serverVerificationData);
}

PurchaseProof purchaseProofOf(PurchaseDetails purchase) => purchaseProofFrom(
  ios: isIOS,
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
