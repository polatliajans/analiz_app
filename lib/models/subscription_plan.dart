class SubscriptionPlan {
  final int id;
  final String name;
  final String price;
  final int durationDays;
  final String? storeProductIdAndroid;
  final int monthlyCredit;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.storeProductIdAndroid,
    this.monthlyCredit = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'].toString(),
      durationDays: json['duration_days'] as int,
      storeProductIdAndroid: json['store_product_id_android'] as String?,
      monthlyCredit: (json['monthly_credit'] as num?)?.toInt() ?? 0,
    );
  }
}
