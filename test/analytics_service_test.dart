import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/services/analytics_events.dart';
import 'package:kriptoanaliz/services/analytics_service.dart';

import 'helpers/analytics_fakes.dart';

void main() {
  late FakeAnalyticsBackend backend;
  late SafeAnalyticsService service;

  setUp(() {
    backend = FakeAnalyticsBackend();
    service = SafeAnalyticsService(backend);
  });

  group('consent', () {
    test(
      'starts denied: collection off and every consent type denied',
      () async {
        await service.init();
        expect(backend.collectionEnabled, isFalse);
        expect(backend.consents.single.analyticsStorage, isFalse);
        expect(backend.consents.single.adStorage, isFalse);
        expect(backend.consents.single.adUserData, isFalse);
        expect(backend.consents.single.adPersonalization, isFalse);
      },
    );

    test('granting only grants analytics storage, never ad consent', () async {
      await service.init();
      await service.applyConsent(allowed: true);
      final c = backend.consents.last;
      expect(c.analyticsStorage, isTrue);
      expect(c.adStorage, isFalse);
      expect(c.adUserData, isFalse);
      expect(c.adPersonalization, isFalse);
      expect(backend.collectionEnabled, isTrue);
    });

    test(
      'events logged before the decision are held, then flushed on grant',
      () async {
        await service.init();
        service.logEvent('logout');
        service.logScreenView('home');
        expect(backend.events, isEmpty);
        expect(backend.screens, isEmpty);
        await service.applyConsent(allowed: true);
        expect(backend.events.map((e) => e.name), ['logout']);
        expect(backend.screens, ['home']);
      },
    );

    test('denying drops held events and later events', () async {
      await service.init();
      service.logEvent('logout');
      await service.applyConsent(allowed: false);
      service.logEvent('logout');
      await service.applyConsent(allowed: true);
      expect(backend.events, isEmpty);
    });

    test('revoking after a grant stops collection', () async {
      await service.applyConsent(allowed: true);
      service.logEvent('logout');
      await service.applyConsent(allowed: false);
      service.logEvent('logout');
      expect(backend.events.length, 1);
      expect(backend.collectionEnabled, isFalse);
      expect(backend.userId, isNull);
    });

    test('the held queue is bounded', () async {
      for (var i = 0; i < analyticsMaxQueuedEvents + 20; i++) {
        service.logEvent('logout');
      }
      await service.applyConsent(allowed: true);
      expect(backend.events.length, analyticsMaxQueuedEvents);
    });
  });

  group('identity', () {
    test('user id and properties wait for consent, then apply', () async {
      service.setUserId('42');
      service.setUserProperty('plan', 'pro');
      expect(backend.userId, isNull);
      expect(backend.userProperties, isEmpty);
      await service.applyConsent(allowed: true);
      expect(backend.userId, '42');
      expect(backend.userProperties['plan'], 'pro');
    });

    test('logout clears the user id', () async {
      await service.applyConsent(allowed: true);
      service.setUserId('42');
      service.setUserId(null);
      expect(backend.userId, isNull);
    });

    test(
      'account deletion forgets identity and resets analytics data',
      () async {
        await service.applyConsent(allowed: true);
        service.setUserId('42');
        service.setUserProperty('plan', 'pro');
        await service.resetOnAccountDeleted();
        expect(backend.userId, isNull);
        expect(backend.userProperties['plan'], isNull);
        expect(backend.resets, 1);
      },
    );

    test('property names and values respect the SDK limits', () async {
      await service.applyConsent(allowed: true);
      service.setUserProperty('x' * 25, 'v');
      service.setUserProperty('1bad', 'v');
      service.setUserProperty('plan', 'p' * 80);
      expect(backend.userProperties.keys, ['plan']);
      expect(
        backend.userProperties['plan']!.length,
        analyticsMaxUserPropertyValueLength,
      );
    });
  });

  group('validation', () {
    setUp(() => service.applyConsent(allowed: true));

    test('invalid event names are dropped', () {
      service.logEvent('');
      service.logEvent('has space');
      service.logEvent('1starts_with_digit');
      service.logEvent('firebase_reserved');
      service.logEvent('google_reserved');
      service.logEvent('a' * (analyticsMaxEventNameLength + 1));
      expect(backend.events, isEmpty);
    });

    test('a 40 character name is accepted', () {
      service.logEvent('a' * analyticsMaxEventNameLength);
      expect(backend.events.length, 1);
    });

    test(
      'params: nulls dropped, booleans become numbers, strings truncated',
      () {
        service.logEvent('logout', {
          'a': null,
          'b': true,
          'c': false,
          'd': 'x' * 300,
          'e': 3,
          'f': 1.5,
          'g': double.nan,
          'h': ['list'],
          'bad name': 'v',
        });
        final p = backend.events.single.params;
        expect(p.keys.toSet(), {'b', 'c', 'd', 'e', 'f'});
        expect(p['b'], 1);
        expect(p['c'], 0);
        expect((p['d'] as String).length, analyticsMaxParamValueLength);
      },
    );

    test('at most $analyticsMaxParams params are sent', () {
      service.logEvent('logout', {for (var i = 0; i < 40; i++) 'p$i': i});
      expect(backend.events.single.params.length, analyticsMaxParams);
    });
  });

  group('never throws', () {
    test('a failing backend is swallowed on every call', () async {
      final failing = SafeAnalyticsService(FakeAnalyticsBackend(throws: true));
      await failing.init();
      await failing.applyConsent(allowed: true);
      failing.logEvent('logout', {'a': 1});
      failing.logScreenView('home');
      failing.setUserId('1');
      failing.setUserProperty('plan', 'pro');
      await failing.resetOnAccountDeleted();
      await failing.applyConsent(allowed: false);
      // Give the unawaited futures a chance to surface errors.
      await Future<void>.delayed(Duration.zero);
    });

    test('the no-op service is safe and inactive', () async {
      const noop = NoopAnalyticsService();
      expect(noop.active, isFalse);
      await noop.init();
      await noop.applyConsent(allowed: true);
      noop.logEvent('logout');
      noop.logLogin(AuthMethod.google);
      await noop.resetOnAccountDeleted();
    });

    test('the default provider is a no-op (no Firebase in tests)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(analyticsProvider).active, isFalse);
    });
  });

  group('event catalogue', () {
    test('every event name is valid, short and unique', () {
      expect(AnalyticsEvents.all.toSet().length, AnalyticsEvents.all.length);
      for (final name in AnalyticsEvents.all) {
        expect(name.length, lessThanOrEqualTo(analyticsMaxEventNameLength));
        expect(isValidAnalyticsName(name), isTrue, reason: name);
        expect(name, equals(name.toLowerCase()));
      }
    });

    test(
      'every typed helper sends a catalogued event within the limits',
      () async {
        final rec = FakeAnalyticsBackend();
        final s = SafeAnalyticsService(rec);
        await s.applyConsent(allowed: true);
        s.logLogin(AuthMethod.google);
        s.logSignUp(AuthMethod.email);
        s.logLogout();
        s.logAnalysisStarted(AnalysisFunnel.quick, '1h');
        s.logAnalysisCompleted(AnalysisFunnel.deep, '1d', 4);
        s.logAnalysisFailed(AnalysisFunnel.ad, 'adUnavailable');
        s.logCreditPurchaseStarted('credits_50');
        s.logPurchase('credits_50');
        s.logSubscriptionStarted('pro_monthly');
        s.logProScreenView('subscription_screen');
        s.logPaywallDismissed('subscription_screen');
        s.logRestoreTapped();
        s.logAdShown('interstitial_analysis', 'interstitial');
        s.logRewardedAdCompleted('rewarded_analysis');
        s.logPushOpened('radar');

        expect(
          rec.events.map((e) => e.name).toSet(),
          AnalyticsEvents.all.toSet(),
        );
        for (final e in rec.events) {
          expect(e.params.length, lessThanOrEqualTo(analyticsMaxParams));
          for (final entry in e.params.entries) {
            expect(isValidAnalyticsName(entry.key), isTrue);
            // No personal data: nothing that looks like an email address.
            expect('${entry.value}'.contains('@'), isFalse);
          }
        }
      },
    );

    test('auth methods and buckets', () {
      expect(AuthMethod.values.map((m) => m.name), [
        'google',
        'email',
        'apple',
        'guest',
      ]);
      expect(timeframeClass('5m'), 'short');
      expect(timeframeClass('4h'), 'medium');
      expect(timeframeClass('1w'), 'long');
      expect(creditCostBucket(0), '0');
      expect(creditCostBucket(2), '1_2');
      expect(creditCostBucket(5), '3_5');
      expect(creditCostBucket(9), '6_plus');
    });

    test('tab screen names follow the bottom tabs', () {
      expect(AnalyticsScreens.tabs, [
        'home',
        'chart',
        'radar',
        'watchlist',
        'account',
      ]);
      expect(AnalyticsScreens.tab(99), 'home');
    });
  });
}
