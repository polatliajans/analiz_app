class CreditPackage {
  final int id;
  final String name;
  final int creditAmount;
  final String price;
  final String? storeProductIdAndroid;

  const CreditPackage({
    required this.id,
    required this.name,
    required this.creditAmount,
    required this.price,
    this.storeProductIdAndroid,
  });

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      id: json['id'] as int,
      name: json['name'] as String,
      creditAmount: json['credit_amount'] as int,
      price: json['price'].toString(),
      storeProductIdAndroid: json['store_product_id_android'] as String?,
    );
  }
}
