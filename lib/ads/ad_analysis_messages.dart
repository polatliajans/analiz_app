import '../l10n/app_localizations.dart';
import 'ad_analysis_flow.dart';

/// User-facing text for a finished ad-analysis flow; null when nothing should
/// be said (success, cancelled, or [AdFlowOutcome.hasCredit] / failures that
/// the caller handles itself).
String? adFlowMessage(AppLocalizations l10n, AdFlowOutcome outcome) =>
    switch (outcome) {
      AdFlowOutcome.adUnavailable => l10n.adAnalysisAdUnavailable,
      AdFlowOutcome.verificationTimeout => l10n.adAnalysisVerifyTimeout,
      AdFlowOutcome.capReached => l10n.adAnalysisCapReached,
      AdFlowOutcome.notFree => l10n.adAnalysisNotFree,
      AdFlowOutcome.disabled => l10n.adAnalysisDisabled,
      AdFlowOutcome.emailUnverified => l10n.adAnalysisEmailUnverified,
      AdFlowOutcome.sessionExpired => l10n.adAnalysisSessionExpired,
      AdFlowOutcome.success ||
      AdFlowOutcome.cancelled ||
      AdFlowOutcome.hasCredit ||
      AdFlowOutcome.failed => null,
    };
