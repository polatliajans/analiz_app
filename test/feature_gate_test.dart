import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/utils/feature_gate.dart';

ChartSignal _s(int strength) => ChartSignal(
  candleTime: DateTime.utc(2026, 1, 1),
  signalType: 'buy',
  strength: strength,
);

void main() {
  const config = PlanConfig();

  group('Free / guest', () {
    const gate = FeatureGate(plan: config, isPro: false);

    test('deep analysis is locked when the config requires Pro', () {
      expect(gate.canUseDeepAnalysis, isFalse);
      expect(
        const FeatureGate(
          plan: PlanConfig(deepAnalysisRequiresPro: false),
          isPro: false,
        ).canUseDeepAnalysis,
        isTrue,
      );
    });

    test('only configured timeframes are locked', () {
      expect(gate.isTimeframeLocked('1m'), isTrue);
      expect(gate.isTimeframeLocked('5m'), isTrue);
      expect(gate.isTimeframeLocked('15m'), isFalse);
      expect(gate.isTimeframeLocked('1w'), isFalse);
    });

    test('only signals up to freeMaxSignalStrength are visible', () {
      final all = [_s(1), _s(2), _s(3), _s(2)];
      expect(gate.visibleSignals(all).map((s) => s.strength), [1, 2, 2]);
      expect(gate.isSignalVisible(3), isFalse);
      expect(gate.showStrongSignalsNote, isTrue);
      const tight = FeatureGate(
        plan: PlanConfig(freeMaxSignalStrength: 1),
        isPro: false,
      );
      expect(tight.visibleSignals(all).map((s) => s.strength), [1]);
      const open = FeatureGate(
        plan: PlanConfig(freeMaxSignalStrength: 3),
        isPro: false,
      );
      expect(open.visibleSignals(all), hasLength(4));
      expect(open.showStrongSignalsNote, isFalse);
    });

    test('watchlist limit', () {
      expect(gate.watchlistLimit, 10);
      expect(gate.watchlistLimitReached(9), isFalse);
      expect(gate.watchlistLimitReached(10), isTrue);
      expect(gate.watchlistLimitReached(14), isTrue);
      const unlimited = FeatureGate(
        plan: PlanConfig(freeWatchlistMax: null),
        isPro: false,
      );
      expect(unlimited.watchlistLimitReached(500), isFalse);
    });

    test('persisted choices are clamped to what is allowed', () {
      expect(gate.effectiveTimeframe('1m'), '15m');
      expect(gate.effectiveTimeframe('4h'), '4h');
    });
  });

  group('Pro', () {
    const gate = FeatureGate(plan: config, isPro: true);

    test('everything is open', () {
      expect(gate.canUseDeepAnalysis, isTrue);
      expect(gate.isTimeframeLocked('1m'), isFalse);
      final all = [_s(1), _s(2), _s(3)];
      expect(gate.visibleSignals(all), hasLength(3));
      expect(gate.showStrongSignalsNote, isFalse);
      expect(gate.watchlistLimit, isNull);
      expect(gate.watchlistLimitReached(999), isFalse);
      expect(gate.effectiveTimeframe('1m'), '1m');
    });
  });

  group('AppConfig.fromJson', () {
    test('parses the full server payload including ads', () {
      final c = AppConfig.fromJson({
        'plan': {
          'role': 'free',
          'free_watchlist_max': 7,
          'deep_analysis_requires_pro': false,
          'pro_only_timeframes': ['1m'],
          'free_max_signal_strength': 1,
          'alerts_require_pro': true,
        },
        'ads': {
          'enabled': true,
          'placements': [
            {
              'key': 'banner_radar',
              'type': 'banner',
              'unit_id': 'ca-app-pub-1/2',
              'frequency': null,
              'cooldown_minutes': null,
            },
            {
              'key': 'interstitial_analysis',
              'type': 'interstitial',
              'unit_id': 'x',
              'frequency': 3,
              'cooldown_minutes': 5,
            },
          ],
          'rewarded': {
            'enabled': true,
            'unit_id': 'r',
            'amount': 3,
            'daily_cap': 3,
            'remaining_today': 2,
          },
        },
      });
      expect(c.plan.role, 'free');
      expect(c.plan.freeWatchlistMax, 7);
      expect(c.plan.proOnlyTimeframes, ['1m']);
      expect(c.plan.freeMaxSignalStrength, 1);
      expect(c.ads.enabled, isTrue);
      expect(c.ads.placements, hasLength(2));
      expect(c.ads.placement('interstitial_analysis')!.frequency, 3);
      expect(c.ads.placement('interstitial_analysis')!.cooldownMinutes, 5);
      expect(c.ads.rewarded.remainingToday, 2);
    });

    test('null free_watchlist_max means unlimited', () {
      final c = AppConfig.fromJson({
        'plan': {'role': 'pro', 'free_watchlist_max': null},
      });
      expect(c.plan.freeWatchlistMax, isNull);
    });

    test('missing sections fall back to safe defaults', () {
      final c = AppConfig.fromJson({});
      expect(c.plan.deepAnalysisRequiresPro, isTrue);
      expect(c.plan.proOnlyTimeframes, ['1m', '5m']);
      expect(c.plan.freeWatchlistMax, 10);
      expect(c.plan.freeMaxSignalStrength, 2);
      expect(c.ads.enabled, isFalse);
      expect(c.ads.placements, isEmpty);
    });

    test('plan survives a toJson round trip', () {
      const original = PlanConfig(
        role: 'free',
        freeWatchlistMax: 4,
        proOnlyTimeframes: ['1m'],
        freeMaxSignalStrength: 1,
      );
      final back = PlanConfig.fromJson(original.toJson());
      expect(back.freeWatchlistMax, 4);
      expect(back.freeMaxSignalStrength, 1);
      expect(back.proOnlyTimeframes, ['1m']);
    });
  });
}
