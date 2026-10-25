import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/kline_stream.dart';
import '../models/candle.dart';
import '../models/chart_signal.dart';
import '../utils/timeframes.dart';
import 'auth_provider.dart';
import 'chart_data_provider.dart';
import 'home_tab_provider.dart';

/// Minimum gap between two UI updates driven by the live stream.
const liveUiThrottle = Duration(milliseconds: 500);

/// How often signals are re-fetched while the chart is visible.
const signalRefreshInterval = Duration(minutes: 1);

/// REST polling period used when the WebSocket keeps failing.
const pollingInterval = Duration(seconds: 5);

/// No message for this long means the stream is stalled; treat it as lost.
const streamSilenceTimeout = Duration(seconds: 15);

/// Failed connection attempts before switching to REST polling.
const pollingFailureThreshold = 3;

final klineStreamProvider = Provider<KlineStream>(
  (ref) => const WebSocketKlineStream(),
);

/// Merges freshly fetched signals into [existing]: same candle time and type
/// are replaced by the fresh one, others are kept. Sorted by candle time.
List<ChartSignal> mergeSignals(
  List<ChartSignal> existing,
  List<ChartSignal> fresh,
) {
  final byKey = <(int, String), ChartSignal>{};
  for (final s in [...existing, ...fresh]) {
    byKey[(s.candleTime.millisecondsSinceEpoch, s.signalType)] = s;
  }
  final out = byKey.values.toList()
    ..sort((a, b) => a.candleTime.compareTo(b.candleTime));
  return out;
}

class LiveChartState {
  final bool loading;
  final Object? error;
  final List<Candle> candles;
  final List<ChartSignal> signals;

  /// Latest price (live close); null before the first load.
  final double? price;

  /// 1 if the last price move was up, -1 if down, 0 if unknown.
  final int direction;

  /// 24h change in percent from the mini ticker; null until it arrives.
  final double? change24h;

  /// True while the REST polling fallback is active.
  final bool polling;

  const LiveChartState({
    this.loading = true,
    this.error,
    this.candles = const [],
    this.signals = const [],
    this.price,
    this.direction = 0,
    this.change24h,
    this.polling = false,
  });
}

class _LifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState) onChange;
  _LifecycleObserver(this.onChange);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}

/// Owns candles, signals and the live price of one coin/timeframe.
///
/// Live only while the chart tab is selected and the app is in the
/// foreground: then it loads history over REST once, connects the WebSocket
/// and refreshes signals every minute. Leaving closes everything; returning
/// reloads the history and reconnects.
class LiveChartController extends Notifier<LiveChartState> {
  final ChartDataParams params;
  LiveChartController(this.params);

  late _LifecycleObserver _observer;
  bool _tabVisible = true;
  bool _appForeground = true;
  bool _running = false;
  bool _disposed = false;
  int _gen = 0;

  List<Candle> _candles = const [];
  List<ChartSignal> _signals = const [];
  double? _price;
  int _direction = 0;
  double? _change24h;
  Object? _error;
  bool _loading = true;
  bool _polling = false;
  int _failures = 0;

  StreamSubscription<LiveEvent>? _sub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  Timer? _signalTimer;
  Timer? _emitTimer;
  Timer? _watchdog;
  bool _emitDirty = false;
  bool _pollBusy = false;

  @override
  LiveChartState build() {
    final binding = WidgetsBinding.instance;
    final life = binding.lifecycleState;
    _appForeground = life == null || _isForeground(life);
    _tabVisible = ref.read(homeTabProvider) == chartTabIndex;

    _observer = _LifecycleObserver((s) {
      _appForeground = _isForeground(s);
      _sync();
    });
    binding.addObserver(_observer);

    ref.listen<int>(homeTabProvider, (_, tab) {
      _tabVisible = tab == chartTabIndex;
      _sync();
    });

    // Signal strength access depends on the session / role: refetch.
    ref.listen(
      authProvider.select((s) => (s.token, s.member?.role)),
      (_, _) => _onAccessChanged(),
    );

    ref.onDispose(() {
      _disposed = true;
      binding.removeObserver(_observer);
      _stop();
    });

    scheduleMicrotask(_sync);
    return const LiveChartState();
  }

  // `inactive` also happens for system overlays; only real background closes.
  static bool _isForeground(AppLifecycleState s) =>
      s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;

  /// Reloads from scratch (error screen retry button).
  void retry() {
    _stop();
    _sync();
  }

  void _onAccessChanged() {
    if (_disposed) return;
    _signals = const [];
    if (!_running) return;
    final gen = _gen;
    unawaited(() async {
      final fresh = await _fetchSignals();
      if (gen != _gen || fresh == null) return;
      _signals = fresh;
      _emitNow();
    }());
  }

  void _sync() {
    if (_disposed) return;
    final wantLive = _tabVisible && _appForeground;
    if (wantLive && !_running) {
      _start();
    } else if (!wantLive && _running) {
      _stop();
    }
  }

  Future<void> _start() async {
    _running = true;
    final gen = ++_gen;
    final api = ref.read(binanceKlinesApiProvider);

    if (_candles.isEmpty) {
      _loading = true;
      _error = null;
      _emitNow();
    }

    final signalsFuture = _fetchSignals();
    try {
      final fetched = await api.fetchKlines(
        symbol: params.coin.symbol,
        marketType: params.coin.marketType,
        timeframe: params.timeframe,
      );
      if (gen != _gen) return;
      _candles = fetched;
      _setPrice(fetched.isEmpty ? null : fetched.last.close);
      _loading = false;
      _error = null;
      // Draw the candles right away; signals are merged in when they arrive.
      _emitNow();
    } catch (e) {
      if (gen != _gen) return;
      _loading = false;
      if (_candles.isEmpty) {
        _error = e;
        _emitNow();
        return;
      }
      // Keep showing the previous candles; the stream refreshes them.
    }

    _connect(gen);
    _startSignalTimer(gen);

    final signals = await signalsFuture;
    if (gen != _gen) return;
    if (signals != null) _signals = mergeSignals(_signals, signals);
    _emitNow();
  }

  void _stop() {
    _running = false;
    _gen++;
    _sub?.cancel();
    _sub = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _signalTimer?.cancel();
    _signalTimer = null;
    _emitTimer?.cancel();
    _emitTimer = null;
    _watchdog?.cancel();
    _watchdog = null;
    _emitDirty = false;
    _pollBusy = false;
    _failures = 0;
    _polling = false;
  }

  // --- WebSocket -----------------------------------------------------------

  void _connect(int gen) {
    if (gen != _gen) return;
    _sub?.cancel();
    final Stream<LiveEvent> stream;
    try {
      stream = ref
          .read(klineStreamProvider)
          .connect(
            marketType: params.coin.marketType,
            symbol: params.coin.symbol,
            timeframe: params.timeframe,
          );
    } catch (_) {
      _onLost(gen);
      return;
    }
    _armWatchdog(gen);
    _sub = stream.listen(
      (event) => _onEvent(gen, event),
      onError: (Object _) => _onLost(gen),
      onDone: () => _onLost(gen),
      cancelOnError: true,
    );
  }

  void _armWatchdog(int gen) {
    _watchdog?.cancel();
    _watchdog = Timer(streamSilenceTimeout, () => _onLost(gen));
  }

  void _onEvent(int gen, LiveEvent event) {
    if (gen != _gen) return;
    _armWatchdog(gen);
    if (_failures > 0 || _polling) _onRecovered(gen);

    switch (event) {
      case KlineUpdate():
        _candles = applyKlineUpdate(_candles, event);
        _setPrice(event.close);
      case TickerUpdate():
        _change24h = event.changePercent ?? _change24h;
    }
    _requestEmit();
  }

  /// First message after a failure: leave polling, fill any gap via REST.
  void _onRecovered(int gen) {
    _failures = 0;
    final wasPolling = _polling;
    _polling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (wasPolling) _requestEmit();
    unawaited(_resync(gen));
  }

  Future<void> _resync(int gen) async {
    try {
      final fetched = await ref
          .read(binanceKlinesApiProvider)
          .fetchKlines(
            symbol: params.coin.symbol,
            marketType: params.coin.marketType,
            timeframe: params.timeframe,
          );
      if (gen != _gen || fetched.isEmpty) return;
      // Keep anything the stream delivered meanwhile that is newer.
      var merged = fetched;
      for (final c in _candles) {
        if (c.openTime > merged.last.openTime) merged = [...merged, c];
      }
      _candles = merged;
      _requestEmit();
    } catch (_) {
      // The live stream keeps the last candle fresh anyway.
    }
  }

  void _onLost(int gen) {
    if (gen != _gen || !_running) return;
    _watchdog?.cancel();
    _watchdog = null;
    _sub?.cancel();
    _sub = null;
    final attempt = _failures;
    _failures++;
    if (_failures >= pollingFailureThreshold && !_polling) _startPolling(gen);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(nextBackoff(attempt), () => _connect(gen));
  }

  // --- REST polling fallback -------------------------------------------------

  void _startPolling(int gen) {
    _polling = true;
    _requestEmit();
    unawaited(_poll(gen));
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollingInterval, (_) => _poll(gen));
  }

  Future<void> _poll(int gen) async {
    if (_pollBusy || gen != _gen) return;
    _pollBusy = true;
    try {
      final latest = await ref
          .read(binanceKlinesApiProvider)
          .fetchKlines(
            symbol: params.coin.symbol,
            marketType: params.coin.marketType,
            timeframe: params.timeframe,
            limit: 2,
          );
      if (gen != _gen || !_polling) return;
      for (final c in latest) {
        _candles = applyKlineUpdate(
          _candles,
          KlineUpdate(
            openTime: c.openTime,
            open: c.open,
            high: c.high,
            low: c.low,
            close: c.close,
            isClosed: false,
          ),
        );
      }
      if (latest.isNotEmpty) _setPrice(latest.last.close);
      _requestEmit();
    } catch (_) {
      // Next tick tries again.
    } finally {
      _pollBusy = false;
    }
  }

  // --- Signals ---------------------------------------------------------------

  Future<List<ChartSignal>?> _fetchSignals() async {
    if (!supportsSignals(params.timeframe)) return const [];
    // Signals are a member feature: guests never call the endpoint.
    if (ref.read(authProvider).token == null) return const [];
    try {
      return await ref
          .read(chartSignalApiProvider)
          .fetchSignals(
            coinId: params.coin.id,
            timeframe: params.timeframe,
            token: ref.read(authProvider).token,
          );
    } catch (_) {
      return null;
    }
  }

  void _startSignalTimer(int gen) {
    if (!supportsSignals(params.timeframe)) return;
    _signalTimer?.cancel();
    _signalTimer = Timer.periodic(signalRefreshInterval, (_) async {
      final fresh = await _fetchSignals();
      if (gen != _gen || fresh == null) return;
      _signals = mergeSignals(_signals, fresh);
      _requestEmit();
    });
  }

  // --- State emission --------------------------------------------------------

  void _setPrice(double? p) {
    if (p == null) return;
    final prev = _price;
    if (prev != null && p != prev) _direction = p > prev ? 1 : -1;
    _price = p;
  }

  LiveChartState _snapshot() => LiveChartState(
    loading: _loading,
    error: _error,
    candles: _candles,
    signals: _signals,
    price: _price,
    direction: _direction,
    change24h: _change24h,
    polling: _polling,
  );

  void _emitNow() {
    if (_disposed) return;
    state = _snapshot();
  }

  /// Leading + trailing throttle: at most one UI update per [liveUiThrottle].
  void _requestEmit() {
    if (_disposed) return;
    if (_emitTimer != null) {
      _emitDirty = true;
      return;
    }
    _emitNow();
    _emitTimer = Timer(liveUiThrottle, () {
      _emitTimer = null;
      if (_emitDirty) {
        _emitDirty = false;
        _requestEmit();
      }
    });
  }
}

final liveChartProvider = NotifierProvider.autoDispose
    .family<LiveChartController, LiveChartState, ChartDataParams>(
      LiveChartController.new,
    );
