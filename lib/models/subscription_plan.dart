import 'package:flutter/foundation.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final String price;
  final int durationDays;
  final String? storeProductIdAndroid;

  /// App Store product id; null on older servers (falls back to the Android id).
  final String? appleProductId;
  final int monthlyCredit;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.storeProductIdAndroid,
    this.appleProductId,
    this.monthlyCredit = 0,
  });

  /// Product id to query/buy on [platform] (iOS: Apple id, else Android id).
  String? productIdFor(TargetPlatform platform) =>
      platform == TargetPlatform.iOS
      ? (appleProductId ?? storeProductIdAndroid)
      : storeProductIdAndroid;

  /// Product id for the platform the app is running on.
  String? get storeProductId => productIdFor(defaultTargetPlatform);

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'].toString(),
      durationDays: json['duration_days'] as int,
      storeProductIdAndroid: json['store_product_id_android'] as String?,
      appleProductId: json['apple_product_id'] as String?,
      monthlyCredit: (json['monthly_credit'] as num?)?.toInt() ?? 0,
    );
  }
}
