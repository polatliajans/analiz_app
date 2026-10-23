import 'dart:convert';

// Defensive models of `GET /api/coins/{coin}/overview`. Every field is
// nullable and parsing never throws: missing, renamed-by-alias or garbage
// values simply become null so a tab can hide the row or show its empty state.

double? _num(Object? v) {
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is String) {
    final d = double.tryParse(v.trim());
    return (d != null && d.isFinite) ? d : null;
  }
  return null;
}

int? _int(Object? v) => _num(v)?.round();

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

bool? _bool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.trim().toLowerCase();
    if (t == 'true' || t == '1') return true;
    if (t == 'false' || t == '0') return false;
  }
  return null;
}

DateTime? _date(Object? v) {
  if (v is! String) return null;
  return DateTime.tryParse(v.trim())?.toLocal();
}

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// First non-null value among [keys] in [m] (aliases for the same field).
Object? _pick(Map<String, dynamic>? m, List<String> keys) {
  if (m == null) return null;
  for (final k in keys) {
    final v = m[k];
    if (v != null) return v;
  }
  return null;
}

double? _pickNum(Map<String, dynamic>? m, List<String> keys) =>
    _num(_pick(m, keys));

/// Looks [keys] up in each map in turn (nested group first, flat after).
double? _pickNumIn(Iterable<Map<String, dynamic>?> maps, List<String> keys) {
  for (final m in maps) {
    final v = _pickNum(m, keys);
    if (v != null) return v;
  }
  return null;
}

/// All-time high / low: price, when it happened and the distance of the
/// current price from it (percent; negative below the ATH).
class PriceExtreme {
  final double? price;
  final DateTime? date;
  final double? distancePct;

  const PriceExtreme({this.price, this.date, this.distancePct});

  bool get isEmpty => price == null && date == null && distancePct == null;

  static PriceExtreme? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final e = PriceExtreme(
      price: _pickNum(m, const ['price', 'value']),
      date: _date(_pick(m, const ['date', 'at', 'time'])),
      distancePct: _pickNum(m, const [
        'distance_pct',
        'distance_percent',
        'pct_from_current',
        'change_pct',
        'distance',
      ]),
    );
    return e.isEmpty ? null : e;
  }
}

class OverviewSummary {
  final String? name;
  final String? symbol;
  final int? rank;
  final double? marketCap;
  final double? fdv;
  final double? volume24h;
  final double? volumeMarketCapRatio;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final bool? hasMaxSupply;
  final double? _circulatingPctOfMax;
  final double? change24h;
  final double? change7d;
  final double? change30d;
  final double? change90d;
  final PriceExtreme? ath;
  final PriceExtreme? atl;
  final String? category;
  final List<String> tags;
  final String? platform;
  final int? ageDays;
  final int? listingAgeDays;
  final bool newListing;
  final List<String> sources;

  const OverviewSummary({
    this.name,
    this.symbol,
    this.rank,
    this.marketCap,
    this.fdv,
    this.volume24h,
    this.volumeMarketCapRatio,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.hasMaxSupply,
    double? circulatingPctOfMax,
    this.change24h,
    this.change7d,
    this.change30d,
    this.change90d,
    this.ath,
    this.atl,
    this.category,
    this.tags = const [],
    this.platform,
    this.ageDays,
    this.listingAgeDays,
    this.newListing = false,
    this.sources = const [],
  }) : _circulatingPctOfMax = circulatingPctOfMax;

  /// Circulating supply as percent of the max supply; null without a max.
  double? get circulatingPctOfMax {
    if (hasMaxSupply == false) return null;
    final given = _circulatingPctOfMax;
    if (given != null) return given.clamp(0.0, 100.0);
    final max = maxSupply;
    final circ = circulatingSupply;
    if (max == null || max <= 0 || circ == null) return null;
    return (circ / max * 100).clamp(0.0, 100.0);
  }

  bool get showsSupplyProgress =>
      (hasMaxSupply ?? maxSupply != null) && circulatingPctOfMax != null;

  List<double?> get changes => [change24h, change7d, change30d, change90d];

  bool get isEmpty =>
      name == null &&
      rank == null &&
      marketCap == null &&
      fdv == null &&
      volume24h == null &&
      volumeMarketCapRatio == null &&
      circulatingSupply == null &&
      totalSupply == null &&
      maxSupply == null &&
      changes.every((c) => c == null) &&
      ath == null &&
      atl == null &&
      category == null &&
      tags.isEmpty &&
      platform == null &&
      ageDays == null &&
      listingAgeDays == null &&
      !newListing;

  static OverviewSummary? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final supply = _map(_pick(m, const ['supply']));
    final changes = _map(
      _pick(m, const ['changes', 'price_change', 'percent_change']),
    );
    final both = [changes, m];
    final tags = _pick(m, const ['tags']);
    final sources = _pick(m, const ['sources', 'data_sources']);
    final maxSupply = _pickNumIn([supply, m], const ['max', 'max_supply']);
    final s = OverviewSummary(
      name: _str(m['name']),
      symbol: _str(m['symbol']),
      rank: _int(_pick(m, const ['rank', 'cmc_rank', 'market_cap_rank'])),
      marketCap: _pickNum(m, const ['market_cap', 'marketcap']),
      fdv: _pickNum(m, const [
        'fdv',
        'fully_diluted_market_cap',
        'fully_diluted_valuation',
      ]),
      volume24h: _pickNum(m, const ['volume_24h', 'volume24h']),
      volumeMarketCapRatio: _pickNum(m, const [
        'volume_market_cap_ratio',
        'volume_to_market_cap',
        'volume_mcap_ratio',
        'vol_mcap',
      ]),
      circulatingSupply: _pickNumIn(
        [supply, m],
        const ['circulating', 'circulating_supply'],
      ),
      totalSupply: _pickNumIn([supply, m], const ['total', 'total_supply']),
      maxSupply: maxSupply,
      hasMaxSupply: _bool(
        _pick(supply, const ['has_max_supply']) ?? m['has_max_supply'],
      ),
      circulatingPctOfMax: _pickNumIn(
        [supply, m],
        const ['circulating_pct_of_max', 'circulating_percent_of_max'],
      ),
      change24h: _pickNumIn(both, const [
        '24h',
        'pct_24h',
        'change_24h',
        'change_24h_pct',
        'percent_change_24h',
      ]),
      change7d: _pickNumIn(both, const [
        '7d',
        'pct_7d',
        'change_7d',
        'change_7d_pct',
        'percent_change_7d',
      ]),
      change30d: _pickNumIn(both, const [
        '30d',
        'pct_30d',
        'change_30d',
        'change_30d_pct',
        'percent_change_30d',
      ]),
      change90d: _pickNumIn(both, const [
        '90d',
        'pct_90d',
        'change_90d',
        'change_90d_pct',
        'percent_change_90d',
      ]),
      ath: PriceExtreme.tryParse(_pick(m, const ['ath', 'all_time_high'])),
      atl: PriceExtreme.tryParse(_pick(m, const ['atl', 'all_time_low'])),
      category: _str(m['category']),
      tags: tags is List
          ? [
              for (final t in tags)
                if (_str(t) != null) _str(t)!,
            ]
          : const [],
      platform: _str(_pick(m, const ['platform', 'chain'])),
      ageDays: _int(_pick(m, const ['age_days', 'coin_age_days'])),
      listingAgeDays: _int(_pick(m, const ['listing_age_days', 'listed_days'])),
      newListing:
          _bool(_pick(m, const ['new_listing', 'is_new_listing'])) ?? false,
      sources: sources is List
          ? [
              for (final t in sources)
                if (_str(t) != null) _str(t)!,
            ]
          : const [],
    );
    return s.isEmpty ? null : s;
  }
}

/// Futures-only metrics. Ratios are plain numbers (1.0 = balanced).
class FuturesMetrics {
  /// Funding rate in percent per funding interval (0.01 = 0.01%).
  final double? fundingRatePct;

  /// Where the current funding sits in its recent history, 0..100.
  final double? fundingPercentile;
  final double? oiChange1h;
  final double? oiChange4h;
  final double? oiChange24h;
  final double? oiChange7d;

  /// Share of long accounts/positions, 0..100.
  final double? longSharePct;
  final double? longShortRatio;
  final double? topTraderRatio;

  /// Taker buy volume divided by taker sell volume.
  final double? takerBuySell1h;
  final double? takerBuySell24h;

  /// Futures premium over spot in percent.
  final double? basisPct;

  const FuturesMetrics({
    this.fundingRatePct,
    this.fundingPercentile,
    this.oiChange1h,
    this.oiChange4h,
    this.oiChange24h,
    this.oiChange7d,
    this.longSharePct,
    this.longShortRatio,
    this.topTraderRatio,
    this.takerBuySell1h,
    this.takerBuySell24h,
    this.basisPct,
  });

  bool get isEmpty =>
      fundingRatePct == null &&
      fundingPercentile == null &&
      oiChange1h == null &&
      oiChange4h == null &&
      oiChange24h == null &&
      oiChange7d == null &&
      longSharePct == null &&
      longShortRatio == null &&
      topTraderRatio == null &&
      takerBuySell1h == null &&
      takerBuySell24h == null &&
      basisPct == null;

  /// Fractions (<= 1) are scaled to percent.
  static double? _share(double? v) =>
      v == null ? null : (v >= 0 && v <= 1 ? v * 100 : v).clamp(0.0, 100.0);

  static FuturesMetrics? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final funding = _map(m['funding']);
    final oi = _map(_pick(m, const ['oi_change', 'open_interest_change']));
    final taker = _map(_pick(m, const ['taker', 'taker_buy_sell']));
    final ratio = _pickNumIn(
      [funding, m],
      const ['rate_pct', 'funding_rate_pct'],
    );
    // `funding_rate` is the raw exchange fraction (0.0001 = 0.01%).
    final raw = _pickNumIn([funding, m], const ['rate', 'funding_rate']);
    final f = FuturesMetrics(
      fundingRatePct: ratio ?? (raw == null ? null : raw * 100),
      fundingPercentile: _pickNumIn(
        [funding, m],
        const ['percentile', 'funding_percentile'],
      )?.clamp(0.0, 100.0),
      oiChange1h: _pickNumIn([oi, m], const ['1h', 'oi_change_1h']),
      oiChange4h: _pickNumIn([oi, m], const ['4h', 'oi_change_4h']),
      oiChange24h: _pickNumIn([oi, m], const ['24h', 'oi_change_24h']),
      oiChange7d: _pickNumIn([oi, m], const ['7d', 'oi_change_7d']),
      longSharePct: _share(
        _pickNum(m, const [
          'long_share',
          'long_share_pct',
          'long_account_pct',
          'long_pct',
        ]),
      ),
      longShortRatio: _pickNum(m, const ['long_short_ratio', 'ls_ratio']),
      topTraderRatio: _pickNum(m, const [
        'top_trader_ratio',
        'top_trader_long_short_ratio',
      ]),
      takerBuySell1h: _pickNumIn(
        [taker, m],
        const ['1h', 'taker_buy_sell_1h', 'taker_ratio_1h'],
      ),
      takerBuySell24h: _pickNumIn(
        [taker, m],
        const ['24h', 'taker_buy_sell_24h', 'taker_ratio_24h'],
      ),
      basisPct: _pickNum(m, const ['basis_pct', 'basis', 'basis_percent']),
    );
    return f.isEmpty ? null : f;
  }
}

/// One order book band (e.g. within 1% of the mid price).
class DepthBand {
  final double bandPct;
  final double? bidUsd;
  final double? askUsd;

  const DepthBand({required this.bandPct, this.bidUsd, this.askUsd});

  /// (bid - ask) / (bid + ask) in -1..1; null when unknown or empty.
  double? get imbalance {
    final b = bidUsd, a = askUsd;
    if (b == null || a == null || b < 0 || a < 0 || b + a <= 0) return null;
    return (b - a) / (b + a);
  }

  static DepthBand? tryParse(Object? json, [double? keyed]) {
    final m = _map(json);
    if (m == null) return null;
    final band = _pickNum(m, const ['band_pct', 'band', 'pct']) ?? keyed;
    if (band == null) return null;
    final bid = _pickNum(m, const ['bid_usd', 'bid', 'bids']);
    final ask = _pickNum(m, const ['ask_usd', 'ask', 'asks']);
    if (bid == null && ask == null) return null;
    return DepthBand(bandPct: band, bidUsd: bid, askUsd: ask);
  }
}

class LiquidityMetrics {
  final double? spreadBps;
  final List<DepthBand> depth;

  const LiquidityMetrics({this.spreadBps, this.depth = const []});

  bool get isEmpty => spreadBps == null && depth.isEmpty;

  static LiquidityMetrics? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final raw = _pick(m, const ['depth', 'depth_bands']);
    final bands = <DepthBand>[];
    if (raw is List) {
      for (final e in raw) {
        final b = DepthBand.tryParse(e);
        if (b != null) bands.add(b);
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final key = double.tryParse('$k'.replaceAll('%', '').trim());
        final b = DepthBand.tryParse(v, key);
        if (b != null) bands.add(b);
      });
    }
    bands.sort((a, b) => a.bandPct.compareTo(b.bandPct));
    final l = LiquidityMetrics(
      spreadBps: _pickNum(m, const ['spread_bps', 'spread']),
      depth: bands,
    );
    return l.isEmpty ? null : l;
  }
}

class ActivityMetrics {
  final double? volume24h;
  final int? trades24h;
  final int? volumeRank;
  final int? volumeRankTotal;

  const ActivityMetrics({
    this.volume24h,
    this.trades24h,
    this.volumeRank,
    this.volumeRankTotal,
  });

  bool get isEmpty =>
      volume24h == null &&
      trades24h == null &&
      volumeRank == null &&
      volumeRankTotal == null;

  static ActivityMetrics? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final a = ActivityMetrics(
      volume24h: _pickNum(m, const ['volume_24h', 'quote_volume_24h']),
      trades24h: _int(_pick(m, const ['trades_24h', 'trade_count_24h'])),
      volumeRank: _int(_pick(m, const ['volume_rank', 'rank'])),
      volumeRankTotal: _int(
        _pick(m, const ['volume_rank_total', 'rank_total', 'total']),
      ),
    );
    return a.isEmpty ? null : a;
  }
}

class OverviewMarket {
  /// "spot" or "futures" as seen by the server; null when not given.
  final String? marketType;
  final FuturesMetrics? futures;
  final LiquidityMetrics? liquidity;
  final ActivityMetrics? activity;

  const OverviewMarket({
    this.marketType,
    this.futures,
    this.liquidity,
    this.activity,
  });

  bool get isEmpty => futures == null && liquidity == null && activity == null;

  static OverviewMarket? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final market = OverviewMarket(
      marketType: _str(_pick(m, const ['market_type', 'type'])),
      futures: FuturesMetrics.tryParse(
        _pick(m, const ['futures', 'derivatives']),
      ),
      liquidity: LiquidityMetrics.tryParse(m['liquidity']),
      activity: ActivityMetrics.tryParse(m['activity']),
    );
    return market.isEmpty ? null : market;
  }
}

class CoinOverview {
  final OverviewSummary? summary;
  final OverviewMarket? market;
  final DateTime? generatedAt;

  const CoinOverview({this.summary, this.market, this.generatedAt});

  /// What an old server without the endpoint (or garbage) is treated as.
  static const empty = CoinOverview();

  bool get isEmpty => summary == null && market == null;

  /// Never throws: anything that is not a JSON object parses to [empty].
  factory CoinOverview.parse(Object? json) {
    final root = _map(json);
    if (root == null) return empty;
    // Tolerate a `{ "data": { ... } }` envelope.
    final m = _map(root['data']) ?? root;
    return CoinOverview(
      summary: OverviewSummary.tryParse(m['summary']),
      market: OverviewMarket.tryParse(m['market']),
      generatedAt: _date(m['generated_at']),
    );
  }

  factory CoinOverview.fromBody(String body) {
    try {
      return CoinOverview.parse(jsonDecode(body));
    } catch (_) {
      return empty;
    }
  }
}
