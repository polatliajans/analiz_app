import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kriptoanaliz/data/api_http.dart';
import 'package:kriptoanaliz/data/terms_acceptance_api.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/terms_acceptance_provider.dart';
import 'package:kriptoanaliz/utils/platform_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

class _Call {
  final String token;
  final String version;
  final DateTime acceptedAt;
  final String platform;
  _Call(this.token, this.version, this.acceptedAt, this.platform);
}

class FakeTermsApi implements TermsAcceptanceApi {
  final calls = <_Call>[];
  bool fail = false;

  @override
  Future<void> submit({
    required String token,
    required String version,
    required DateTime acceptedAt,
    required String platform,
  }) async {
    calls.add(_Call(token, version, acceptedAt, platform));
    if (fail) throw StateError('offline');
  }
}

/// Auth whose state the test can flip (guest -> signed in).
class _Auth extends AuthNotifier {
  final Member? initial;
  _Auth(this.initial);

  @override
  AuthState build() => initial == null
      ? const AuthState()
      : AuthState(token: 'tok', member: initial);

  void signIn(Member m) => state = AuthState(token: 'tok2', member: m);
}

const _other = Member(id: 2, email: 'x@y.z', role: 'user', creditBalance: 0);

Future<ProviderContainer> _container(
  FakeTermsApi api,
  SharedPreferences prefs, {
  Member? member = testMember,
  String version = '2026-11-02',
}) async {
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      termsVersionProvider.overrideWithValue(version),
      termsClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 2, 9)),
      termsAcceptanceApiProvider.overrideWithValue(api),
      authProvider.overrideWith(() => _Auth(member)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<SharedPreferences> _prefs(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  return SharedPreferences.getInstance();
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  const accepted = <String, Object>{
    termsAcceptedVersionKey: '2026-11-02',
    termsAcceptedAtKey: '2026-11-02T08:30:00.000Z',
  };

  test('signed-in member: sends once with version, time, platform', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs(accepted));
    c.read(termsSyncProvider);
    await _settle();

    expect(api.calls, hasLength(1));
    expect(api.calls.single.token, 'tok');
    expect(api.calls.single.version, '2026-11-02');
    expect(api.calls.single.acceptedAt, DateTime.utc(2026, 11, 2, 8, 30));
    expect(api.calls.single.platform, 'android');

    // Same member + version is never sent twice.
    expect(await c.read(termsSyncProvider.notifier).sync(), isTrue);
    expect(api.calls, hasLength(1));
  });

  test('a failure is retried on the next launch, not marked done', () async {
    final api = FakeTermsApi()..fail = true;
    final prefs = await _prefs(accepted);
    final first = await _container(api, prefs);
    first.read(termsSyncProvider);
    await _settle();
    expect(api.calls, hasLength(1));
    expect(prefs.getStringList(termsSyncedKey), isNull);

    // Next launch: same storage, server is back.
    api.fail = false;
    final second = await _container(api, prefs);
    second.read(termsSyncProvider);
    await _settle();
    expect(api.calls, hasLength(2));
    expect(prefs.getStringList(termsSyncedKey), ['1|2026-11-02']);

    final third = await _container(api, prefs);
    third.read(termsSyncProvider);
    await _settle();
    expect(api.calls, hasLength(2));
  });

  test('guests only store locally: nothing is sent', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs(accepted), member: null);
    c.read(termsSyncProvider);
    await _settle();
    expect(api.calls, isEmpty);
  });

  test('nothing is sent before the terms were accepted', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs({}));
    c.read(termsSyncProvider);
    await _settle();
    expect(api.calls, isEmpty);
  });

  test('accepting while signed in sends right away', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs({}));
    c.read(termsSyncProvider);
    await c.read(termsAcceptedProvider.notifier).accept();
    await _settle();
    expect(api.calls, hasLength(1));
    expect(api.calls.single.acceptedAt, DateTime.utc(2026, 11, 2, 9));
  });

  test('a guest who registers later is reported after login', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs(accepted), member: null);
    c.read(termsSyncProvider);
    await _settle();
    expect(api.calls, isEmpty);

    (c.read(authProvider.notifier) as _Auth).signIn(testMember);
    await _settle();
    expect(api.calls, hasLength(1));
    expect(api.calls.single.token, 'tok2');
  });

  test('another member on the same device is reported separately', () async {
    final api = FakeTermsApi();
    final c = await _container(api, await _prefs(accepted));
    c.read(termsSyncProvider);
    await _settle();
    (c.read(authProvider.notifier) as _Auth).signIn(_other);
    await _settle();
    expect(api.calls, hasLength(2));
  });

  test(
    'a new terms version is reported again and old entries pruned',
    () async {
      final api = FakeTermsApi();
      final prefs = await _prefs({
        ...accepted,
        termsSyncedKey: ['1|2026-01-01'],
      });
      final c = await _container(api, prefs);
      c.read(termsSyncProvider);
      await _settle();
      expect(api.calls, hasLength(1));
      expect(prefs.getStringList(termsSyncedKey), ['1|2026-11-02']);
    },
  );

  group('HttpTermsAcceptanceApi', () {
    Future<http.Request> run(int status) async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(jsonEncode({'ok': true}), status);
      });
      await http.runWithClient(
        () => const HttpTermsAcceptanceApi().submit(
          token: 'abc',
          version: '2026-11-02',
          acceptedAt: DateTime.utc(2026, 11, 2, 9),
          platform: 'ios',
        ),
        () => client,
      );
      return seen;
    }

    tearDown(() => ApiHttp.platformResolver = platformName);

    test('posts the JSON body with the bearer token', () async {
      final req = await run(200);
      expect(req.method, 'POST');
      expect(req.url.path, endsWith('/api/me/terms-acceptance'));
      expect(req.headers['Authorization'], 'Bearer abc');
      expect(req.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(req.body), {
        'version': '2026-11-02',
        'accepted_at': '2026-11-02T09:00:00.000Z',
        'platform': 'ios',
      });
    });

    test('accepts 204 and rejects other statuses', () async {
      await run(204);
      await expectLater(run(422), throwsStateError);
      await expectLater(run(500), throwsStateError);
    });
  });
}
