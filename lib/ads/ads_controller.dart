import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/app_config.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/price_alert_provider.dart';
import 'ad_analysis_flow.dart';
import 'ad_counters.dart';
import 'ad_logic.dart';

/// Debug-only switch (`--dart-define=ADS_FORCE_TEST=true`): shows every
/// placement with Google test units even if the server has no units yet.
const _forceTestAdsDefine = bool.fromEnvironment('ADS_FORCE_TEST');
bool get forceTestAds => kDebugMode && _forceTestAdsDefine;

/// Ads the app may show for the current user (Pro: none).
final effectiveAdsConfigProvider = Provider<AdsConfig>(
  (ref) => effectiveAdsConfig(
    ref.watch(appConfigProvider.select((c) => c.ads)),
    isPro: ref.watch(isProProvider),
    forceTestAds: forceTestAds,
  ),
);

/// Free, signed-in member and the server offers ad-funded quick analysis:
/// the SDK (consent + init) and a rewarded ad are needed even when the
/// banner/interstitial ads are switched off.
final adAnalysisWantedProvider = Provider<bool>(
  (ref) =>
      ref.watch(authProvider.select((s) => s.isLoggedIn)) &&
      !ref.watch(isProProvider) &&
      ref.watch(appConfigProvider.select((c) => c.adAnalysisEnabled)),
);

final adCountersProvider = Provider<AdCounters>(
  (ref) => AdCounters(ref.watch(sharedPreferencesProvider)),
);

class AdsState {
  /// Consent flow finished with permission to request ads and the SDK is
  /// initialized, while ads are enabled for this user.
  final bool sdkReady;

  /// A rewarded ad is loaded and can be shown right away.
  final bool rewardedLoaded;

  const AdsState({this.sdkReady = false, this.rewardedLoaded = false});

  AdsState copyWith({bool? sdkReady, bool? rewardedLoaded}) => AdsState(
    sdkReady: sdkReady ?? this.sdkReady,
    rewardedLoaded: rewardedLoaded ?? this.rewardedLoaded,
  );
}

/// Owns the ad SDK lifecycle: UMP consent, `MobileAds.initialize`, and the
/// full-screen (interstitial / rewarded) ads. Banner and native widgets load
/// their own ads only while [adsReadyProvider] is true.
class AdsController extends Notifier<AdsState> {
  static Future<bool>? _consentAndInit;

  InterstitialAd? _interstitial;
  bool _interstitialLoading = false;
  RewardedAd? _rewarded;
  bool _rewardedLoading = false;
  bool _showingFullScreen = false;

  AdsConfig get _config => ref.read(effectiveAdsConfigProvider);

  @override
  AdsState build() {
    ref.listen(effectiveAdsConfigProvider, (_, next) => _onConfig(next));
    ref.listen(
      adAnalysisWantedProvider,
      (_, _) => _onConfig(ref.read(effectiveAdsConfigProvider)),
    );
    ref.listen(authProvider.select((s) => s.member?.id), (_, id) {
      // A rewarded ad is tied to the signed-in member: drop it on sign-out.
      _rewarded?.dispose();
      _rewarded = null;
      if (state.rewardedLoaded) state = state.copyWith(rewardedLoaded: false);
      if (id != null) _loadRewarded();
    });
    ref.onDispose(_disposeFullScreenAds);
    Future.microtask(() => _onConfig(ref.read(effectiveAdsConfigProvider)));
    return const AdsState();
  }

  Future<void> _onConfig(AdsConfig config) async {
    if (!config.enabled && !_adAnalysisWanted) {
      _disposeFullScreenAds();
      state = const AdsState();
      return;
    }
    final ok = await (_consentAndInit ??= _obtainConsentAndInitialize());
    // Config may have changed (e.g. upgraded to Pro) while consent ran.
    if (!ok || !ref.mounted) return;
    if (!ref.read(effectiveAdsConfigProvider).enabled && !_adAnalysisWanted) {
      return;
    }
    if (!state.sdkReady) state = state.copyWith(sdkReady: true);
    _loadInterstitial();
    _loadRewarded();
  }

  /// UMP consent (form shown only when required), then SDK init. Ads are
  /// requested only if `canRequestAds()` allows it.
  static Future<bool> _obtainConsentAndInitialize() async {
    try {
      final done = Completer<void>();
      void finish([Object? _]) {
        if (!done.isCompleted) done.complete();
      }

      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired(finish),
        finish,
      );
      await done.future;
      if (!await ConsentInformation.instance.canRequestAds()) {
        _consentAndInit = null; // ask again on the next launch/config change
        return false;
      }
      await MobileAds.instance.initialize();
      return true;
    } catch (_) {
      _consentAndInit = null;
      return false;
    }
  }

  /// Pro upgrade, ads switched off or provider disposed.
  void _disposeFullScreenAds() {
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
  }

  // ---------------------------------------------------------------- interstitial

  String? get _interstitialUnit => activeUnitId(
    _config,
    AdPlacementKeys.interstitialAnalysis,
    AdFormat.interstitial,
    isDebug: kDebugMode,
  );

  void _loadInterstitial() {
    final unit = _interstitialUnit;
    if (!state.sdkReady || unit == null) return;
    if (_interstitial != null || _interstitialLoading) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          if (!state.sdkReady) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) => _interstitialLoading = false,
      ),
    );
  }

  /// Call once per successful (quick or deep) analysis.
  Future<void> recordSuccessfulAnalysis() async {
    if (ref.read(isProProvider)) return;
    await ref.read(adCountersProvider).incrementAnalysisCount();
  }

  /// Call after the user closed the analysis result. Shows an interstitial
  /// on every N-th analysis when the cooldown has passed.
  Future<void> maybeShowInterstitial() async {
    if (!state.sdkReady || _showingFullScreen) return;
    final placement = _config.placement(AdPlacementKeys.interstitialAnalysis);
    if (placement == null || _interstitialUnit == null) return;
    final counters = ref.read(adCountersProvider);
    final show = shouldShowInterstitial(
      analysisCount: counters.analysisCount,
      frequency: effectiveFrequency(
        placement.frequency,
        defaultInterstitialFrequency,
      ),
      lastShownAt: counters.lastInterstitialAt,
      now: DateTime.now(),
      cooldownMinutes: effectiveCooldownMinutes(placement.cooldownMinutes),
    );
    if (!show) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _showingFullScreen = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) =>
          counters.setLastInterstitialAt(DateTime.now()),
      onAdDismissedFullScreenContent: (a) {
        _showingFullScreen = false;
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        _showingFullScreen = false;
        a.dispose();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      _showingFullScreen = false;
      ad.dispose();
    }
  }

  // -------------------------------------------------------------------- rewarded

  bool get _adAnalysisWanted => ref.read(adAnalysisWantedProvider);

  void _loadRewarded() {
    if (!state.sdkReady || !_adAnalysisWanted) return;
    if (_rewarded != null || _rewardedLoading) return;
    final unit = resolveUnitId(
      _config.rewarded.unitId,
      AdFormat.rewarded,
      isDebug: kDebugMode,
    );
    if (unit == null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          if (!state.sdkReady) {
            ad.dispose();
            return;
          }
          _rewarded = ad;
          state = state.copyWith(rewardedLoaded: true);
        },
        onAdFailedToLoad: (_) => _rewardedLoading = false,
      ),
    );
  }

  /// Retries loading a rewarded ad.
  void preloadRewarded() => _loadRewarded();

  /// Runs consent / SDK init if still pending, loads a rewarded ad and waits
  /// (up to [timeout]) until one is ready. False when ads cannot be shown.
  Future<bool> prepareRewarded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_adAnalysisWanted) return false;
    if (!state.sdkReady) await _onConfig(ref.read(effectiveAdsConfigProvider));
    if (!ref.mounted || !state.sdkReady) return false;
    _loadRewarded();
    final deadline = DateTime.now().add(timeout);
    while (ref.mounted && !state.rewardedLoaded) {
      if (DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!state.rewardedLoaded) _loadRewarded();
    }
    return ref.mounted && state.rewardedLoaded;
  }

  /// Shows the rewarded ad. AdMob server-side verification carries the
  /// member id as `user_id` and [customData] (the ad-analysis session id) as
  /// `custom_data`; the server marks the session verified from that callback.
  Future<RewardedOutcome> showRewarded({String? customData}) async {
    final ad = _rewarded;
    final member = ref.read(authProvider).member;
    if (ad == null || member == null || _showingFullScreen) {
      _loadRewarded();
      return RewardedOutcome.unavailable;
    }
    _rewarded = null;
    state = state.copyWith(rewardedLoaded: false);
    _showingFullScreen = true;
    final result = Completer<RewardedOutcome>();
    var earned = false;
    void finish(RewardedOutcome outcome, Ad a) {
      _showingFullScreen = false;
      a.dispose();
      if (!result.isCompleted) result.complete(outcome);
      _loadRewarded();
    }

    try {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: '${member.id}',
          customData: customData,
        ),
      );
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) => finish(
          earned ? RewardedOutcome.earned : RewardedOutcome.dismissed,
          a,
        ),
        onAdFailedToShowFullScreenContent: (a, _) =>
            finish(RewardedOutcome.failed, a),
      );
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
    } catch (_) {
      finish(RewardedOutcome.failed, ad);
    }
    return result.future;
  }
}

/// Bridges [AdsController] to the ad-analysis flow.
class AdsControllerAdService implements AdAnalysisAdService {
  final AdsController controller;
  AdsControllerAdService(this.controller);

  @override
  Future<bool> prepare() => controller.prepareRewarded();

  @override
  Future<RewardedOutcome> show(String sessionId) =>
      controller.showRewarded(customData: sessionId);
}

final adsControllerProvider = NotifierProvider<AdsController, AdsState>(
  AdsController.new,
);

/// True when banner/native ads may be requested right now.
final adsReadyProvider = Provider<bool>(
  (ref) =>
      ref.watch(effectiveAdsConfigProvider).enabled &&
      ref.watch(adsControllerProvider.select((s) => s.sdkReady)),
);
