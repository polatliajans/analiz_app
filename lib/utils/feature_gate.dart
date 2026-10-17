import '../models/app_config.dart';

/// Pure decisions about which features the current user may use. Pro is
/// unrestricted; Free and guests follow the server-provided [PlanConfig].
class FeatureGate {
  final PlanConfig plan;
  final bool isPro;

  const FeatureGate({required this.plan, required this.isPro});

  bool get canUseDeepAnalysis => isPro || !plan.deepAnalysisRequiresPro;

  bool isTimeframeLocked(String timeframe) =>
      !isPro && plan.proOnlyTimeframes.contains(timeframe);

  bool get isStrength3FilterLocked => !isPro && plan.strength3FilterRequiresPro;

  /// Max watchlist size, null when unlimited.
  int? get watchlistLimit => isPro ? null : plan.freeWatchlistMax;

  bool watchlistLimitReached(int count) {
    final limit = watchlistLimit;
    return limit != null && count >= limit;
  }

  /// A previously saved timeframe the user may no longer use falls back.
  String effectiveTimeframe(String saved) =>
      isTimeframeLocked(saved) ? fallbackTimeframe : saved;

  /// A previously saved strength filter the user may no longer use falls back.
  int effectiveMinStrength(int saved) =>
      (saved == 3 && isStrength3FilterLocked) ? 1 : saved;
}

/// Timeframe used when a saved one is locked.
const fallbackTimeframe = '15m';
