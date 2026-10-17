import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kriptoanaliz/data/notification_settings_api.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/notification_settings_provider.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(token: 't');
}

class _FakeApi extends NotificationSettingsApi {
  bool failUpdate = false;

  @override
  Future<NotificationSettings> fetch(String token) async =>
      const NotificationSettings(
        values: {
          'announcements': true,
          'credits': true,
          'signals': true,
          'alerts': true,
        },
        proOnly: {'signals', 'alerts'},
      );

  @override
  Future<NotificationSettings> update(
    String token,
    Map<String, bool> changes,
  ) async {
    if (failUpdate) throw const NotificationSettingsException(500);
    return NotificationSettings(
      values: {
        'announcements': true,
        'credits': true,
        'signals': true,
        'alerts': true,
        ...changes,
      },
      proOnly: const {'signals', 'alerts'},
    );
  }
}

void main() {
  ProviderContainer make(_FakeApi api) => ProviderContainer(
    overrides: [
      authProvider.overrideWith(_Auth.new),
      notificationSettingsApiProvider.overrideWithValue(api),
    ],
  );

  test('parses missing keys as on and exposes pro_only', () {
    final s = NotificationSettings.fromJson({
      'settings': {'credits': false},
      'pro_only': ['signals'],
    });
    expect(s.isOn('credits'), isFalse);
    expect(s.isOn('alerts'), isTrue);
    expect(s.isProOnly('signals'), isTrue);
    expect(s.isProOnly('alerts'), isFalse);
  });

  test('setValue saves the change', () async {
    final c = make(_FakeApi());
    addTearDown(c.dispose);
    await c.read(notificationSettingsProvider.future);
    await c.read(notificationSettingsProvider.notifier).setValue('credits', false);
    expect(c.read(notificationSettingsProvider).value!.isOn('credits'), isFalse);
  });

  test('setValue rolls back and rethrows on failure', () async {
    final api = _FakeApi()..failUpdate = true;
    final c = make(api);
    addTearDown(c.dispose);
    await c.read(notificationSettingsProvider.future);
    await expectLater(
      c.read(notificationSettingsProvider.notifier).setValue('credits', false),
      throwsA(isA<NotificationSettingsException>()),
    );
    expect(c.read(notificationSettingsProvider).value!.isOn('credits'), isTrue);
  });
}
