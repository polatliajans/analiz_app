import '../models/app_config.dart';

/// Pure ad decisions (no SDK calls) so they can be unit tested.

enum AdFormat { banner, native, interstitial, rewarded }

enum RewardedOutcome { earned, dismissed, unavailable, failed }

/// Placement keys served by `GET /api/app-config`.
abstract final class AdPlacementKeys {
  static const bannerRadar = 'banner_radar';
  static const bannerWatchlist = 'banner_watchlist';
  static const bannerProfile = 'banner_profile';
  static const nativeRadar = 'native_radar';
  static const nativeCoinPicker = 'native_coin_picker';
  static const interstitialAnalysis = 'interstitial_analysis';

  static const all = [
    bannerRadar,
    bannerWatchlist,
    bannerProfile,
    nativeRadar,
    nativeCoinPicker,
    interstitialAnalysis,
  ];

  static String typeOf(String key) {
    if (key.startsWith('banner_')) return 'banner';
    if (key.startsWith('native_')) return 'native';
    return 'interstitial';
  }
}

const defaultNativeFrequency = 8;
const defaultInterstitialFrequency = 3;
const defaultInterstitialCooldownMinutes = 5;
const defaultRewardedAmount = 3;
const defaultRewardedDailyCap = 3;

/// Google's public test ad units (safe to click, never billed).
const testUnitIds = <AdFormat, String>{
  AdFormat.banner: 'ca-app-pub-3940256099942544/9214589741',
  AdFormat.interstitial: 'ca-app-pub-3940256099942544/1033173712',
  AdFormat.native: 'ca-app-pub-3940256099942544/2247696110',
  AdFormat.rewarded: 'ca-app-pub-3940256099942544/5224354917',
};

/// The server unit id when set; otherwise Google's test unit in debug builds
/// and null (= placement not shown) in release builds.
String? resolveUnitId(
  String? serverUnitId,
  AdFormat format, {
  required bool isDebug,
}) {
  final id = serverUnitId?.trim() ?? '';
  if (id.isNotEmpty) return id;
  return isDebug ? testUnitIds[format] : null;
}

/// Unit id for an enabled placement, or null when it must not be shown.
String? activeUnitId(
  AdsConfig ads,
  String key,
  AdFormat format, {
  required bool isDebug,
}) {
  if (!ads.enabled) return null;
  final placement = ads.placement(key);
  if (placement == null) return null;
  return resolveUnitId(placement.unitId, format, isDebug: isDebug);
}

int effectiveFrequency(int? configured, int fallback) =>
    configured == null || configured <= 0 ? fallback : configured;

int effectiveCooldownMinutes(int? configured) =>
    configured == null || configured < 0
    ? defaultInterstitialCooldownMinutes
    : configured;

/// In a list where an ad follows every [frequency] content rows, whether the
/// combined [index] is an ad slot.
bool shouldShowNativeAt(int index, int frequency) =>
    frequency > 0 && index >= 0 && (index + 1) % (frequency + 1) == 0;

/// Content row shown at combined [index] (must not be an ad slot).
int contentIndexAt(int index, int frequency) =>
    frequency > 0 ? index - (index + 1) ~/ (frequency + 1) : index;

/// Zero-based number of the ad at combined [index] (an ad slot).
int nativeSlotNumber(int index, int frequency) =>
    (index + 1) ~/ (frequency + 1) - 1;

/// How many distinct native ads a list cycles through so the same ad is
/// never laid out twice at once (about 25 rows are built at a time).
int nativePoolSizeFor(int frequency) =>
    frequency <= 0 ? 0 : 25 ~/ (frequency + 1) + 2;

/// Combined row count; no ad is placed after the last content row.
int itemCountWithAds(int contentCount, int frequency) {
  if (contentCount <= 0) return 0;
  if (frequency <= 0) return contentCount;
  return contentCount + (contentCount - 1) ~/ frequency;
}

/// Interstitial after every [frequency]-th successful analysis, and only if
/// at least [cooldownMinutes] passed since the last one was shown.
bool shouldShowInterstitial({
  required int analysisCount,
  required int frequency,
  required DateTime? lastShownAt,
  required DateTime now,
  required int cooldownMinutes,
}) {
  if (frequency <= 0 || analysisCount <= 0) return false;
  if (analysisCount % frequency != 0) return false;
  if (lastShownAt == null) return true;
  return now.difference(lastShownAt) >= Duration(minutes: cooldownMinutes);
}

/// Ads actually used by the app. Pro never sees ads. [forceTestAds] (debug
/// only) enables every placement with Google test units so ads can be checked
/// before AdMob units are configured on the server.
AdsConfig effectiveAdsConfig(
  AdsConfig server, {
  required bool isPro,
  required bool forceTestAds,
}) {
  if (isPro) return AdsConfig.none;
  if (!forceTestAds) return server;
  final r = server.rewarded;
  final cap = r.dailyCap > 0 ? r.dailyCap : defaultRewardedDailyCap;
  return AdsConfig(
    enabled: true,
    placements: [
      for (final key in AdPlacementKeys.all)
        server.placement(key) ??
            AdPlacement(key: key, type: AdPlacementKeys.typeOf(key)),
    ],
    rewarded: RewardedConfig(
      enabled: true,
      unitId: r.unitId,
      amount: r.amount > 0 ? r.amount : defaultRewardedAmount,
      dailyCap: cap,
      remainingToday: r.remainingToday ?? cap,
    ),
  );
}
