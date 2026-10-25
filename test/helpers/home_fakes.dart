import 'dart:async';
import 'dart:convert';

import 'package:kriptoanaliz/data/analysis_history_api.dart';
import 'package:kriptoanaliz/data/coin_api.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/models/home_data.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';

/// "Now" used by the home tests.
final homeTestNow = DateTime.utc(2026, 10, 21, 10, 0);

Map<String, dynamic> fullHomeJson() => {
  'generated_at': '2026-10-21T10:00:00Z',
  'market': {
    'fear_greed': {'value': 53, 'label': 'Neutral', 'change_7d': -8},
    'btc': {
      'price': 82000.0,
      'change_24h_pct': 1.02,
      'regime': 'bull',
      'dominance_pct': 60.2,
    },
    'total_market_cap': {'usd': 2738271923149, 'change_24h_pct': 0.77},
    'as_of': '2026-10-21T09:55:00Z',
  },
  'events': [
    {
      'name': 'FOMC rate decision + statement',
      'date_utc': '2026-10-28T18:00:00Z',
      'hours_until': 176.0,
      'importance': 'high',
    },
    {
      'name': 'CPI release',
      'date_utc': '2026-10-22T12:30:00Z',
      'hours_until': 26.5,
      'importance': 'medium',
    },
  ],
  'radar': [
    {
      'coin_id': 7,
      'symbol': 'ETHUSDT',
      'market_type': 'spot',
      'timeframe': '4h',
      'direction': 'buy',
      'strength': 2,
      'at': '2026-10-21T09:30:00Z',
    },
    {
      'coin_id': 8,
      'symbol': 'SOLUSDT',
      'market_type': 'futures',
      'timeframe': '1h',
      'direction': 'sell',
      'strength': 3,
      'at': '2026-10-21T08:00:00Z',
    },
  ],
  'movers': [
    {
      'coin_id': 1,
      'symbol': 'BTCUSDT',
      'market_type': 'spot',
      'price': 82000.0,
      'change_24h_pct': 1.02,
    },
    {
      'coin_id': 9,
      'symbol': 'DOGEUSDT',
      'market_type': 'spot',
      'price': 0.1534,
      'change_24h_pct': -4.5,
    },
  ],
  'market_movers': marketMoversJson(),
  'last_analysis': {
    'id': 12,
    'coin_id': 1,
    'symbol': 'SUIUSDT',
    'market_type': 'futures',
    'timeframe': '4h',
    'bias': 'bearish',
    'confidence': 54,
    'kisaca': 'Short-term pressure remains downward.',
    'generated_at': '2026-10-21T08:00:00Z',
    'cached': true,
  },
  'credits': {'balance': 80, 'is_pro': false},
};

Map<String, dynamic> mover(
  String symbol,
  double change, {
  int? id,
  double price = 1.5,
  double volume = 1200000000,
  String market = 'spot',
}) => {
  'coin_id': id ?? symbol.hashCode.abs() % 10000,
  'symbol': symbol,
  'market_type': market,
  'price': price,
  'change_24h_pct': change,
  'quote_volume_usd': volume,
};

/// Exchange-wide lists: 7 gainers, 7 losers, 7 volume rows (more than the 5
/// shown by default).
Map<String, dynamic> marketMoversJson() => {
  'gainers': [
    for (var i = 0; i < 7; i++)
      mover('GAIN${i}USDT', 20.0 - i, id: 100 + i, price: 2.0 + i),
  ],
  'losers': [
    for (var i = 0; i < 7; i++)
      mover('LOSE${i}USDT', -10.0 - i, id: 200 + i, price: 3.0 + i),
  ],
  'volume': [
    mover('BTCUSDT', 1.0, id: 1, price: 82000, volume: 1.2e9),
    mover('ETHUSDT', 0.5, id: 7, price: 3000, volume: 345e6),
    for (var i = 0; i < 5; i++)
      mover('VOL${i}USDT', 0.1 * i, id: 300 + i, volume: 12.3e6 - i * 1e6),
  ],
};

Map<String, dynamic> emptyHomeJson() => {
  'generated_at': '2026-10-21T10:00:00Z',
  'market': null,
  'events': <dynamic>[],
  'radar': <dynamic>[],
  'movers': <dynamic>[],
  'last_analysis': null,
  'credits': {'balance': 5, 'is_pro': false},
};

HomeResponse homeResponse(Map<String, dynamic> json) {
  final body = jsonEncode(json);
  return HomeResponse(HomeData.fromBody(body), body);
}

/// Fake HomeApi whose behaviour is set per test.
class FakeHomeApi extends HomeApi {
  int calls = 0;
  String? lastToken;
  Future<HomeResponse> Function() handler;

  FakeHomeApi(this.handler);

  /// Calls of the public (token-less) variant used by guests.
  int publicCalls = 0;
  Future<HomeResponse> Function()? publicHandler;

  @override
  Future<HomeResponse> fetch(String token) {
    calls++;
    lastToken = token;
    return handler();
  }

  @override
  Future<HomeResponse> fetchPublic() {
    publicCalls++;
    return (publicHandler ?? handler)();
  }
}

class MutableClock {
  DateTime now;
  MutableClock(this.now);
  DateTime call() => now;
}

const testMember = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'user',
  creditBalance: 80,
);

class FakeAuth extends AuthNotifier {
  final Member? member;
  FakeAuth([this.member = testMember]);

  @override
  AuthState build() => member == null
      ? const AuthState()
      : AuthState(token: 'tok', member: member);
}

class FakeCoinApi extends CoinApi {
  final List<Coin> coins;
  FakeCoinApi(this.coins);

  @override
  Future<List<Coin>> fetchCoins({String? marketType}) async => coins
      .where((c) => marketType == null || c.marketType == marketType)
      .toList();
}

Coin testCoin(int id, String symbol, [String market = 'spot']) => Coin(
  id: id,
  symbol: symbol,
  name: symbol,
  marketType: market,
  lastPrice: 1,
  priceChangePercent24h: 0,
  volume24h: 1,
);

class FakeHistoryApi extends AnalysisHistoryApi {
  final List<AnalysisRecord> records;
  FakeHistoryApi(this.records);

  @override
  Future<List<AnalysisRecord>> fetch(String token, {int? coinId}) async =>
      records;
}

Completer<HomeResponse> pendingResponse() => Completer<HomeResponse>();
