import 'package:flutter/foundation.dart';

class CreditPackage {
  final int id;
  final String name;
  final int creditAmount;
  final String price;
  final String? storeProductIdAndroid;

  /// App Store product id; null on older servers (falls back to the Android id).
  final String? appleProductId;

  const CreditPackage({
    required this.id,
    required this.name,
    required this.creditAmount,
    required this.price,
    this.storeProductIdAndroid,
    this.appleProductId,
  });

  /// Product id to query/buy on [platform] (iOS: Apple id, else Android id).
  String? productIdFor(TargetPlatform platform) =>
      platform == TargetPlatform.iOS
      ? (appleProductId ?? storeProductIdAndroid)
      : storeProductIdAndroid;

  /// Product id for the platform the app is running on.
  String? get storeProductId => productIdFor(defaultTargetPlatform);

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      id: json['id'] as int,
      name: json['name'] as String,
      creditAmount: json['credit_amount'] as int,
      price: json['price'].toString(),
      storeProductIdAndroid: json['store_product_id_android'] as String?,
      appleProductId: json['apple_product_id'] as String?,
    );
  }
}
