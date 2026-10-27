// Sanitized demo data for the store screenshots (no real accounts).
import 'package:kriptoanaliz/models/home_data.dart';

HomeData homeResponseData(String body) => HomeData.fromBody(body);

Map<String, dynamic> _mv(String s, double chg, double price, int id,
        [double vol = 1e8]) =>
    {
      'coin_id': id,
      'symbol': s,
      'market_type': 'spot',
      'price': price,
      'change_24h_pct': chg,
      'quote_volume_usd': vol,
    };

Map<String, dynamic> homeJson(String lang) {
  final fg = {'en': 'Neutral', 'tr': 'Nötr', 'es': 'Neutral'}[lang];
  return {
    'generated_at': '2026-10-21T10:00:00Z',
    'market': {
      'fear_greed': {'value': 51, 'label': fg, 'change_7d': -4},
      'btc': {
        'price': 80542.8,
        'change_24h_pct': -0.94,
        'regime': 'bull',
        'dominance_pct': 60.2,
      },
      'total_market_cap': {'usd': 2738271923149, 'change_24h_pct': -1.25},
      'as_of': '2026-10-21T09:55:00Z',
    },
    'events': [],
    'radar': [],
    'movers': [],
    'market_movers': {
      'gainers': [
        _mv('SOLUSDT', 8.42, 168.35, 101),
        _mv('AVAXUSDT', 6.15, 34.72, 102),
        _mv('LINKUSDT', 5.38, 17.84, 103),
        _mv('ADAUSDT', 4.77, 0.5821, 104),
        _mv('DOGEUSDT', 4.12, 0.1534, 105),
      ],
      'losers': [
        _mv('XRPUSDT', -3.2, 0.5412, 201),
        _mv('DOTUSDT', -2.9, 4.31, 202),
        _mv('LTCUSDT', -2.4, 71.2, 203),
        _mv('TRXUSDT', -1.8, 0.1612, 204),
        _mv('BCHUSDT', -1.5, 412.6, 205),
      ],
      'volume': [
        _mv('BTCUSDT', -0.94, 80542.8, 1, 1.2e9),
        _mv('ETHUSDT', -1.4, 2310.5, 7, 6.4e8),
        _mv('SOLUSDT', 8.42, 168.35, 101, 3.1e8),
        _mv('XRPUSDT', -3.2, 0.5412, 201, 2.2e8),
        _mv('DOGEUSDT', 4.12, 0.1534, 105, 1.4e8),
      ],
    },
    'last_analysis': null,
    'credits': {'balance': 120, 'is_pro': false},
  };
}
