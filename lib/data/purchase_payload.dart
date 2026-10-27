import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

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

/// The transaction id the server should look up on iOS. A StoreKit 1
/// `restored` transaction carries a NEW transactionIdentifier that Apple's
/// server API does not know; the original purchase's id does, so it is
/// preferred there. Fresh purchases keep their own id.
String? _iosTransactionId(PurchaseDetails purchase) {
  if (purchase.status == PurchaseStatus.restored &&
      purchase is AppStorePurchaseDetails) {
    final original = purchase
        .skPaymentTransaction
        .originalTransaction
        ?.transactionIdentifier
        ?.trim();
    if (original != null && original.isNotEmpty) return original;
  }
  return purchase.purchaseID;
}

PurchaseProof? purchaseProofOf(PurchaseDetails purchase, {bool? ios}) {
  final onIos = ios ?? isIOS;
  return purchaseProofFrom(
    ios: onIos,
    purchaseId: onIos ? _iosTransactionId(purchase) : purchase.purchaseID,
    serverVerificationData: purchase.verificationData.serverVerificationData,
  );
}

/// POST body for `/purchases/credit-packages/{id}` and
/// `/purchases/subscriptions/{id}`. Android keeps its original single-field
/// body; iOS adds `platform`. The server reads only `purchase_token` (it
/// verifies by transaction id through the App Store Server API), so the
/// base64 receipt is not sent.
Map<String, String> buildPurchaseBody(PurchaseProof proof, {String? platform}) {
  final p = platform ?? platformName();
  if (p != 'ios') return {'purchase_token': proof.token};
  return {'platform': 'ios', 'purchase_token': proof.token};
}
