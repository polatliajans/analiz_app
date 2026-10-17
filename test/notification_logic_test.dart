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
    test('shows the rationale once for a signed-in member without permission',
        () {
      expect(
        decideNotificationPermissionPrompt(
          loggedIn: true,
          alreadyAsked: false,
          permissionGranted: false,
        ),
        isTrue,
      );
    });
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
}
