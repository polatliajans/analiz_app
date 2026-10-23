import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

Future<({ProviderContainer c, FakeHomeApi api, MutableClock clock})> _setup({
  required Future<HomeResponse> Function() handler,
  Map<String, Object> prefs = const {},
  Member? member = testMember,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final api = FakeHomeApi(handler);
  final clock = MutableClock(now ?? homeTestNow);
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      authProvider.overrideWith(() => FakeAuth(member)),
      homeApiProvider.overrideWithValue(api),
      homeClockProvider.overrideWithValue(clock.call),
    ],
  );
  addTearDown(c.dispose);
  c.listen(homeProvider, (_, _) {});
  return (c: c, api: api, clock: clock);
}

Map<String, Object> _cachePrefs(DateTime at, {int user = 1}) => {
  homeCacheBodyKey: jsonEncode(fullHomeJson()),
  homeCacheAtKey: at.millisecondsSinceEpoch,
  homeCacheUserKey: user,
};

void main() {
  test('first load: skeleton, then data, and the response is cached', () async {
    final done = Completer<HomeResponse>();
    final s = await _setup(handler: () => done.future);

    var st = s.c.read(homeProvider);
    expect(st.signedIn, isTrue);
    expect(st.showSkeleton, isTrue);
    expect(st.data, isNull);

    await pumpEventQueue();
    expect(s.api.calls, 1);
    expect(s.api.lastToken, 'tok');

    done.complete(homeResponse(fullHomeJson()));
    await pumpEventQueue();

    st = s.c.read(homeProvider);
    expect(st.showSkeleton, isFalse);
    expect(st.loading, isFalse);
    expect(st.failed, isFalse);
    expect(st.data!.credits!.balance, 80);
    expect(st.fetchedAt, s.clock.now);
    expect(st.isStale(s.clock.now), isFalse);

    final prefs = s.c.read(sharedPreferencesProvider);
    expect(prefs.getString(homeCacheBodyKey), isNotNull);
    expect(prefs.getInt(homeCacheUserKey), 1);
  });

  test('cached response is shown immediately while refreshing', () async {
    final done = Completer<HomeResponse>();
    final s = await _setup(
      handler: () => done.future,
      prefs: _cachePrefs(homeTestNow.subtract(const Duration(minutes: 5))),
    );
    final st = s.c.read(homeProvider);
    expect(st.data, isNotNull);
    expect(st.showSkeleton, isFalse);
    expect(st.loading, isTrue);
    expect(st.isStale(s.clock.now), isFalse);
  });

  test('cache older than 15 minutes is flagged stale', () async {
    final done = Completer<HomeResponse>();
    final s = await _setup(
      handler: () => done.future,
      prefs: _cachePrefs(homeTestNow.subtract(const Duration(minutes: 16))),
    );
    expect(s.c.read(homeProvider).isStale(s.clock.now), isTrue);
    expect(
      s.c
          .read(homeProvider)
          .isStale(s.clock.now.subtract(const Duration(minutes: 10))),
      isFalse,
    );
  });

  test('refresh failure keeps cached data and marks it stale', () async {
    final s = await _setup(
      handler: () => Future.error(HomeException('boom')),
      prefs: _cachePrefs(homeTestNow.subtract(const Duration(minutes: 2))),
    );
    await pumpEventQueue();
    final st = s.c.read(homeProvider);
    expect(st.failed, isTrue);
    expect(st.loading, isFalse);
    expect(st.data, isNotNull);
    // Fresh data, but the refresh failed: still shows the note.
    expect(st.isStale(s.clock.now), isTrue);
  });

  test('failure without cache leaves no data (error card)', () async {
    final s = await _setup(handler: () => Future.error(HomeException('x')));
    await pumpEventQueue();
    final st = s.c.read(homeProvider);
    expect(st.data, isNull);
    expect(st.failed, isTrue);
    expect(st.showSkeleton, isFalse);
    expect(st.isStale(s.clock.now), isFalse);
  });

  test('a later success clears the failure', () async {
    var fail = true;
    final s = await _setup(
      handler: () => fail
          ? Future.error(HomeException('x'))
          : Future.value(homeResponse(fullHomeJson())),
    );
    await pumpEventQueue();
    expect(s.c.read(homeProvider).failed, isTrue);
    fail = false;
    await s.c.read(homeProvider.notifier).refresh(force: true);
    final st = s.c.read(homeProvider);
    expect(st.failed, isFalse);
    expect(st.data, isNotNull);
  });

  test('non-forced refreshes are debounced to once per 30 seconds', () async {
    final s = await _setup(
      handler: () => Future.value(homeResponse(fullHomeJson())),
    );
    await pumpEventQueue();
    expect(s.api.calls, 1);

    final n = s.c.read(homeProvider.notifier);
    s.clock.now = s.clock.now.add(const Duration(seconds: 20));
    await n.refresh();
    expect(s.api.calls, 1);

    s.clock.now = s.clock.now.add(const Duration(seconds: 11));
    await n.refresh();
    expect(s.api.calls, 2);

    await n.refresh(force: true); // pull-to-refresh ignores the debounce
    expect(s.api.calls, 3);
  });

  test('cache of another account is ignored', () async {
    final done = Completer<HomeResponse>();
    final s = await _setup(
      handler: () => done.future,
      prefs: _cachePrefs(homeTestNow, user: 99),
    );
    expect(s.c.read(homeProvider).data, isNull);
    expect(s.c.read(homeProvider).showSkeleton, isTrue);
  });

  test('guest: no request, not signed in', () async {
    final s = await _setup(
      handler: () => Future.value(homeResponse(fullHomeJson())),
      member: null,
    );
    await pumpEventQueue();
    final st = s.c.read(homeProvider);
    expect(st.signedIn, isFalse);
    expect(st.showSkeleton, isFalse);
    expect(s.api.calls, 0);
  });
}
