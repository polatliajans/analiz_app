import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/radar_api.dart';
import '../models/radar_item.dart';
import '../utils/radar_tiers.dart';
import 'auth_provider.dart';
import 'price_alert_provider.dart';

final radarApiProvider = Provider<RadarApi>((ref) => RadarApi());

/// Guest (no session), free member or Pro.
final radarAccessProvider = Provider<RadarAccess>((ref) {
  final token = ref.watch(authProvider.select((s) => s.token));
  if (token == null) return RadarAccess.guest;
  return ref.watch(isProProvider) ? RadarAccess.pro : RadarAccess.free;
});

/// The family key is the term ('short'|'medium'|'long') or null for all terms.
/// Non-Pro users only ever get (and request) the short term: null maps to
/// 'short' and locked terms resolve to an empty list without a request.
final radarProvider = FutureProvider.family<List<RadarItem>, String?>((
  ref,
  term,
) async {
  final access = ref.watch(radarAccessProvider);
  final token = ref.watch(authProvider.select((s) => s.token));
  if (access != RadarAccess.pro) {
    if (term != null && term != 'short') return const <RadarItem>[];
    return ref.read(radarApiProvider).fetch(term: 'short', token: token);
  }
  return ref.read(radarApiProvider).fetch(term: term, token: token);
});
