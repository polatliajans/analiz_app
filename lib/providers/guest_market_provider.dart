import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_api.dart';
import '../models/home_data.dart';
import '../utils/stable_pairs.dart';
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

/// Market data for the guest home. Throws when the ticker cannot be fetched
/// so the screen can offer a retry.
final guestMarketProvider = FutureProvider.autoDispose<HomeData?>(
  (ref) async {
    final quotes = await ref.read(tickerApiProvider).fetchAll('spot');
    return buildGuestMarket(quotes);
  },
  // The screen offers its own retry button; no silent back-off loop.
  retry: (_, _) => null,
);
