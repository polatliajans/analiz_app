import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

class FirebaseAnalyticsBackend implements AnalyticsBackend {
  FirebaseAnalytics get _a => FirebaseAnalytics.instance;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _a.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> setConsent(AnalyticsConsent consent) => _a.setConsent(
    analyticsStorageConsentGranted: consent.analyticsStorage,
    adStorageConsentGranted: consent.adStorage,
    adUserDataConsentGranted: consent.adUserData,
    adPersonalizationSignalsConsentGranted: consent.adPersonalization,
  );

  @override
  Future<void> logEvent(String name, Map<String, Object> params) =>
      _a.logEvent(name: name, parameters: params.isEmpty ? null : params);

  @override
  Future<void> logScreenView(String screenName) =>
      _a.logScreenView(screenName: screenName);

  @override
  Future<void> setUserId(String? id) => _a.setUserId(id: id);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _a.setUserProperty(name: name, value: value);

  @override
  Future<void> resetAnalyticsData() => _a.resetAnalyticsData();
}
