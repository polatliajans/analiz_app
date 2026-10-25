import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_api.dart';
import '../models/home_data.dart';
import '../utils/stable_pairs.dart';
import 'home_provider.dart';
import 'live_tickers_provider.dart';

/// Pairs below this 24h USDT turnover are ignored for the gainers / losers
/// lists (illiquid listings otherwise dominate them).
const guestMinQuoteVolume = 5000000.0;

final _leveragedToken = RegExp(r'(UP|DOWN|BULL|BEAR)USDT$');

/// Builds the public part of the home page (BTC pulse and exchange-wide
/// movers) from the Binance spot 24h ticker. Used for guests, for whom the
/// member-only `/home` endpoint is unavailable. Null when nothing usable.
HomeData? buildGuestMarket(Map<String, TickerQuote> quotes) {
  final btc = quotes['BTCUSDT'];
  final rows = <MarketMover>[];
  quotes.forEach((symbol, q) {
    if (!symbol.endsWith('USDT') || symbol.length <= 4) return;
    if (isStablePair(symbol) || _leveragedToken.hasMatch(symbol)) return;
    if (q.lastPrice <= 0) return;
    rows.add(
      MarketMover(
        symbol: symbol,
        price: q.lastPrice,
        change24hPct: q.changePercent,
        quoteVolumeUsd: q.quoteVolume,
      ),
    );
  });

  List<MarketMover> top(
    Iterable<MarketMover> list,
    int Function(MarketMover a, MarketMover b) cmp,
  ) => (list.toList()..sort(cmp)).take(MarketMovers.maxPerList).toList();

  final liquid = rows.where(
    (r) => (r.quoteVolumeUsd ?? 0) >= guestMinQuoteVolume,
  );
  final movers = MarketMovers(
    gainers: top(liquid, (a, b) => b.change24hPct!.compareTo(a.change24hPct!)),
    losers: top(liquid, (a, b) => a.change24hPct!.compareTo(b.change24hPct!)),
    volume: top(
      rows,
      (a, b) => (b.quoteVolumeUsd ?? 0).compareTo(a.quoteVolumeUsd ?? 0),
    ),
  );
  final market = btc == null
      ? null
      : MarketPulse(
          btc: BtcPulse(price: btc.lastPrice, change24hPct: btc.changePercent),
        );
  if (market == null && movers.isEmpty) return null;
  return HomeData(market: market, marketMovers: movers.isEmpty ? null : movers);
}

/// Whether a public `/home` payload has something worth showing.
bool hasPublicHomeContent(HomeData d) =>
    d.market != null ||
    d.radar.isNotEmpty ||
    d.events.isNotEmpty ||
    !(d.marketMovers?.isEmpty ?? true);

/// Data for the guest home: the public `/home` endpoint (same sections as the
/// signed-in page), falling back to the exchange ticker when the endpoint is
/// unavailable (old server answering 401, offline, empty payload). Throws only
/// when both fail so the screen can offer a retry.
final guestHomeProvider = FutureProvider.autoDispose<HomeData?>((ref) async {
  try {
    final r = await ref.read(homeApiProvider).fetchPublic();
    if (hasPublicHomeContent(r.data)) return r.data;
  } catch (_) {
    // Fall through to the ticker.
  }
  return ref.read(guestMarketProvider.future);
}, retry: (_, _) => null);

/// Market data built from the Binance ticker: the automatic fallback of
/// [guestHomeProvider]. Throws when the ticker cannot be fetched.
final guestMarketProvider = FutureProvider.autoDispose<HomeData?>(
  (ref) async {
    final quotes = await ref.read(tickerApiProvider).fetchAll('spot');
    return buildGuestMarket(quotes);
  },
  // The screen offers its own retry button; no silent back-off loop.
  retry: (_, _) => null,
);
