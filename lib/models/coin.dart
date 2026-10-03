class Coin {
  final int id;
  final String symbol;
  final String name;
  final String marketType;
  final double? lastPrice;
  final double? priceChangePercent24h;
  final double? volume24h;

  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.marketType,
    required this.lastPrice,
    required this.priceChangePercent24h,
    required this.volume24h,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      marketType: json['market_type'] as String,
      lastPrice: _parseNullableDouble(json['last_price']),
      priceChangePercent24h: _parseNullableDouble(json['price_change_percent_24h']),
      volume24h: _parseNullableDouble(json['volume_24h']),
    );
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
