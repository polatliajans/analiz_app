import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics_service.dart';

/// UMP's consent verdict, decoupled from the SDK type for testing.
enum UmpStatus { notRequired, required, obtained, unknown }

/// Analytics may collect when consent is not needed in the user's region, or
/// when UMP lets the app proceed (`canRequestAds`, which is what UMP itself
/// treats as the verdict). The status can read `unknown` on devices where
/// UMP already says ads may be requested (seen in Turkey), so `unknown` follows
/// `canRequestAds`. A still-required or declined consent keeps analytics off.
bool analyticsAllowedFor(UmpStatus status, {required bool canRequestAds}) {
  switch (status) {
    case UmpStatus.notRequired:
      return true;
    case UmpStatus.obtained:
    case UmpStatus.unknown:
      return canRequestAds;
    case UmpStatus.required:
      return false;
  }
}

/// Where the consent verdict comes from; faked in tests.
abstract class ConsentSource {
  /// Refreshes the consent info from UMP without showing any form.
  Future<void> refresh();
  Future<UmpStatus> status();
  Future<bool> canRequestAds();
}

class UmpConsentSource implements ConsentSource {
  const UmpConsentSource();

  @override
  Future<void> refresh() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!done.isCompleted) done.complete();
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  @override
  Future<UmpStatus> status() async {
    switch (await ConsentInformation.instance.getConsentStatus()) {
      case ConsentStatus.notRequired:
        return UmpStatus.notRequired;
      case ConsentStatus.required:
        return UmpStatus.required;
      case ConsentStatus.obtained:
        return UmpStatus.obtained;
      case ConsentStatus.unknown:
        return UmpStatus.unknown;
    }
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();
}

/// Turns UMP's verdict into the analytics consent decision.
class AnalyticsConsentCoordinator {
  final AnalyticsService _service;
  final ConsentSource _source;
  bool _fallbackTried = false;

  AnalyticsConsentCoordinator(this._service, this._source);

  /// Reads the current UMP verdict (after the ad flow ran its form) and
  /// applies it. Safe to repeat: the privacy options form can change it.
  Future<void> resolveFromUmp() async {
    if (!_service.active) return;
    var allowed = false;
    try {
      final status = await _source.status();
      final can = await _source.canRequestAds();
      allowed = analyticsAllowedFor(status, canRequestAds: can);
      analyticsTrace('consent ump=$status canRequestAds=$can allowed=$allowed');
    } catch (e) {
      // Unknown means off.
      analyticsTrace('consent ERR ${e.runtimeType}: $e');
    }
    await _service.applyConsent(allowed: allowed);
  }

  /// For members whose ads (and therefore the consent form) never run, e.g.
  /// Pro: refresh the UMP info silently, once per run, and apply the verdict.
  /// No form is shown here.
  Future<void> resolveWithoutForm() async {
    if (!_service.active || _fallbackTried) return;
    _fallbackTried = true;
    try {
      await _source.refresh();
    } catch (_) {}
    await resolveFromUmp();
  }
}

final analyticsConsentCoordinatorProvider =
    Provider<AnalyticsConsentCoordinator>(
      (ref) => AnalyticsConsentCoordinator(
        ref.watch(analyticsProvider),
        const UmpConsentSource(),
      ),
    );
