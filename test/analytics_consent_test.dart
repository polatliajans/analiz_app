import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/services/analytics_consent.dart';
import 'package:kriptoanaliz/services/analytics_service.dart';

import 'helpers/analytics_fakes.dart';

class _FakeSource implements ConsentSource {
  UmpStatus current;
  bool canAds = true;
  bool throwsOnStatus;
  int refreshes = 0;

  _FakeSource(this.current, {this.throwsOnStatus = false});

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<UmpStatus> status() async {
    if (throwsOnStatus) throw StateError('no plugin');
    return current;
  }

  @override
  Future<bool> canRequestAds() async => canAds;
}

void main() {
  group('analyticsAllowedFor', () {
    test('collects when consent is not required in the region', () {
      expect(
        analyticsAllowedFor(UmpStatus.notRequired, canRequestAds: true),
        isTrue,
      );
      expect(
        analyticsAllowedFor(UmpStatus.notRequired, canRequestAds: false),
        isTrue,
      );
    });

    test('collects after consent was obtained and UMP allows it', () {
      expect(
        analyticsAllowedFor(UmpStatus.obtained, canRequestAds: true),
        isTrue,
      );
      expect(
        analyticsAllowedFor(UmpStatus.obtained, canRequestAds: false),
        isFalse,
      );
    });

    test('stays off while consent is required or unknown', () {
      expect(
        analyticsAllowedFor(UmpStatus.required, canRequestAds: true),
        isFalse,
      );
      expect(
        analyticsAllowedFor(UmpStatus.unknown, canRequestAds: true),
        isFalse,
      );
    });
  });

  group('AnalyticsConsentCoordinator', () {
    test('grants analytics when consent is not required', () async {
      final service = RecordingAnalyticsService();
      await AnalyticsConsentCoordinator(
        service,
        _FakeSource(UmpStatus.notRequired),
      ).resolveFromUmp();
      expect(service.consents, [true]);
    });

    test('denies when the user declined / consent still required', () async {
      final service = RecordingAnalyticsService();
      await AnalyticsConsentCoordinator(
        service,
        _FakeSource(UmpStatus.required),
      ).resolveFromUmp();
      expect(service.consents, [false]);
    });

    test('a failing UMP read means denied, never an exception', () async {
      final service = RecordingAnalyticsService();
      await AnalyticsConsentCoordinator(
        service,
        _FakeSource(UmpStatus.obtained, throwsOnStatus: true),
      ).resolveFromUmp();
      expect(service.consents, [false]);
    });

    test('can be re-resolved after the privacy options form', () async {
      final service = RecordingAnalyticsService();
      final source = _FakeSource(UmpStatus.obtained);
      final c = AnalyticsConsentCoordinator(service, source);
      await c.resolveFromUmp();
      source.canAds = false;
      await c.resolveFromUmp();
      expect(service.consents, [true, false]);
    });

    test('the form-less fallback refreshes once per run', () async {
      final service = RecordingAnalyticsService();
      final source = _FakeSource(UmpStatus.notRequired);
      final c = AnalyticsConsentCoordinator(service, source);
      await c.resolveWithoutForm();
      await c.resolveWithoutForm();
      expect(source.refreshes, 1);
      expect(service.consents, [true]);
    });

    test('an inactive (no-op) service never touches UMP', () async {
      final source = _FakeSource(UmpStatus.notRequired);
      final c = AnalyticsConsentCoordinator(
        const NoopAnalyticsService(),
        source,
      );
      await c.resolveWithoutForm();
      await c.resolveFromUmp();
      expect(source.refreshes, 0);
    });
  });
}
