/// How a member's credit total splits into monthly plan credits (which expire
/// at renewal) and purchased credits (which never expire).
///
/// Every field is optional: an older server only sends the total, in which
/// case the UI falls back to the total and the generic policy text.
class CreditBreakdown {
  /// Monthly plan credits left.
  final int? planCredits;

  /// The package amount the plan credits are topped up to on renewal.
  final int? planCreditTotal;

  /// Credits bought in packs (never expire).
  final int? purchasedCredits;

  /// Next renewal (UTC); null when unknown.
  final DateTime? renewAt;

  const CreditBreakdown({
    this.planCredits,
    this.planCreditTotal,
    this.purchasedCredits,
    this.renewAt,
  });

  static const none = CreditBreakdown();

  /// True when the server told us the monthly part.
  bool get hasPlan => planCredits != null;

  bool get isEmpty =>
      planCredits == null &&
      planCreditTotal == null &&
      purchasedCredits == null &&
      renewAt == null;

  /// Reads the four fields from [json] (a member / credits payload); a nested
  /// `credits` object is accepted as a fallback. Never throws.
  factory CreditBreakdown.fromJson(Object? json) {
    if (json is! Map) return none;
    int? i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.isFinite ? v.round() : null;
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
      return null;
    }

    DateTime? d(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toUtc() : null;

    Object? pick(String key) {
      final top = json[key];
      if (top != null) return top;
      final nested = json['credits'];
      return nested is Map ? nested[key] : null;
    }

    return CreditBreakdown(
      planCredits: i(pick('plan_credits')),
      planCreditTotal: i(pick('plan_credit_total')),
      purchasedCredits: i(pick('purchased_credits')),
      renewAt: d(pick('credits_renew_at')),
    );
  }

  /// Whole calendar days (local) from [now] to [renewAt]; null if unknown,
  /// never negative.
  int? daysUntilRenewal(DateTime now) {
    final r = renewAt;
    if (r == null) return null;
    final a = DateTime(now.year, now.month, now.day);
    final rl = r.toLocal();
    final b = DateTime(rl.year, rl.month, rl.day);
    final days = b.difference(a).inDays;
    return days < 0 ? 0 : days;
  }

  /// Fraction of the monthly package still left, 0..1.
  double? get planFraction {
    final left = planCredits;
    final total = planCreditTotal;
    if (left == null || total == null || total <= 0) return null;
    return (left / total).clamp(0.0, 1.0);
  }
}

/// Friendly key for a credit-transaction type, or null for unknown types
/// (callers then show the server description / raw type).
bool isMonthlyResetType(String? type) => type == 'monthly_reset';
