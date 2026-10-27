import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Store [ProductDetails] (localized title, price, billing period) keyed by
/// product id. The argument is the product ids joined with ','. Empty when
/// the store is unavailable, so callers fall back to the server's data.
final storeProductsProvider =
    FutureProvider.family<Map<String, ProductDetails>, String>((
      ref,
      joinedIds,
    ) async {
      final ids = joinedIds.split(',').where((id) => id.isNotEmpty).toSet();
      if (ids.isEmpty) return {};
      try {
        final iap = InAppPurchase.instance;
        if (!await iap.isAvailable()) return {};
        final response = await iap.queryProductDetails(ids);
        return {for (final d in response.productDetails) d.id: d};
      } catch (_) {
        return {};
      }
    });
