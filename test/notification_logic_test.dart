import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/services/notification_logic.dart';

void main() {
  group('resolveNotificationTarget', () {
    test('maps every known screen', () {
      expect(
        resolveNotificationTarget({'screen': 'profile'}).screen,
        NotificationScreen.profile,
      );
      expect(
        resolveNotificationTarget({'screen': 'credit_packages'}).screen,
        NotificationScreen.creditPackages,
      );
      expect(
        resolveNotificationTarget({'screen': 'subscription'}).screen,
        NotificationScreen.subscription,
      );
      expect(
        resolveNotificationTarget({'screen': 'radar'}).screen,
        NotificationScreen.radar,
      );
      expect(
        resolveNotificationTarget({'screen': 'alarms'}).screen,
        NotificationScreen.alarms,
      );
      expect(
        resolveNotificationTarget({'screen': 'none'}).screen,
        NotificationScreen.none,
      );
    });

    test('chart carries a numeric or string coin_id', () {
      final a = resolveNotificationTarget({'screen': 'chart', 'coin_id': '42'});
      expect(a.screen, NotificationScreen.chart);
      expect(a.coinId, 42);
      final b = resolveNotificationTarget({'screen': 'chart', 'coin_id': 7});
      expect(b.coinId, 7);
    });

    test('chart with missing or bad coin_id has no coin', () {
      expect(resolveNotificationTarget({'screen': 'chart'}).coinId, isNull);
      expect(
        resolveNotificationTarget({'screen': 'chart', 'coin_id': 'x'}).coinId,
        isNull,
      );
    });

    test('deep_analysis carries the job id and needs login', () {
      final a = resolveNotificationTarget({
        'screen': 'deep_analysis',
        'job_id': '12',
        'analysis_id': '5',
      });
      expect(a.screen, NotificationScreen.deepAnalysis);
      expect(a.jobId, 12);
      expect(a.requiresLogin, isTrue);
      expect(
        resolveNotificationTarget({
          'screen': 'deep_analysis',
          'job_id': 3,
        }).jobId,
        3,
      );
      expect(
        resolveNotificationTarget({'screen': 'deep_analysis'}).jobId,
        isNull,
      );
    });

    test('unknown or missing screen only opens the app', () {
      expect(
        resolveNotificationTarget({'screen': 'nope'}).screen,
        NotificationScreen.none,
      );
      expect(resolveNotificationTarget({}).screen, NotificationScreen.none);
      expect(
        resolveNotificationTarget({'screen': 5}).screen,
        NotificationScreen.none,
      );
    });

    test('coin_id is ignored for non-chart screens', () {
      expect(
        resolveNotificationTarget({'screen': 'radar', 'coin_id': '3'}).coinId,
        isNull,
      );
    });

    test('requiresLogin', () {
      expect(
        const NotificationTarget(NotificationScreen.alarms).requiresLogin,
        isTrue,
      );
      expect(
        const NotificationTarget(NotificationScreen.radar).requiresLogin,
        isFalse,
      );
    });
  });

  group('resolveNotificationPayload', () {
    test('parses JSON payload', () {
      final t = resolveNotificationPayload('{"screen":"chart","coin_id":"5"}');
      expect(t.screen, NotificationScreen.chart);
      expect(t.coinId, 5);
    });

    test('bad payload opens the app only', () {
      expect(resolveNotificationPayload(null).screen, NotificationScreen.none);
      expect(
        resolveNotificationPayload('not json').screen,
        NotificationScreen.none,
      );
      expect(resolveNotificationPayload('[1]').screen, NotificationScreen.none);
    });
  });

  group('resolveChannelId', () {
    test('uses a known android channel id first', () {
      expect(resolveChannelId('alerts', {'category': 'credit'}), 'alerts');
    });
    test('falls back to data.channel, then data.category', () {
      expect(resolveChannelId(null, {'channel': 'signals'}), 'signals');
      expect(resolveChannelId('weird', {'category': 'credit'}), 'credits');
      expect(resolveChannelId(null, {'category': 'signal'}), 'signals');
      expect(resolveChannelId(null, {'category': 'alert'}), 'alerts');
      expect(
        resolveChannelId(null, {'category': 'announcement'}),
        'announcements',
      );
    });
    test('defaults to announcements', () {
      expect(resolveChannelId(null, {}), 'announcements');
      expect(resolveChannelId('x', {'category': 'y'}), 'announcements');
    });
  });

  group('decideNotificationPermissionPrompt', () {
    test(
      'shows the rationale once for a signed-in member without permission',
      () {
        expect(
          decideNotificationPermissionPrompt(
            loggedIn: true,
            alreadyAsked: false,
            permissionGranted: false,
          ),
          isTrue,
        );
      },
    );
    test('never when guest, already asked, or already granted', () {
      expect(
        decideNotificationPermissionPrompt(
          loggedIn: false,
          alreadyAsked: false,
          permissionGranted: false,
        ),
        isFalse,
      );
      expect(
        decideNotificationPermissionPrompt(
          loggedIn: true,
          alreadyAsked: true,
          permissionGranted: false,
        ),
        isFalse,
      );
      expect(
        decideNotificationPermissionPrompt(
          loggedIn: true,
          alreadyAsked: false,
          permissionGranted: true,
        ),
        isFalse,
      );
    });
  });

  group('rememberMessage / stableNotificationId', () {
    test('a new key is accepted and remembered', () {
      final r = rememberMessage(const [], '42');
      expect(r.isNew, isTrue);
      expect(r.seen, ['42']);
    });

    test('a repeated key is rejected and the list is unchanged', () {
      final r = rememberMessage(const ['42', '43'], '42');
      expect(r.isNew, isFalse);
      expect(r.seen, ['42', '43']);
    });

    test('a missing or empty key is always treated as new', () {
      expect(rememberMessage(const ['1'], null).isNew, isTrue);
      expect(rememberMessage(const ['1'], '').isNew, isTrue);
      expect(rememberMessage(const ['1'], null).seen, ['1']);
    });

    test('only the most recent ids are kept', () {
      var seen = <String>[];
      for (var i = 0; i < seenMessageLimit + 5; i++) {
        seen = rememberMessage(seen, 'id$i').seen;
      }
      expect(seen.length, seenMessageLimit);
      expect(seen.first, 'id5');
      expect(seen.last, 'id${seenMessageLimit + 4}');
      // An evicted id would be shown again; a recent one is still blocked.
      expect(rememberMessage(seen, 'id0').isNew, isTrue);
      expect(rememberMessage(seen, 'id${seenMessageLimit + 4}').isNew, isFalse);
    });

    test('notification id is stable, positive and 31-bit', () {
      expect(stableNotificationId('7'), stableNotificationId('7'));
      expect(stableNotificationId('7'), isNot(stableNotificationId('8')));
      for (final k in ['1', 'push-12345', 'a' * 200]) {
        final id = stableNotificationId(k);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0x7fffffff));
      }
    });
  });
}
