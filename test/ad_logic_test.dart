import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ad_counters.dart';
import 'package:kriptoanaliz/ads/ad_logic.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('native placement in lists', () {
    test('an ad follows every N content rows', () {
      final slots = [for (var i = 0; i < 20; i++) shouldShowNativeAt(i, 8)];
      expect(
        [
          for (var i = 0; i < 20; i++)
            if (slots[i]) i,
        ],
        [8, 17],
      );
    });

    test('frequency <= 0 never shows ads', () {
      expect(shouldShowNativeAt(0, 0), isFalse);
      expect(shouldShowNativeAt(8, -1), isFalse);
      expect(itemCountWithAds(30, 0), 30);
      expect(contentIndexAt(12, 0), 12);
    });

    test('content indexes skip the ad slots', () {
      expect(contentIndexAt(7, 8), 7);
      expect(contentIndexAt(9, 8), 8);
      expect(contentIndexAt(16, 8), 15);
      expect(contentIndexAt(18, 8), 16);
    });

    test('no trailing ad after the last content row', () {
      expect(itemCountWithAds(0, 8), 0);
      expect(itemCountWithAds(5, 8), 5);
      expect(itemCountWithAds(8, 8), 8);
      expect(itemCountWithAds(9, 8), 10);
      expect(itemCountWithAds(17, 8), 19);
      // Every content row maps to a distinct, in-range index.
      const count = 40;
      final total = itemCountWithAds(count, 8);
      final contents = [
        for (var i = 0; i < total; i++)
          if (!shouldShowNativeAt(i, 8)) contentIndexAt(i, 8),
      ];
      expect(contents, List.generate(count, (i) => i));
      expect(shouldShowNativeAt(total - 1, 8), isFalse);
    });

    test('pool is large enough that one ad is never on screen twice', () {
      expect(nativePoolSizeFor(8), 4);
      expect(nativePoolSizeFor(0), 0);
      for (final n in [1, 2, 3, 5, 8, 12, 30]) {
        // Rows between two uses of the same ad.
        expect(nativePoolSizeFor(n) * (n + 1), greaterThan(25), reason: '$n');
      }
    });

    test('ad slot number counts ads from zero', () {
      expect(nativeSlotNumber(8, 8), 0);
      expect(nativeSlotNumber(17, 8), 1);
      expect(nativeSlotNumber(26, 8), 2);
    });
  });

  group('radar native frequency (server honored)', () {
    test('server value used exactly, floor of 2, default 10', () {
      expect(nativeFrequencyFor(5), 5);
      expect(nativeFrequencyFor(3), 3);
      expect(nativeFrequencyFor(2), 2);
      expect(nativeFrequencyFor(25), 25);
      expect(nativeFrequencyFor(1), minNativeFrequency);
      expect(nativeFrequencyFor(null), defaultNativeFrequency);
      expect(nativeFrequencyFor(0), defaultNativeFrequency);
      expect(nativeFrequencyFor(-4), defaultNativeFrequency);
    });

    test('frequency 5 puts an ad after every 5th content row', () {
      final f = nativeFrequencyFor(5);
      final slots = [
        for (var i = 0; i < 18; i++)
          if (shouldShowNativeAt(i, f)) i,
      ];
      expect(slots, [5, 11, 17]);
      expect(itemCountWithAds(10, f), 11);
      expect(nativePoolSizeFor(f), greaterThan(2));
    });

    test('native_home is a native placement served to everyone but Pro', () {
      expect(AdPlacementKeys.typeOf(AdPlacementKeys.nativeHome), 'native');
      expect(AdPlacementKeys.all, contains(AdPlacementKeys.nativeHome));
      const ads = AdsConfig(
        enabled: true,
        reduced: true,
        placements: [
          AdPlacement(key: 'native_home', type: 'native', unitId: 'nh'),
        ],
      );
      final reduced = effectiveAdsConfig(
        ads,
        isPro: false,
        forceTestAds: false,
      );
      expect(
        activeUnitId(
          reduced,
          AdPlacementKeys.nativeHome,
          AdFormat.native,
          isDebug: false,
        ),
        'nh',
      );
      final pro = effectiveAdsConfig(ads, isPro: true, forceTestAds: false);
      expect(
        activeUnitId(
          pro,
          AdPlacementKeys.nativeHome,
          AdFormat.native,
          isDebug: true,
        ),
        isNull,
      );
      // Missing / disabled placement: no unit, so the slot collapses.
      expect(
        activeUnitId(
          const AdsConfig(enabled: true),
          AdPlacementKeys.nativeHome,
          AdFormat.native,
          isDebug: false,
        ),
        isNull,
      );
    });
  });

  group('navigation interstitial decision', () {
    final start = DateTime(2026, 10, 17, 12);
    final now = start.add(const Duration(minutes: 30));

    bool show({
      int visits = 4,
      int frequency = 4,
      DateTime? last,
      DateTime? at,
      int cooldown = 5,
      int today = 0,
      int? cap = 6,
      DateTime? started,
    }) => shouldShowNavigationInterstitial(
      visitCount: visits,
      frequency: frequency,
      lastShownAt: last,
      now: at ?? now,
      cooldownMinutes: cooldown,
      shownToday: today,
      dailyCap: cap,
      appStartedAt: started ?? start,
    );

    test('every N-th visit only', () {
      expect(show(visits: 4), isTrue);
      expect(show(visits: 8), isTrue);
      expect(show(visits: 1), isFalse);
      expect(show(visits: 3), isFalse);
      expect(show(visits: 5), isFalse);
      expect(show(visits: 0), isFalse);
      expect(show(frequency: 0), isFalse);
    });

    test('cooldown is shared with any interstitial', () {
      expect(show(last: now.subtract(const Duration(minutes: 4))), isFalse);
      expect(show(last: now.subtract(const Duration(minutes: 5))), isTrue);
      expect(show(last: now.subtract(const Duration(hours: 2))), isTrue);
    });

    test('daily cap', () {
      expect(show(today: 5), isTrue);
      expect(show(today: 6), isFalse);
      expect(show(today: 99, cap: null), isTrue);
      expect(show(today: 0, cap: 0), isFalse);
    });

    test('never in the first 60 seconds after launch', () {
      expect(show(at: start.add(const Duration(seconds: 59))), isFalse);
      expect(show(at: start.add(const Duration(seconds: 60))), isTrue);
    });

    test('defaults and daily cap parsing', () {
      expect(defaultNavigationFrequency, 4);
      final absent = AdPlacement.fromJson(const {
        'key': 'interstitial_navigation',
        'type': 'interstitial',
      });
      expect(navigationDailyCap(absent), 6);
      final unlimited = AdPlacement.fromJson(const {
        'key': 'interstitial_navigation',
        'type': 'interstitial',
        'daily_cap': null,
      });
      expect(navigationDailyCap(unlimited), isNull);
      final ten = AdPlacement.fromJson(const {
        'key': 'interstitial_navigation',
        'type': 'interstitial',
        'daily_cap': 10,
        'frequency': 2,
      });
      expect(navigationDailyCap(ten), 10);
      expect(ten.frequency, 2);
    });

    test('Pro and missing unit id yield no placement to show', () {
      const ads = AdsConfig(
        enabled: true,
        placements: [
          AdPlacement(key: 'interstitial_navigation', type: 'interstitial'),
        ],
      );
      expect(
        activeUnitId(
          effectiveAdsConfig(ads, isPro: false, forceTestAds: false),
          AdPlacementKeys.interstitialNavigation,
          AdFormat.interstitial,
          isDebug: false,
        ),
        isNull,
      );
      expect(
        effectiveAdsConfig(
          ads,
          isPro: true,
          forceTestAds: false,
        ).placement(AdPlacementKeys.interstitialNavigation),
        isNull,
      );
    });

    test(
      'counters persist visits and reset the daily count on a new day',
      () async {
        SharedPreferences.setMockInitialValues({});
        final c = AdCounters(await SharedPreferences.getInstance());
        expect(await c.incrementChartVisits(), 1);
        expect(await c.incrementChartVisits(), 2);
        final d1 = DateTime(2026, 10, 17, 23, 59);
        expect(c.navigationShownToday(d1), 0);
        await c.recordNavigationShown(d1);
        await c.recordNavigationShown(d1);
        expect(c.navigationShownToday(d1), 2);
        expect(c.lastInterstitialAt, d1);
        final d2 = DateTime(2026, 10, 18, 0, 1);
        expect(c.navigationShownToday(d2), 0);
        await c.recordNavigationShown(d2);
        expect(c.navigationShownToday(d2), 1);
        expect(c.chartVisitCount, 2);
      },
    );
  });

  group('frequency defaults', () {
    test('missing or non-positive values fall back', () {
      expect(effectiveFrequency(null, defaultNativeFrequency), 10);
      expect(effectiveFrequency(0, defaultInterstitialFrequency), 3);
      expect(effectiveFrequency(-2, 3), 3);
      expect(effectiveFrequency(5, 3), 5);
    });

    test('cooldown defaults to 5 minutes; 0 is allowed', () {
      expect(effectiveCooldownMinutes(null), 5);
      expect(effectiveCooldownMinutes(-1), 5);
      expect(effectiveCooldownMinutes(0), 0);
      expect(effectiveCooldownMinutes(12), 12);
    });
  });

  group('interstitial decision', () {
    final now = DateTime(2026, 10, 17, 12);

    bool decide(int count, {DateTime? last, int cooldown = 5, int n = 3}) =>
        shouldShowInterstitial(
          analysisCount: count,
          frequency: n,
          lastShownAt: last,
          now: now,
          cooldownMinutes: cooldown,
        );

    test('only every N-th analysis', () {
      expect(decide(1), isFalse);
      expect(decide(2), isFalse);
      expect(decide(3), isTrue);
      expect(decide(4), isFalse);
      expect(decide(6), isTrue);
      expect(decide(0), isFalse);
    });

    test('cooldown since the last shown interstitial', () {
      expect(
        decide(3, last: now.subtract(const Duration(minutes: 4))),
        isFalse,
      );
      expect(decide(3, last: now.subtract(const Duration(minutes: 5))), isTrue);
      expect(decide(3, last: now.subtract(const Duration(hours: 2))), isTrue);
      expect(decide(3, last: now, cooldown: 0), isTrue);
    });

    test('the first analysis of a session is not special', () {
      // N = 1 shows after the very first analysis when no cooldown blocks it.
      expect(decide(1, n: 1), isTrue);
    });

    test('invalid frequency never shows', () {
      expect(decide(3, n: 0), isFalse);
    });
  });

  group('unit ids', () {
    test('server id wins in every build', () {
      expect(
        resolveUnitId('ca-app-pub-1/2', AdFormat.banner, isDebug: false),
        'ca-app-pub-1/2',
      );
      expect(
        resolveUnitId('ca-app-pub-1/2', AdFormat.banner, isDebug: true),
        'ca-app-pub-1/2',
      );
    });

    test('debug falls back to Google test units, release hides', () {
      expect(
        resolveUnitId('', AdFormat.banner, isDebug: true),
        'ca-app-pub-3940256099942544/9214589741',
      );
      expect(
        resolveUnitId(null, AdFormat.interstitial, isDebug: true),
        'ca-app-pub-3940256099942544/1033173712',
      );
      expect(
        resolveUnitId(' ', AdFormat.native, isDebug: true),
        'ca-app-pub-3940256099942544/2247696110',
      );
      expect(
        resolveUnitId(null, AdFormat.rewarded, isDebug: true),
        'ca-app-pub-3940256099942544/5224354917',
      );
      expect(resolveUnitId(null, AdFormat.banner, isDebug: false), isNull);
      expect(resolveUnitId('', AdFormat.rewarded, isDebug: false), isNull);
    });

    test('placement must exist and ads be enabled', () {
      const ads = AdsConfig(
        enabled: true,
        placements: [
          AdPlacement(key: 'banner_radar', type: 'banner', unitId: 'u1'),
          AdPlacement(key: 'banner_watchlist', type: 'banner'),
        ],
      );
      expect(
        activeUnitId(
          ads,
          AdPlacementKeys.bannerRadar,
          AdFormat.banner,
          isDebug: false,
        ),
        'u1',
      );
      expect(
        activeUnitId(
          ads,
          AdPlacementKeys.bannerWatchlist,
          AdFormat.banner,
          isDebug: false,
        ),
        isNull,
      );
      expect(
        activeUnitId(
          ads,
          AdPlacementKeys.nativeRadar,
          AdFormat.native,
          isDebug: true,
        ),
        isNull,
      );
      expect(
        activeUnitId(
          const AdsConfig(
            placements: [
              AdPlacement(key: 'banner_radar', type: 'banner', unitId: 'u1'),
            ],
          ),
          AdPlacementKeys.bannerRadar,
          AdFormat.banner,
          isDebug: true,
        ),
        isNull,
      );
    });
  });

  group('effective ads config', () {
    const server = AdsConfig(
      enabled: true,
      placements: [
        AdPlacement(key: 'native_radar', type: 'native', frequency: 6),
      ],
      rewarded: RewardedConfig(enabled: true, unitId: 'rw'),
    );

    test('Pro never gets ads, even in forced test mode', () {
      expect(
        effectiveAdsConfig(server, isPro: true, forceTestAds: true).enabled,
        isFalse,
      );
    });

    test('server config is used as is without forcing', () {
      expect(
        identical(
          effectiveAdsConfig(server, isPro: false, forceTestAds: false),
          server,
        ),
        isTrue,
      );
    });

    test('forced test mode enables every placement, keeps server values', () {
      final c = effectiveAdsConfig(
        AdsConfig.none,
        isPro: false,
        forceTestAds: true,
      );
      expect(c.enabled, isTrue);
      for (final key in AdPlacementKeys.all) {
        expect(c.placement(key), isNotNull, reason: key);
      }

      final kept = effectiveAdsConfig(server, isPro: false, forceTestAds: true);
      expect(kept.placement('native_radar')!.frequency, 6);
      expect(kept.rewarded.unitId, 'rw');
    });

    group('reduced ads tier', () {
      const reducedServer = AdsConfig(
        enabled: true,
        reduced: true,
        placements: [
          AdPlacement(key: 'banner_radar', type: 'banner', unitId: 'b'),
          AdPlacement(key: 'native_radar', type: 'native', unitId: 'n'),
          AdPlacement(
            key: 'interstitial_analysis',
            type: 'interstitial',
            unitId: 'i',
          ),
          AdPlacement(
            key: 'interstitial_navigation',
            type: 'interstitial',
            unitId: 'nav',
          ),
        ],
      );

      test('reduced keeps navigation interstitial, drops only analysis', () {
        final c = effectiveAdsConfig(
          reducedServer,
          isPro: false,
          forceTestAds: false,
        );
        expect(
          activeUnitId(
            c,
            AdPlacementKeys.interstitialNavigation,
            AdFormat.interstitial,
            isDebug: false,
          ),
          'nav',
        );
        expect(c.placement(AdPlacementKeys.interstitialAnalysis), isNull);
      });

      test('reduced drops interstitials, keeps banner and native', () {
        final c = effectiveAdsConfig(
          reducedServer,
          isPro: false,
          forceTestAds: false,
        );
        expect(c.enabled, isTrue);
        expect(c.placement(AdPlacementKeys.interstitialAnalysis), isNull);
        expect(c.placement(AdPlacementKeys.bannerRadar), isNotNull);
        expect(c.placement(AdPlacementKeys.nativeRadar), isNotNull);
        expect(
          activeUnitId(
            c,
            AdPlacementKeys.interstitialAnalysis,
            AdFormat.interstitial,
            isDebug: true,
          ),
          isNull,
        );
      });

      test('reduced also holds in forced test mode', () {
        final c = effectiveAdsConfig(
          reducedServer,
          isPro: false,
          forceTestAds: true,
        );
        expect(c.placement(AdPlacementKeys.interstitialAnalysis), isNull);
        expect(c.placement(AdPlacementKeys.bannerRadar), isNotNull);
      });

      test('not reduced keeps the interstitial', () {
        final full = AdsConfig(
          enabled: true,
          placements: reducedServer.placements,
        );
        final c = effectiveAdsConfig(full, isPro: false, forceTestAds: false);
        expect(identical(c, full), isTrue);
        expect(c.placement(AdPlacementKeys.interstitialAnalysis), isNotNull);
      });

      test('Pro stays ad-free even when reduced', () {
        expect(
          effectiveAdsConfig(
            reducedServer,
            isPro: true,
            forceTestAds: false,
          ).enabled,
          isFalse,
        );
      });

      test('reduced parses from JSON and defaults to false', () {
        expect(
          AppConfig.fromJson(const {
            'ads': {'enabled': true, 'reduced': true},
          }).ads.reduced,
          isTrue,
        );
        expect(
          AppConfig.fromJson(const {
            'ads': {'enabled': true},
          }).ads.reduced,
          isFalse,
        );
        expect(AppConfig.fromJson(const {}).ads.reduced, isFalse);
        expect(
          AppConfig.fromJson(const {
            'ads': {'reduced': 'yes'},
          }).ads.reduced,
          isFalse,
        );
      });
    });
  });

  group('parsing defaults', () {
    test('missing ads block means no ads', () {
      final c = AppConfig.fromJson(const {});
      expect(c.ads.enabled, isFalse);
      expect(c.ads.placements, isEmpty);
      expect(c.ads.rewarded.enabled, isFalse);
    });

    test('placement without frequency/cooldown uses defaults', () {
      final c = AppConfig.fromJson(const {
        'ads': {
          'enabled': true,
          'placements': [
            {
              'key': 'interstitial_analysis',
              'type': 'interstitial',
              'unit_id': 'x',
              'frequency': null,
              'cooldown_minutes': null,
            },
          ],
          'rewarded': {
            'enabled': true,
            'unit_id': null,
            'amount': 3,
            'daily_cap': 3,
            'remaining_today': 2,
          },
        },
      });
      final p = c.ads.placement(AdPlacementKeys.interstitialAnalysis)!;
      expect(effectiveFrequency(p.frequency, defaultInterstitialFrequency), 3);
      expect(effectiveCooldownMinutes(p.cooldownMinutes), 5);
      expect(c.ads.rewarded.unitId, isNull);
    });
  });

  group('persistent counters', () {
    test(
      'analysis count and last interstitial time survive restarts',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final counters = AdCounters(prefs);
        expect(counters.analysisCount, 0);
        expect(counters.lastInterstitialAt, isNull);

        expect(await counters.incrementAnalysisCount(), 1);
        expect(await counters.incrementAnalysisCount(), 2);
        final t = DateTime(2026, 10, 17, 9, 30);
        await counters.setLastInterstitialAt(t);

        final again = AdCounters(prefs);
        expect(again.analysisCount, 2);
        expect(again.lastInterstitialAt, t);
      },
    );
  });
}
