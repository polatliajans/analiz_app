import '../models/app_config.dart';
import '../models/chart_signal.dart';

/// Pure decisions about which features the current user may use. Pro is
/// unrestricted; Free and guests follow the server-provided [PlanConfig].
class FeatureGate {
  final PlanConfig plan;
  final bool isPro;

  const FeatureGate({required this.plan, required this.isPro});

  bool get canUseDeepAnalysis => isPro || !plan.deepAnalysisRequiresPro;

  bool isTimeframeLocked(String timeframe) =>
      !isPro && plan.proOnlyTimeframes.contains(timeframe);

  /// Pro sees every signal strength; Free / guests only up to
  /// [PlanConfig.freeMaxSignalStrength] (the server enforces it too).
  bool isSignalVisible(int strength) =>
      isPro || strength <= plan.freeMaxSignalStrength;

  List<ChartSignal> visibleSignals(List<ChartSignal> signals) => isPro
      ? signals
      : signals.where((s) => isSignalVisible(s.strength)).toList();

  /// Whether to hint that stronger signals exist in Pro.
  bool get showStrongSignalsNote => !isPro && plan.freeMaxSignalStrength < 3;

  /// Max watchlist size, null when unlimited.
  int? get watchlistLimit => isPro ? null : plan.freeWatchlistMax;

  bool watchlistLimitReached(int count) {
    final limit = watchlistLimit;
    return limit != null && count >= limit;
  }

  /// A previously saved timeframe the user may no longer use falls back.
  String effectiveTimeframe(String saved) =>
      isTimeframeLocked(saved) ? fallbackTimeframe : saved;
}

/// Timeframe used when a saved one is locked.
const fallbackTimeframe = '15m';
