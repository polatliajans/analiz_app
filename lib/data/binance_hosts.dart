import 'dart:async';

import 'package:http/http.dart' as http;

/// Binance blocks some regions (HTTP 451 for US IPs, e.g. App Store review) on
/// its main API hosts. Binance publishes market-data-only hosts for public
/// spot data that are not blocked:
/// https://developers.binance.com/docs/binance-spot-api-docs/faqs/market_data_only
const binanceSpotRestHost = 'api.binance.com';
const binanceSpotRestFallbackHost = 'data-api.binance.vision';
const binanceSpotWsPrimary = 'wss://stream.binance.com:9443';
const binanceSpotWsFallback = 'wss://data-stream.binance.vision';

/// Remembers (per app run) that the primary spot host is unreachable, so the
/// following calls go straight to the market-data-only host instead of
/// waiting for another failure first. Retried after [retryPrimaryAfter].
class BinanceHostState {
  BinanceHostState({
    this.retryPrimaryAfter = const Duration(minutes: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static final BinanceHostState shared = BinanceHostState();

  final Duration retryPrimaryAfter;
  final DateTime Function() _clock;
  DateTime? _primaryFailedAt;

  bool get useFallbackFirst {
    final at = _primaryFailedAt;
    if (at == null) return false;
    if (_clock().difference(at) >= retryPrimaryAfter) {
      _primaryFailedAt = null;
      return false;
    }
    return true;
  }

  void markPrimaryFailed() => _primaryFailedAt = _clock();
  void markPrimaryOk() => _primaryFailedAt = null;
}

/// True for a status that means "this host is not available to you" rather
/// than "your request is wrong": geo block (451/403) or Binance-side outage.
bool isHostBlockedStatus(int status) =>
    status == 451 || status == 403 || status == 418 || status >= 500;

/// GET [path] on the spot REST API. Order: primary host, then (on 451/403/5xx,
/// connection errors or timeouts) the market-data-only host. Throws what the
/// last attempt threw / returns its response.
Future<http.Response> getSpotResilient(
  String path,
  Map<String, String> query, {
  http.Client? client,
  BinanceHostState? state,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final c = client ?? http.Client();
  final s = state ?? BinanceHostState.shared;
  Uri uri(String host) => Uri.https(host, path, query);

  Future<http.Response> call(String host) => c.get(uri(host)).timeout(timeout);

  try {
    if (s.useFallbackFirst) {
      try {
        final r = await call(binanceSpotRestFallbackHost);
        if (!isHostBlockedStatus(r.statusCode)) return r;
      } catch (_) {}
      // Fallback failed too: try the primary once more below.
    }
    try {
      final r = await call(binanceSpotRestHost);
      if (!isHostBlockedStatus(r.statusCode)) {
        s.markPrimaryOk();
        return r;
      }
      s.markPrimaryFailed();
    } catch (_) {
      s.markPrimaryFailed();
    }
    return await call(binanceSpotRestFallbackHost);
  } finally {
    if (client == null) c.close();
  }
}
