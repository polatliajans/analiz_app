import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Store-localized prices keyed by product id. The argument is the product ids
/// joined with ',' (a String, so the family key has value equality). Returns an
/// empty map when the store is unavailable, so callers can fall back to the
/// price the backend sent.
final storePricesProvider = FutureProvider.family<Map<String, String>, String>((
  ref,
  joinedIds,
) async {
  final ids = joinedIds.split(',').where((id) => id.isNotEmpty).toSet();
  if (ids.isEmpty) return {};

  try {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) return {};
    final response = await iap.queryProductDetails(ids);
    return {
      for (final details in response.productDetails) details.id: details.price,
    };
  } catch (_) {
    return {};
  }
});
