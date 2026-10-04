import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analysis_history_api.dart';
import '../models/analysis_record.dart';
import 'auth_provider.dart';

final analysisHistoryApiProvider = Provider<AnalysisHistoryApi>(
  (ref) => AnalysisHistoryApi(),
);

/// The member's past analyses; [coinId] null means all coins.
final analysisHistoryProvider =
    FutureProvider.family<List<AnalysisRecord>, int?>((ref, coinId) async {
      final token = ref.watch(authProvider).token;
      if (token == null) return [];
      return ref.watch(analysisHistoryApiProvider).fetch(token, coinId: coinId);
    });
