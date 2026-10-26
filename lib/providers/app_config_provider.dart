import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_config_api.dart';
import '../models/app_config.dart';
import '../utils/feature_gate.dart';
import 'auth_provider.dart';
import 'locale_provider.dart';
import 'price_alert_provider.dart';

const appConfigCacheKey = 'app_config_plan_cache';

final appConfigApiProvider = Provider<AppConfigApi>((ref) => AppConfigApi());

/// Plan limits and ad settings from `GET /api/app-config`.
///
/// Starts from the last successfully fetched plan (or safe defaults) and never
/// shows ads until a fresh response says so. Refetched whenever the session
/// or the member's role changes; failures keep the current value.
class AppConfigNotifier extends Notifier<AppConfig> {
  int _generation = 0;

  @override
  AppConfig build() {
    ref.listen(
      authProvider.select((s) => (s.token, s.member?.role)),
      (_, _) => refresh(),
    );
    // The ads tier depends on whether the member holds purchased credits, so
    // re-fetch when the balance changes (purchase or analysis consumption).
    ref.listen(authProvider.select((s) => s.member?.creditBalance), (prev, _) {
      if (prev != null) refresh();
    });
    Future.microtask(refresh);
    return AppConfig(plan: _readCachedPlan());
  }

  PlanConfig _readCachedPlan() {
    try {
      final raw = ref
          .read(sharedPreferencesProvider)
          .getString(appConfigCacheKey);
      if (raw == null) return PlanConfig.safeDefaults;
      return PlanConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlanConfig.safeDefaults;
    }
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final token = ref.read(authProvider).token;
    try {
      final config = await ref.read(appConfigApiProvider).fetch(token: token);
      // A newer refresh (e.g. after sign-in) supersedes this response.
      if (generation != _generation) return;
      state = config;
      await ref
          .read(sharedPreferencesProvider)
          .setString(appConfigCacheKey, jsonEncode(config.plan.toJson()));
    } catch (_) {
      // Offline or server error: keep the cached/default values.
    }
  }
}

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);

/// Feature decisions for the current user (Pro or not) and plan config.
final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(
    plan: ref.watch(appConfigProvider.select((c) => c.plan)),
    isPro: ref.watch(isProProvider),
  ),
);
