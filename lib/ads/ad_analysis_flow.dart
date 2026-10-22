import '../data/ad_analysis_api.dart';
import '../models/ai_analysis_result.dart';
import 'ad_logic.dart';

/// The rewarded-ad side of the flow (consent, loading, showing). Backed by
/// the real ads controller in the app, a fake in tests.
abstract class AdAnalysisAdService {
  /// Makes sure a rewarded ad is loaded (running consent / SDK init when
  /// needed). False when ads cannot be shown right now.
  Future<bool> prepare();

  /// Shows the ad; [sessionId] is passed to AdMob as SSV `custom_data`.
  Future<RewardedOutcome> show(String sessionId);
}

enum AdFlowPhase { preparing, creatingSession, showingAd, verifying, analyzing }

enum AdFlowOutcome {
  /// The analysis ran; see [AdFlowResult.analysis].
  success,

  /// The ad was closed before the reward: nothing to tell the user.
  cancelled,

  /// No ad could be loaded / shown (or consent is unavailable).
  adUnavailable,

  /// The server did not confirm the reward in time.
  verificationTimeout,
  capReached,

  /// The member has credit now: run the normal credit analysis instead.
  hasCredit,
  notFree,
  disabled,
  emailUnverified,
  sessionExpired,

  /// Anything else; see [AdFlowResult.error].
  failed,
}

class AdFlowResult {
  final AdFlowOutcome outcome;
  final AiAnalysisResult? analysis;
  final Object? error;

  const AdFlowResult(this.outcome, {this.analysis, this.error});

  bool get isSuccess => outcome == AdFlowOutcome.success;
}

/// "Watch one rewarded ad, get one quick analysis": ad -> server-side
/// verification -> quick analysis with `ad_session_id` (0 credits).
class AdAnalysisFlow {
  final AdAnalysisApi api;
  final AdAnalysisAdService ads;
  final String token;

  /// Runs the quick analysis request with the given ad session id.
  final Future<AiAnalysisResult> Function(String sessionId) analyze;

  final void Function(AdFlowPhase phase)? onPhase;
  final Future<void> Function(Duration) delay;
  final Duration pollInterval;
  final int maxPolls;
  final int maxNotVerifiedRetries;

  AdAnalysisFlow({
    required this.api,
    required this.ads,
    required this.token,
    required this.analyze,
    this.onPhase,
    this.delay = _defaultDelay,
    this.pollInterval = const Duration(seconds: 1),
    this.maxPolls = 15,
    this.maxNotVerifiedRetries = 4,
  });

  static Future<void> _defaultDelay(Duration d) => Future<void>.delayed(d);

  Future<AdFlowResult> run() async {
    onPhase?.call(AdFlowPhase.preparing);
    final ready = await _safe(ads.prepare);
    if (ready != true) return const AdFlowResult(AdFlowOutcome.adUnavailable);

    onPhase?.call(AdFlowPhase.creatingSession);
    final AdAnalysisSession session;
    try {
      session = await api.createSession(token);
    } on AdAnalysisException catch (e) {
      return _mapError(e);
    } catch (e) {
      return AdFlowResult(AdFlowOutcome.failed, error: e);
    }

    onPhase?.call(AdFlowPhase.showingAd);
    final RewardedOutcome shown;
    try {
      shown = await ads.show(session.id);
    } catch (_) {
      return const AdFlowResult(AdFlowOutcome.adUnavailable);
    }
    switch (shown) {
      case RewardedOutcome.dismissed:
        return const AdFlowResult(AdFlowOutcome.cancelled);
      case RewardedOutcome.unavailable:
      case RewardedOutcome.failed:
        return const AdFlowResult(AdFlowOutcome.adUnavailable);
      case RewardedOutcome.earned:
        break;
    }

    onPhase?.call(AdFlowPhase.verifying);
    final verified = await _awaitVerification(session.id);
    if (verified != null) return verified;

    onPhase?.call(AdFlowPhase.analyzing);
    for (var attempt = 0; attempt <= maxNotVerifiedRetries; attempt++) {
      try {
        final analysis = await analyze(session.id);
        return AdFlowResult(AdFlowOutcome.success, analysis: analysis);
      } on AdAnalysisException catch (e) {
        if (e.error == AdAnalysisError.notVerified) {
          if (attempt < maxNotVerifiedRetries) await delay(pollInterval);
          continue;
        }
        return _mapError(e);
      } catch (e) {
        return AdFlowResult(AdFlowOutcome.failed, error: e);
      }
    }
    return const AdFlowResult(AdFlowOutcome.verificationTimeout);
  }

  /// Polls until the server marks the reward verified. Null = verified
  /// (continue); otherwise the final result to return.
  Future<AdFlowResult?> _awaitVerification(String sessionId) async {
    for (var i = 0; i < maxPolls; i++) {
      try {
        final s = await api.fetchSession(token, sessionId);
        if (s.verified && !s.expired && !s.used) return null;
        if (s.expired || s.used) {
          return const AdFlowResult(AdFlowOutcome.sessionExpired);
        }
      } on AdAnalysisException catch (e) {
        if (e.error != AdAnalysisError.unknown) return _mapError(e);
      } catch (_) {
        // Transient network error: keep polling.
      }
      await delay(pollInterval);
    }
    return const AdFlowResult(AdFlowOutcome.verificationTimeout);
  }

  Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  AdFlowResult _mapError(AdAnalysisException e) {
    final outcome = switch (e.error) {
      AdAnalysisError.notFree => AdFlowOutcome.notFree,
      AdAnalysisError.disabled => AdFlowOutcome.disabled,
      AdAnalysisError.hasCredit => AdFlowOutcome.hasCredit,
      AdAnalysisError.capReached => AdFlowOutcome.capReached,
      AdAnalysisError.emailUnverified => AdFlowOutcome.emailUnverified,
      AdAnalysisError.sessionExpired => AdFlowOutcome.sessionExpired,
      AdAnalysisError.notVerified => AdFlowOutcome.verificationTimeout,
      AdAnalysisError.unknown => AdFlowOutcome.failed,
    };
    return AdFlowResult(outcome, error: e);
  }
}
