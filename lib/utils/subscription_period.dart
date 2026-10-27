import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../l10n/app_localizations.dart';

/// The billing period StoreKit reports for [details] as user-facing text
/// ("per month", "every 3 months"); null when it is not an App Store
/// subscription product (the caller then falls back to the plan's duration).
String? storeKitPeriodText(ProductDetails? details, AppLocalizations l10n) {
  if (details is! AppStoreProductDetails) return null;
  final period = details.skProduct.subscriptionPeriod;
  if (period == null || period.numberOfUnits <= 0) return null;
  final n = period.numberOfUnits;
  return switch (period.unit) {
    SKSubscriptionPeriodUnit.day => l10n.subPeriodDay(n),
    SKSubscriptionPeriodUnit.week => l10n.subPeriodWeek(n),
    SKSubscriptionPeriodUnit.month => l10n.subPeriodMonth(n),
    SKSubscriptionPeriodUnit.year => l10n.subPeriodYear(n),
  };
}
