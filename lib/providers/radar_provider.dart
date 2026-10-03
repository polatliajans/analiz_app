import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/radar_api.dart';
import '../models/radar_item.dart';

/// The family key is the term ('short'|'medium'|'long') or null for all terms.
final radarProvider = FutureProvider.family<List<RadarItem>, String?>((
  ref,
  term,
) {
  return RadarApi().fetch(term: term);
});
