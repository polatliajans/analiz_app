/// Plan limits (what Free / guest users may do) as served by
/// `GET /api/app-config`.
class PlanConfig {
  /// "guest", "free" or "pro" as seen by the server.
  final String role;

  /// Max watchlist size for non-Pro users; null means unlimited.
  final int? freeWatchlistMax;
  final bool deepAnalysisRequiresPro;
  final List<String> proOnlyTimeframes;

  /// Highest signal strength Free / guest users get from the server (1..3).
  final int freeMaxSignalStrength;
  final bool alertsRequirePro;

  const PlanConfig({
    this.role = 'guest',
    this.freeWatchlistMax = 10,
    this.deepAnalysisRequiresPro = true,
    this.proOnlyTimeframes = const ['1m', '5m'],
    this.freeMaxSignalStrength = 2,
    this.alertsRequirePro = true,
  });

  /// Safe behaviour used offline / on error before any value was cached.
  static const safeDefaults = PlanConfig();

  factory PlanConfig.fromJson(Map<String, dynamic> json) {
    const d = PlanConfig.safeDefaults;
    final tfs = json['pro_only_timeframes'];
    return PlanConfig(
      role: json['role'] as String? ?? d.role,
      freeWatchlistMax: json.containsKey('free_watchlist_max')
          ? (json['free_watchlist_max'] as num?)?.toInt()
          : d.freeWatchlistMax,
      deepAnalysisRequiresPro:
          json['deep_analysis_requires_pro'] as bool? ??
          d.deepAnalysisRequiresPro,
      proOnlyTimeframes: tfs is List
          ? tfs.map((e) => '$e').toList()
          : d.proOnlyTimeframes,
      freeMaxSignalStrength:
          (json['free_max_signal_strength'] as num?)?.toInt().clamp(1, 3) ??
          d.freeMaxSignalStrength,
      alertsRequirePro: json['alerts_require_pro'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'free_watchlist_max': freeWatchlistMax,
    'deep_analysis_requires_pro': deepAnalysisRequiresPro,
    'pro_only_timeframes': proOnlyTimeframes,
    'free_max_signal_strength': freeMaxSignalStrength,
    'alerts_require_pro': alertsRequirePro,
  };
}

class AdPlacement {
  final String key;
  final String type;
  final String? unitId;
  final int? frequency;
  final int? cooldownMinutes;

  const AdPlacement({
    required this.key,
    required this.type,
    this.unitId,
    this.frequency,
    this.cooldownMinutes,
  });

  factory AdPlacement.fromJson(Map<String, dynamic> json) => AdPlacement(
    key: json['key'] as String? ?? '',
    type: json['type'] as String? ?? '',
    unitId: json['unit_id'] as String?,
    frequency: (json['frequency'] as num?)?.toInt(),
    cooldownMinutes: (json['cooldown_minutes'] as num?)?.toInt(),
  );
}

class RewardedConfig {
  final bool enabled;
  final String? unitId;
  final int amount;
  final int dailyCap;

  /// Rewards the member can still earn today; null for guests.
  final int? remainingToday;

  const RewardedConfig({
    this.enabled = false,
    this.unitId,
    this.amount = 0,
    this.dailyCap = 0,
    this.remainingToday,
  });

  factory RewardedConfig.fromJson(Map<String, dynamic> json) => RewardedConfig(
    enabled: json['enabled'] as bool? ?? false,
    // The server serves the rewarded unit for ad-funded quick analyses as
    // `analysis_unit_id`; the legacy `unit_id` is null once credit rewards are off.
    unitId: (json['analysis_unit_id'] as String?) ?? (json['unit_id'] as String?),
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 0,
    remainingToday: (json['remaining_today'] as num?)?.toInt(),
  );
}

/// Ad settings. The default (no ads) is what Pro users and failures get.
class AdsConfig {
  final bool enabled;
  final List<AdPlacement> placements;
  final RewardedConfig rewarded;

  const AdsConfig({
    this.enabled = false,
    this.placements = const [],
    this.rewarded = const RewardedConfig(),
  });

  static const none = AdsConfig();

  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    final list = json['placements'];
    final rewarded = json['rewarded'];
    return AdsConfig(
      enabled: json['enabled'] as bool? ?? false,
      placements: list is List
          ? [
              for (final p in list)
                if (p is Map<String, dynamic>) AdPlacement.fromJson(p),
            ]
          : const [],
      rewarded: rewarded is Map<String, dynamic>
          ? RewardedConfig.fromJson(rewarded)
          : const RewardedConfig(),
    );
  }

  AdPlacement? placement(String key) {
    for (final p in placements) {
      if (p.key == key) return p;
    }
    return null;
  }
}

class AppConfig {
  final PlanConfig plan;
  final AdsConfig ads;

  /// Free members may watch one rewarded ad instead of paying 2 credits for
  /// a quick analysis (never for deep analysis).
  final bool adAnalysisEnabled;
  final int adAnalysisDailyCap;

  const AppConfig({
    this.plan = PlanConfig.safeDefaults,
    this.ads = AdsConfig.none,
    this.adAnalysisEnabled = false,
    this.adAnalysisDailyCap = 0,
  });

  static const safeDefaults = AppConfig();

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final ads = json['ads'];
    return AppConfig(
      plan: plan is Map<String, dynamic>
          ? PlanConfig.fromJson(plan)
          : PlanConfig.safeDefaults,
      ads: ads is Map<String, dynamic>
          ? AdsConfig.fromJson(ads)
          : AdsConfig.none,
      adAnalysisEnabled: _lookup(json, 'ad_analysis_enabled') == true,
      adAnalysisDailyCap:
          (_lookup(json, 'ad_analysis_daily_cap') as num?)?.toInt() ?? 0,
    );
  }

  /// The contract puts the ad-analysis keys at the top level; tolerate them
  /// being nested in `ads` or `plan` too.
  static Object? _lookup(Map<String, dynamic> json, String key) {
    if (json[key] != null) return json[key];
    for (final group in ['ads', 'plan']) {
      final m = json[group];
      if (m is Map<String, dynamic> && m[key] != null) return m[key];
    }
    return null;
  }
}
