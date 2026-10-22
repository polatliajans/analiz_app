import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ad_analysis_api.dart';
import 'auth_provider.dart';

final adAnalysisApiProvider = Provider<AdAnalysisApi>(
  (ref) => HttpAdAnalysisApi(),
);

/// Today's ad-analysis allowance for the signed-in member; null for guests
/// or when the request fails (the ad option is then simply not offered).
final adAnalysisStatusProvider = FutureProvider.autoDispose<AdAnalysisStatus?>((
  ref,
) async {
  final token = ref.watch(authProvider.select((s) => s.token));
  if (token == null) return null;
  try {
    return await ref.watch(adAnalysisApiProvider).fetchStatus(token);
  } catch (_) {
    return null;
  }
});
