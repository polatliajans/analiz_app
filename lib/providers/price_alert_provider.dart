import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/price_alert_api.dart';
import '../models/price_alert.dart';
import 'auth_provider.dart';

final priceAlertApiProvider = Provider<PriceAlertApi>((ref) => PriceAlertApi());

/// The signed-in member's alerts (empty for guests).
final priceAlertsProvider = FutureProvider<PriceAlertList>((ref) async {
  final token = ref.watch(authProvider.select((s) => s.token));
  if (token == null) return const PriceAlertList();
  return ref.watch(priceAlertApiProvider).fetchAlerts(token);
});

/// Whether the signed-in member has the Pro role.
final isProProvider = Provider<bool>(
  (ref) => ref.watch(authProvider.select((s) => s.member?.role)) == 'pro',
);
