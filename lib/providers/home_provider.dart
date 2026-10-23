import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_api.dart';
import '../models/home_data.dart';
import 'auth_provider.dart';
import 'locale_provider.dart';

const homeCacheBodyKey = 'home_cache_body';
const homeCacheAtKey = 'home_cache_at_ms';
const homeCacheUserKey = 'home_cache_user';

/// Data older than this (or a failed refresh) gets the "not up to date" note.
const homeStaleAfter = Duration(minutes: 15);

/// Resume / tab-visible refreshes are skipped when the last attempt is newer.
const homeMinRefreshGap = Duration(seconds: 30);

/// While the home tab is on screen the data (live BTC price, movers...) is refreshed this
/// often. null disables it; widget tests (FLUTTER_TEST) run without it unless they override
/// the provider, so no stray timers are left behind.
final homeAutoRefreshProvider = Provider<Duration?>(
  (ref) => Platform.environment.containsKey('FLUTTER_TEST')
      ? null
      : const Duration(seconds: 45),
);

final homeApiProvider = Provider<HomeApi>((ref) => HomeApi());

/// Clock used by the home feature; overridden in tests.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class HomeState {
  /// Last known data (cached or fresh); null until anything is available.
  final HomeData? data;

  /// When [data] was fetched from the server.
  final DateTime? fetchedAt;

  /// A fetch is running (or auth is still being restored).
  final bool loading;

  /// The latest refresh attempt failed.
  final bool failed;

  /// There is a signed-in member (the endpoint needs one).
  final bool signedIn;

  const HomeState({
    this.data,
    this.fetchedAt,
    this.loading = false,
    this.failed = false,
    this.signedIn = false,
  });

  /// First load without anything to show.
  bool get showSkeleton => data == null && loading;

  /// Whether the "güncel değil" note should be shown at [now].
  bool isStale(DateTime now) {
    if (data == null) return false;
    if (failed) return true;
    final at = fetchedAt;
    if (at == null) return true;
    return now.difference(at) > homeStaleAfter;
  }

  HomeState copyWith({
    HomeData? data,
    DateTime? fetchedAt,
    bool? loading,
    bool? failed,
  }) => HomeState(
    data: data ?? this.data,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    signedIn: signedIn,
  );
}

class HomeNotifier extends Notifier<HomeState> {
  String? _token;
  int? _userId;
  DateTime? _lastAttempt;
  Future<void>? _inFlight;

  DateTime _now() => ref.read(homeClockProvider)();

  @override
  HomeState build() {
    final auth = ref.watch(
      authProvider.select((s) => (s.token, s.member?.id, s.isRestoring)),
    );
    final (token, userId, restoring) = auth;
    _token = token;
    _userId = userId;
    _lastAttempt = null;
    _inFlight = null;

    if (token == null || userId == null) {
      // Still restoring the session -> skeleton; otherwise a guest.
      return HomeState(loading: restoring || token != null);
    }

    final cached = _readCache(userId);
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return HomeState(
      data: cached?.$1,
      fetchedAt: cached?.$2,
      loading: true,
      signedIn: true,
    );
  }

  (HomeData, DateTime)? _readCache(int userId) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getInt(homeCacheUserKey) != userId) return null;
      final body = prefs.getString(homeCacheBodyKey);
      final at = prefs.getInt(homeCacheAtKey);
      if (body == null || at == null) return null;
      return (HomeData.fromBody(body), DateTime.fromMillisecondsSinceEpoch(at));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(int userId, String body, DateTime at) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(homeCacheBodyKey, body);
      await prefs.setInt(homeCacheAtKey, at.millisecondsSinceEpoch);
      await prefs.setInt(homeCacheUserKey, userId);
    } catch (_) {
      // Caching is best effort.
    }
  }

  /// Fetches fresh data. Without [force] (resume / tab shown) it is skipped
  /// when the previous attempt was less than [homeMinRefreshGap] ago.
  Future<void> refresh({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    final token = _token;
    final userId = _userId;
    if (token == null || userId == null) return Future.value();
    final now = _now();
    final last = _lastAttempt;
    if (!force && last != null && now.difference(last) < homeMinRefreshGap) {
      return Future.value();
    }
    _lastAttempt = now;
    state = state.copyWith(loading: true);
    final run = _fetch(token, userId).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _fetch(String token, int userId) async {
    try {
      final response = await ref.read(homeApiProvider).fetch(token);
      if (!ref.mounted || _token != token) return;
      final at = _now();
      state = HomeState(
        data: response.data,
        fetchedAt: at,
        loading: false,
        failed: false,
        signedIn: true,
      );
      await _writeCache(userId, response.rawBody, at);
    } catch (_) {
      if (!ref.mounted || _token != token) return;
      state = state.copyWith(loading: false, failed: true);
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
