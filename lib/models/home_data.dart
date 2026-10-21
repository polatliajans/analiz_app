import 'dart:convert';

// Models for `GET /api/home`. Parsing is defensive: every section may be
// missing or null, unknown fields are ignored, and malformed list items are
// dropped instead of failing the whole response.

String? _str(Object? v) {
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  return null;
}

double? _num(Object? v) {
  if (v is num) return v.isFinite ? v.toDouble() : null;
  if (v is String) {
    final d = double.tryParse(v);
    return d != null && d.isFinite ? d : null;
  }
  return null;
}

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.isFinite ? v.round() : null;
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
  return null;
}

bool? _bool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final l = v.toLowerCase();
    if (l == 'true' || l == '1') return true;
    if (l == 'false' || l == '0') return false;
  }
  return null;
}

DateTime? _date(Object? v) {
  final s = _str(v);
  return s == null ? null : DateTime.tryParse(s)?.toUtc();
}

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<T> _items<T>(Object? v, T? Function(Map<String, dynamic>) parse) {
  if (v is! List) return const [];
  final out = <T>[];
  for (final e in v) {
    final m = _map(e);
    if (m == null) continue;
    try {
      final item = parse(m);
      if (item != null) out.add(item);
    } catch (_) {
      // Skip the malformed item only.
    }
  }
  return out;
}

class FearGreed {
  final int value;
  final String? label;
  final int? change7d;

  const FearGreed({required this.value, this.label, this.change7d});

  static FearGreed? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final value = _int(m['value']);
    if (value == null) return null;
    return FearGreed(
      value: value.clamp(0, 100),
      label: _str(m['label']),
      change7d: _int(m['change_7d']),
    );
  }
}

class BtcPulse {
  final double? price;
  final double? change24hPct;

  /// bull | bear | sideways | unknown (anything else is treated as unknown).
  final String regime;
  final double? dominancePct;

  const BtcPulse({
    this.price,
    this.change24hPct,
    this.regime = 'unknown',
    this.dominancePct,
  });

  static BtcPulse? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final regime = (_str(m['regime']) ?? 'unknown').toLowerCase();
    return BtcPulse(
      price: _num(m['price']),
      change24hPct: _num(m['change_24h_pct']),
      regime: const {'bull', 'bear', 'sideways'}.contains(regime)
          ? regime
          : 'unknown',
      dominancePct: _num(m['dominance_pct']),
    );
  }
}

class TotalMarketCap {
  final double? usd;
  final double? change24hPct;

  const TotalMarketCap({this.usd, this.change24hPct});

  static TotalMarketCap? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    return TotalMarketCap(
      usd: _num(m['usd']),
      change24hPct: _num(m['change_24h_pct']),
    );
  }
}

class MarketPulse {
  final FearGreed? fearGreed;
  final BtcPulse? btc;
  final TotalMarketCap? totalMarketCap;
  final DateTime? asOf;

  const MarketPulse({this.fearGreed, this.btc, this.totalMarketCap, this.asOf});

  bool get hasAnyData =>
      fearGreed != null ||
      btc?.price != null ||
      btc?.dominancePct != null ||
      totalMarketCap?.usd != null;

  static MarketPulse? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    return MarketPulse(
      fearGreed: FearGreed.tryParse(m['fear_greed']),
      btc: BtcPulse.tryParse(m['btc']),
      totalMarketCap: TotalMarketCap.tryParse(m['total_market_cap']),
      asOf: _date(m['as_of']),
    );
  }
}

class HomeEvent {
  final String name;
  final DateTime? dateUtc;
  final double? hoursUntil;

  /// high | medium (anything else is treated as medium).
  final String importance;

  const HomeEvent({
    required this.name,
    this.dateUtc,
    this.hoursUntil,
    this.importance = 'medium',
  });

  bool get isHigh => importance == 'high';

  static HomeEvent? tryParse(Map<String, dynamic> m) {
    final name = _str(m['name']);
    if (name == null) return null;
    return HomeEvent(
      name: name,
      dateUtc: _date(m['date_utc']),
      hoursUntil: _num(m['hours_until']),
      importance: _str(m['importance'])?.toLowerCase() == 'high'
          ? 'high'
          : 'medium',
    );
  }
}

class HomeRadarSignal {
  final int? coinId;
  final String symbol;
  final String marketType;
  final String timeframe;

  /// buy | sell
  final String direction;
  final int strength;
  final DateTime? at;

  const HomeRadarSignal({
    this.coinId,
    required this.symbol,
    this.marketType = 'spot',
    required this.timeframe,
    required this.direction,
    this.strength = 1,
    this.at,
  });

  bool get isBuy => direction == 'buy';

  static HomeRadarSignal? tryParse(Map<String, dynamic> m) {
    final symbol = _str(m['symbol']);
    final timeframe = _str(m['timeframe']);
    final dir = _str(m['direction'])?.toLowerCase();
    if (symbol == null || timeframe == null) return null;
    if (dir != 'buy' && dir != 'sell') return null;
    return HomeRadarSignal(
      coinId: _int(m['coin_id']),
      symbol: symbol,
      marketType: _str(m['market_type']) ?? 'spot',
      timeframe: timeframe,
      direction: dir!,
      strength: (_int(m['strength']) ?? 1).clamp(1, 3),
      at: _date(m['at']),
    );
  }
}

class HomeMover {
  final int? coinId;
  final String symbol;
  final String marketType;
  final double? price;
  final double? change24hPct;

  const HomeMover({
    this.coinId,
    required this.symbol,
    this.marketType = 'spot',
    this.price,
    this.change24hPct,
  });

  static HomeMover? tryParse(Map<String, dynamic> m) {
    final symbol = _str(m['symbol']);
    if (symbol == null) return null;
    return HomeMover(
      coinId: _int(m['coin_id']),
      symbol: symbol,
      marketType: _str(m['market_type']) ?? 'spot',
      price: _num(m['price']),
      change24hPct: _num(m['change_24h_pct']),
    );
  }
}

class HomeLastAnalysis {
  final int? id;
  final int? coinId;
  final String symbol;
  final String marketType;
  final String? timeframe;

  /// bullish | bearish | neutral (anything else is treated as neutral).
  final String bias;
  final int? confidence;
  final String? kisaca;
  final DateTime? generatedAt;
  final bool cached;

  const HomeLastAnalysis({
    this.id,
    this.coinId,
    required this.symbol,
    this.marketType = 'spot',
    this.timeframe,
    this.bias = 'neutral',
    this.confidence,
    this.kisaca,
    this.generatedAt,
    this.cached = false,
  });

  static HomeLastAnalysis? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    final symbol = _str(m['symbol']);
    if (symbol == null) return null;
    final bias = (_str(m['bias']) ?? 'neutral').toLowerCase();
    return HomeLastAnalysis(
      id: _int(m['id']),
      coinId: _int(m['coin_id']),
      symbol: symbol,
      marketType: _str(m['market_type']) ?? 'spot',
      timeframe: _str(m['timeframe']),
      bias: const {'bullish', 'bearish'}.contains(bias) ? bias : 'neutral',
      confidence: _int(m['confidence'])?.clamp(0, 100),
      kisaca: _str(m['kisaca']),
      generatedAt: _date(m['generated_at']),
      cached: _bool(m['cached']) ?? false,
    );
  }
}

class HomeCredits {
  final int? balance;
  final bool isPro;

  const HomeCredits({this.balance, this.isPro = false});

  static HomeCredits? tryParse(Object? json) {
    final m = _map(json);
    if (m == null) return null;
    return HomeCredits(
      balance: _int(m['balance']),
      isPro: _bool(m['is_pro']) ?? false,
    );
  }
}

class HomeData {
  final DateTime? generatedAt;
  final MarketPulse? market;

  /// True when the server says its market snapshot was too old to serve.
  final bool marketStale;
  final List<HomeEvent> events;
  final List<HomeRadarSignal> radar;
  final List<HomeMover> movers;
  final HomeLastAnalysis? lastAnalysis;
  final HomeCredits? credits;

  const HomeData({
    this.generatedAt,
    this.market,
    this.marketStale = false,
    this.events = const [],
    this.radar = const [],
    this.movers = const [],
    this.lastAnalysis,
    this.credits,
  });

  static const empty = HomeData();

  /// Parses an already decoded JSON value; anything unexpected yields an empty
  /// [HomeData] (or empty sections) rather than throwing.
  factory HomeData.fromJson(Object? json) {
    final m = _map(json);
    if (m == null) return HomeData.empty;
    return HomeData(
      generatedAt: _date(m['generated_at']),
      market: MarketPulse.tryParse(m['market']),
      marketStale: _bool(m['stale']) ?? false,
      events: _items(m['events'], HomeEvent.tryParse).take(5).toList(),
      radar: _items(m['radar'], HomeRadarSignal.tryParse).take(5).toList(),
      movers: _items(m['movers'], HomeMover.tryParse).take(5).toList(),
      lastAnalysis: HomeLastAnalysis.tryParse(m['last_analysis']),
      credits: HomeCredits.tryParse(m['credits']),
    );
  }

  /// Parses a raw response body. Throws [FormatException] when the body is not
  /// a JSON object at all (the caller then treats the refresh as failed).
  factory HomeData.fromBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Home response is not a JSON object');
    }
    return HomeData.fromJson(decoded);
  }
}
