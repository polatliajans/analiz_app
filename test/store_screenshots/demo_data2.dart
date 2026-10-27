// Sanitized demo data (chart, coin overview, deep analysis, radar) for the
// store screenshots. No real accounts or personal data.

/// Deterministic 4h candles [open, high, low, close]: a spike, a decline and
/// a small bounce ending at [last].
List<List<double>> demoCandles({int n = 90, double last = 80567.3}) {
  final closes = <double>[];
  for (var i = 0; i < n; i++) {
    final t = i / (n - 1);
    double base;
    if (t < 0.28) {
      base = 78400 + (84300 - 78400) * (t / 0.28);
    } else if (t < 0.88) {
      base = 84300 - (84300 - 79500) * ((t - 0.28) / 0.60);
    } else {
      base = 79500 + (last - 79500) * ((t - 0.88) / 0.12);
    }
    final wob = ((i * 37) % 17 - 8) * 55.0;
    closes.add(base + wob);
  }
  closes[n - 1] = last;
  final out = <List<double>>[];
  for (var i = 0; i < n; i++) {
    final open = i == 0 ? closes[0] - 120 : closes[i - 1];
    final c = closes[i];
    final up = ((i * 53) % 11 + 3) * 28.0;
    final dn = ((i * 29) % 13 + 3) * 28.0;
    final hi = (open > c ? open : c) + up;
    final lo = (open < c ? open : c) - dn;
    out.add([open, hi, lo, c]);
  }
  return out;
}

Map<String, dynamic> btcOverview(String lang) {
  final cat = {'en': 'Layer 1', 'tr': 'Katman 1', 'es': 'Capa 1'}[lang];
  return {
    'generated_at': '2026-10-21T10:00:00Z',
    'stale': false,
    'coin': {
      'id': 1,
      'symbol': 'BTCUSDT',
      'market_type': 'spot',
      'base_asset': 'BTC',
    },
    'summary': {
      'name': 'Bitcoin',
      'rank': 1,
      'market_cap_usd': 1620000000000,
      'fully_diluted_market_cap_usd': 1690000000000.0,
      'volume_24h_usd': 23300000000,
      'volume_to_market_cap_pct': 1.4,
      'circulating_supply_pct_of_max': 96.0,
      'has_max_supply': true,
      'change_pct': {'24h': -1.01, '7d': -1.19, '30d': -4.93, '90d': 24.42},
      'category': cat,
      'tags': ['pow', 'store-of-value'],
      'platform': null,
      'date_launched': '2010-07-17',
      'age_days': 6200,
      'ath': {
        'price': 126200,
        'date': '2025-10-06',
        'dist_pct': -36.2,
        'days_since': 380,
      },
      'atl': {'price': 2817, 'date': '2017-09-15', 'dist_pct': 2760},
      'listing_age_days': 3300,
      'new_listing': false,
    },
    'market': {'futures': false},
    'attribution': ['CoinMarketCap', 'Binance'],
  };
}

Map<String, dynamic> ethOverview() => {
  'generated_at': '2026-10-21T10:00:00Z',
  'stale': false,
  'coin': {
    'id': 7,
    'symbol': 'ETHUSDT',
    'market_type': 'futures',
    'base_asset': 'ETH',
  },
  'summary': {
    'name': 'Ethereum',
    'rank': 2,
    'market_cap_usd': 278000000000,
    'volume_24h_usd': 14000000000,
    'volume_to_market_cap_pct': 5.0,
    'has_max_supply': false,
    'change_pct': {'24h': -1.4, '7d': -2.6, '30d': 3.1, '90d': 9.8},
  },
  'market': {
    'futures': true,
    'funding_rate_pct': -0.0059,
    'funding_percentile_90': 2,
    'oi_change_pct': {'1h': -0.15, '4h': -0.68, '24h': -0.96, '7d': 0.90},
    'long_share_pct': 78,
    'long_short_ratio': 3.46,
    'top_trader_position_ls': 1.63,
    'taker_buy_sell_ratio_1h': 0.95,
    'taker_buy_sell_ratio_24h': 0.91,
    'basis_pct': 0.03,
    'liquidity': {
      'spread_bps': 0.8,
      'depth_bands': [
        {
          'window_pct': 1.0,
          'bid_depth_usd': 12000000,
          'ask_depth_usd': 15000000,
          'imbalance_ratio': 0.8,
          'complete': true,
        },
        {
          'window_pct': 2.0,
          'bid_depth_usd': 30000000,
          'ask_depth_usd': 20000000,
          'imbalance_ratio': 1.5,
          'complete': true,
        },
      ],
    },
    'activity': {
      'quote_volume_24h_usd': 14000000000,
      'trades_24h': 3200000,
      'volume_rank': 2,
      'rank_of': 300,
      'rank_scope': 'active futures USDT coins',
    },
  },
  'attribution': ['CoinMarketCap', 'Binance'],
};

Map<String, dynamic> _m(String l, String v, String tone, String h) => {
  'label': l,
  'value': v,
  'tone': tone,
  'hint': h,
};

Map<String, dynamic> deepAnalysis(String lang) {
  final data = <String, Map<String, dynamic>>{
    'en': {
      'horizon': '2 days',
      'metrics': [
        _m('Trend strength', 'ADX 25.5', 'bearish',
            'Downtrend still has measurable force.'),
        _m('Momentum', 'RSI14 29.0', 'bullish',
            'Near oversold; a rebound is possible, not confirmed.'),
        _m('Open candle', '+0.91% (94.3% elapsed)', 'bullish',
            'Strong bounce so far, but not a confirmed close.'),
        _m('24h order flow', 'Taker buy/sell 0.902', 'bearish',
            'Full-day market selling still exceeds market buying.'),
        _m('Long positioning', 'Long accounts 68.7%', 'bearish',
            'Crowding leaves positions vulnerable if price weakens.'),
        _m('BTC seven-day change', '-1.19%', 'bearish',
            'Recent price performance remains negative.'),
        _m('Next FOMC decision', 'About 3.9 days', 'neutral',
            'High-importance event is just beyond the base horizon.'),
      ],
      'summary':
          'Net view: SHORT-biased, confidence 56 - the closed four-hour trend remains downward despite a countertrend rebound.',
    },
    'tr': {
      'horizon': '2 gün',
      'metrics': [
        _m('Trend gücü', 'ADX 25,5', 'bearish',
            'Düşüş trendi hâlâ ölçülebilir bir güce sahip.'),
        _m('Momentum', 'RSI14 29,0', 'bullish',
            'Aşırı satıma yakın; tepki yükselişi mümkün ama henüz teyit yok.'),
        _m('Açık mum', '+%0,91 (%94,3 tamamlandı)', 'bullish',
            'Şimdiye kadar güçlü bir toparlanma var, ancak kapanış henüz teyitli değil.'),
        _m('24 saatlik emir akışı', 'Taker alış/satış 0,902', 'bearish',
            'Gün boyu piyasa satışları, piyasa alışlarını hâlâ aşıyor.'),
        _m('Long pozisyonlanma', 'Long hesaplar %68,7', 'bearish',
            'Kalabalık pozisyonlar, fiyat zayıflarsa risk oluşturur.'),
        _m('BTC yedi günlük değişim', '-%1,19', 'bearish',
            'Son dönem fiyat performansı negatif kalıyor.'),
        _m('Sıradaki FOMC kararı', 'Yaklaşık 3,9 gün', 'neutral',
            'Yüksek önemdeki olay, temel ufkun hemen ötesinde.'),
      ],
      'summary':
          'Net görünüm: SHORT yönlü, güven 56 - kapanmış dört saatlik trend, trende ters bir tepkiye rağmen aşağı yönlü kalıyor.',
    },
    'es': {
      'horizon': '2 días',
      'metrics': [
        _m('Fuerza de la tendencia', 'ADX 25,5', 'bearish',
            'La tendencia bajista aún tiene fuerza medible.'),
        _m('Momento', 'RSI14 29,0', 'bullish',
            'Cerca de sobreventa; un rebote es posible, pero no está confirmado.'),
        _m('Vela abierta', '+0,91 % (94,3 % transcurrido)', 'bullish',
            'Fuerte rebote hasta ahora, pero sin cierre confirmado.'),
        _m('Flujo de órdenes 24 h', 'Taker compra/venta 0,902', 'bearish',
            'Las ventas a mercado de todo el día aún superan a las compras.'),
        _m('Posicionamiento largo', 'Cuentas largas 68,7 %', 'bearish',
            'El exceso de posiciones largas es vulnerable si el precio se debilita.'),
        _m('Cambio de BTC a siete días', '-1,19 %', 'bearish',
            'El rendimiento reciente del precio sigue siendo negativo.'),
        _m('Próxima decisión de la FOMC', 'Unos 3,9 días', 'neutral',
            'Evento de alta importancia justo después del horizonte base.'),
      ],
      'summary':
          'Visión neta: sesgo SHORT, confianza 56: la tendencia cerrada de cuatro horas sigue bajista pese a un rebote contra la tendencia.',
    },
  }[lang]!;
  return {
    'schema_version': 1,
    'symbol': 'BTCUSDT',
    'market_type': 'futures',
    'timeframe': '4h',
    'bias': 'bearish',
    'confidence': 56,
    'horizon_candles': 12,
    'horizon_label': data['horizon'],
    'summary': data['summary'],
    'conclusion': data['summary'],
    'key_metrics': data['metrics'],
  };
}

const radarComments = {
  'en': [
    'Oversold with rising volume; watch for a close above the 20-period average.',
    'RSI at a multi-week low near support; a reversal candle is forming.',
    'Bounce attempt inside a downtrend; wait for confirmation.',
  ],
  'tr': [
    'Hacim artarken aşırı satımda; 20 periyotluk ortalamanın üzerinde kapanış izlenmeli.',
    'RSI haftalık dipte, destek yakınında; dönüş mumu oluşuyor.',
    'Düşüş trendi içinde tepki denemesi; teyit beklenmeli.',
  ],
  'es': [
    'Sobreventa con volumen creciente; vigila un cierre sobre la media de 20 periodos.',
    'RSI en mínimos de varias semanas cerca del soporte; se forma una vela de reversión.',
    'Intento de rebote dentro de una tendencia bajista; espera confirmación.',
  ],
};
