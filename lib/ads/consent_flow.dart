import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/widgets.dart';

/// The steps of the ad start-up sequence, injectable so the ORDER can be unit
/// tested without the native SDKs.
class ConsentFlowSteps {
  /// iOS only: App Tracking Transparency applies.
  final bool ios;

  /// UMP consent info update + form (shown only when required).
  final Future<void> Function() ump;

  /// UMP's verdict after the form.
  final Future<bool> Function() canRequestAds;

  /// The ATT system prompt (iOS only; may be a no-op when already decided).
  final Future<void> Function() requestTracking;

  /// `MobileAds.instance.initialize()`.
  final Future<void> Function() initialize;

  const ConsentFlowSteps({
    required this.ios,
    required this.ump,
    required this.canRequestAds,
    required this.requestTracking,
    required this.initialize,
  });
}

/// UMP consent -> (iOS) ATT prompt -> SDK init. Returns true when ads may be
/// requested. ATT runs only once UMP allows ads (no ads means no tracking to
/// ask about) and never blocks or breaks start-up: a failing or denied ATT
/// request still lets the SDK initialize (it then serves non-personalized ads).
Future<bool> runConsentFlow(ConsentFlowSteps steps) async {
  await steps.ump();
  if (!await steps.canRequestAds()) return false;
  if (steps.ios) {
    try {
      await steps.requestTracking();
    } catch (_) {
      // Non-blocking by design.
    }
  }
  await steps.initialize();
  return true;
}

/// Shows the ATT prompt when the user has not decided yet. The system only
/// presents it while the app is active, so wait (bounded) for that first.
Future<void> requestTrackingAuthorizationIfNeeded({
  Duration maxWait = const Duration(seconds: 5),
}) async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status != TrackingStatus.notDetermined) return;
  final deadline = DateTime.now().add(maxWait);
  while (WidgetsBinding.instance.lifecycleState != null &&
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  await AppTrackingTransparency.requestTrackingAuthorization();
}
