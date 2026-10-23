import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coin_overview_api.dart';
import '../models/coin_overview.dart';
import 'auth_provider.dart';

/// Overview data younger than this is served from the client cache.
const overviewCacheTtl = Duration(minutes: 3);

final coinOverviewApiProvider = Provider<CoinOverviewApi>(
  (ref) => CoinOverviewApi(),
);

/// Clock used by the overview cache; overridden in tests.
final overviewClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

class OverviewState {
  /// Last successfully fetched data (kept while refreshing / after a failed
  /// refresh, i.e. possibly stale); null until the first success.
  final CoinOverview? data;
  final DateTime? fetchedAt;
  final bool loading;

  /// The latest fetch failed.
  final Object? error;

  const OverviewState({
    this.data,
    this.fetchedAt,
    this.loading = false,
    this.error,
  });

  bool get hasData => data != null;

  /// First load, nothing to show yet.
  bool get isInitialLoading => loading && data == null;

  /// Failed and nothing to fall back on.
  bool get isFatalError => error != null && data == null && !loading;

  /// Older data is being shown because a refresh failed.
  bool get isStale => error != null && data != null;

  bool isFresh(DateTime now) =>
      data != null &&
      fetchedAt != null &&
      now.difference(fetchedAt!) < overviewCacheTtl;
}

/// Per-coin overview with a short client cache. Loads on first read; later
/// reads only refetch once the data is older than [overviewCacheTtl] or when
/// [load] is forced (pull-to-refresh, retry).
class CoinOverviewNotifier extends Notifier<OverviewState> {
  final int coinId;
  CoinOverviewNotifier(this.coinId);

  Future<void>? _inFlight;

  DateTime _now() => ref.read(overviewClockProvider)();

  @override
  OverviewState build() {
    Future.microtask(() {
      if (ref.mounted) load();
    });
    return const OverviewState(loading: true);
  }

  Future<void> load({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;
    if (!force && state.isFresh(_now())) return Future.value();
    return _inFlight = _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> retry() => load(force: true);

  Future<void> _fetch() async {
    state = OverviewState(
      data: state.data,
      fetchedAt: state.fetchedAt,
      loading: true,
    );
    try {
      final token = ref.read(authProvider).token;
      final data = await ref
          .read(coinOverviewApiProvider)
          .fetch(coinId, token: token);
      if (!ref.mounted) return;
      state = OverviewState(data: data, fetchedAt: _now());
    } catch (e) {
      if (!ref.mounted) return;
      state = OverviewState(
        data: state.data,
        fetchedAt: state.fetchedAt,
        error: e,
      );
    }
  }
}

final coinOverviewProvider =
    NotifierProvider.family<CoinOverviewNotifier, OverviewState, int>(
      CoinOverviewNotifier.new,
    );
