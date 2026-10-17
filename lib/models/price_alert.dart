import '../utils/price_alert_logic.dart';

enum PriceAlertStatus {
  active,
  triggered,
  canceled;

  static PriceAlertStatus fromApi(String? value) {
    for (final s in PriceAlertStatus.values) {
      if (s.name == value) return s;
    }
    return PriceAlertStatus.canceled;
  }
}

class PriceAlert {
  final int id;
  final int coinId;
  final String symbol;
  final String marketType;
  final double targetPrice;
  final AlertDirection direction;
  final PriceAlertStatus status;
  final DateTime? triggeredAt;
  final double? triggeredPrice;
  final DateTime? createdAt;

  const PriceAlert({
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.marketType,
    required this.targetPrice,
    required this.direction,
    required this.status,
    this.triggeredAt,
    this.triggeredPrice,
    this.createdAt,
  });

  bool get isActive => status == PriceAlertStatus.active;

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as int,
      coinId: json['coin_id'] as int,
      symbol: json['symbol'] as String? ?? '',
      marketType: json['market_type'] as String? ?? 'spot',
      targetPrice: _num(json['target_price']) ?? 0,
      direction:
          AlertDirection.fromApi(json['direction'] as String?) ??
          AlertDirection.above,
      status: PriceAlertStatus.fromApi(json['status'] as String?),
      triggeredAt: _date(json['triggered_at']),
      triggeredPrice: _num(json['triggered_price']),
      createdAt: _date(json['created_at']),
    );
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
}

/// Response of GET /api/alerts.
class PriceAlertList {
  final int maxActive;
  final List<PriceAlert> alerts;

  const PriceAlertList({this.maxActive = 20, this.alerts = const []});

  List<PriceAlert> get active => [
    for (final a in alerts)
      if (a.isActive) a,
  ];

  List<PriceAlert> get history => [
    for (final a in alerts)
      if (!a.isActive) a,
  ];

  List<PriceAlert> activeForCoin(int coinId) => [
    for (final a in alerts)
      if (a.isActive && a.coinId == coinId) a,
  ];

  factory PriceAlertList.fromJson(Map<String, dynamic> json) {
    final raw = json['alerts'] as List<dynamic>? ?? const [];
    return PriceAlertList(
      maxActive: (json['max_active'] as num?)?.toInt() ?? 20,
      alerts: [
        for (final a in raw) PriceAlert.fromJson(a as Map<String, dynamic>),
      ],
    );
  }
}
