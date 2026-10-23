import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';

Map<String, dynamic> fullOverviewJson() => {
  'coin_id': 1,
  'generated_at': '2026-10-21T10:00:00Z',
  'summary': {
    'name': 'Bitcoin',
    'symbol': 'BTC',
    'rank': 1,
    'market_cap': 1600000000000,
    'fdv': 1700000000000.0,
    'volume_24h': 45000000000,
    'volume_market_cap_ratio': 0.028,
    'supply': {
      'circulating': 19700000,
      'total': 19700000,
      'max': 21000000,
      'has_max_supply': true,
    },
    'changes': {'24h': 1.5, '7d': -3.2, '30d': 10.0, '90d': -12.5},
    'ath': {
      'price': 126000,
      'date': '2025-10-06T00:00:00Z',
      'distance_pct': -35.2,
    },
    'atl': {
      'price': 67.81,
      'date': '2013-07-06T00:00:00Z',
      'distance_pct': 120000,
    },
    'category': 'Layer 1',
    'tags': ['pow', 'store-of-value', ''],
    'platform': null,
    'age_days': 6200,
    'listing_age_days': 3300,
    'new_listing': false,
  },
  'market': {
    'market_type': 'futures',
    'futures': {
      'funding_rate': 0.0001,
      'funding_percentile': 85,
      'oi_change': {'1h': 0.5, '4h': -1.0, '24h': 3.0, '7d': 8.0},
      'long_share': 0.56,
      'long_short_ratio': 1.27,
      'top_trader_ratio': 1.1,
      'taker': {'1h': 1.2, '24h': 0.8},
      'basis_pct': 0.03,
    },
    'liquidity': {
      'spread_bps': 0.8,
      'depth': [
        {'band_pct': 2, 'bid_usd': 30000000, 'ask_usd': 20000000},
        {'band_pct': 1, 'bid_usd': 12000000, 'ask_usd': 15000000},
      ],
    },
    'activity': {
      'volume_24h': 45000000000,
      'trades_24h': 3200000,
      'volume_rank': 1,
      'volume_rank_total': 300,
    },
  },
};

void main() {
  group('CoinOverview.parse', () {
    test('full payload', () {
      final o = CoinOverview.parse(fullOverviewJson());
      expect(o.isEmpty, isFalse);
      expect(o.generatedAt, isNotNull);

      final s = o.summary!;
      expect(s.name, 'Bitcoin');
      expect(s.rank, 1);
      expect(s.marketCap, 1.6e12);
      expect(s.fdv, 1.7e12);
      expect(s.volumeMarketCapRatio, 0.028);
      expect(s.circulatingSupply, 19700000);
      expect(s.maxSupply, 21000000);
      expect(s.hasMaxSupply, isTrue);
      expect(s.circulatingPctOfMax, closeTo(93.8, 0.1));
      expect(s.showsSupplyProgress, isTrue);
      expect(s.change24h, 1.5);
      expect(s.change7d, -3.2);
      expect(s.change30d, 10.0);
      expect(s.change90d, -12.5);
      expect(s.ath!.price, 126000);
      expect(s.ath!.date, isNotNull);
      expect(s.ath!.distancePct, -35.2);
      expect(s.atl!.distancePct, 120000);
      expect(s.category, 'Layer 1');
      expect(s.tags, ['pow', 'store-of-value']);
      expect(s.platform, isNull);
      expect(s.ageDays, 6200);
      expect(s.listingAgeDays, 3300);
      expect(s.newListing, isFalse);

      final f = o.market!.futures!;
      // Raw exchange fraction 0.0001 is 0.01 percent.
      expect(f.fundingRatePct, closeTo(0.01, 1e-9));
      expect(f.fundingPercentile, 85);
      expect(f.oiChange1h, 0.5);
      expect(f.oiChange4h, -1.0);
      expect(f.oiChange24h, 3.0);
      expect(f.oiChange7d, 8.0);
      // A 0..1 share is scaled to percent.
      expect(f.longSharePct, closeTo(56, 1e-9));
      expect(f.longShortRatio, 1.27);
      expect(f.takerBuySell1h, 1.2);
      expect(f.takerBuySell24h, 0.8);
      expect(f.basisPct, 0.03);

      final l = o.market!.liquidity!;
      expect(l.spreadBps, 0.8);
      // Bands are sorted ascending.
      expect(l.depth.map((b) => b.bandPct), [1, 2]);
      expect(l.depth.first.imbalance, closeTo(-0.111, 0.001));
      expect(l.depth.last.imbalance, closeTo(0.2, 1e-9));

      final a = o.market!.activity!;
      expect(a.volumeRank, 1);
      expect(a.volumeRankTotal, 300);
      expect(a.trades24h, 3200000);
    });

    test('partial payload keeps only what is there', () {
      final o = CoinOverview.parse({
        'summary': {'name': 'Foo', 'market_cap': '123.5', 'rank': null},
        'market': {
          'activity': {'volume_rank': 7},
        },
      });
      expect(o.summary!.name, 'Foo');
      expect(o.summary!.marketCap, 123.5);
      expect(o.summary!.rank, isNull);
      expect(o.summary!.fdv, isNull);
      expect(o.summary!.tags, isEmpty);
      expect(o.summary!.ath, isNull);
      expect(o.market!.futures, isNull);
      expect(o.market!.liquidity, isNull);
      expect(o.market!.activity!.volumeRank, 7);
      expect(o.market!.activity!.volumeRankTotal, isNull);
    });

    test('alias keys and flat change fields are understood', () {
      final o = CoinOverview.parse({
        'data': {
          'summary': {
            'name': 'Alias',
            'percent_change_24h': 2.0,
            'percent_change_7d': -1.0,
            'fully_diluted_market_cap': 5,
            'circulating_supply': 50,
            'max_supply': 100,
            'is_new_listing': true,
          },
          'market': {
            'derivatives': {'funding_rate_pct': 0.02, 'oi_change_24h': 4},
            'liquidity': {
              'depth': {
                '1': {'bid': 10, 'ask': 5},
              },
            },
          },
        },
      });
      final s = o.summary!;
      expect(s.change24h, 2.0);
      expect(s.change7d, -1.0);
      expect(s.fdv, 5);
      expect(s.circulatingPctOfMax, 50);
      expect(s.newListing, isTrue);
      expect(o.market!.futures!.fundingRatePct, 0.02);
      expect(o.market!.futures!.oiChange24h, 4);
      expect(o.market!.liquidity!.depth.single.bandPct, 1);
    });

    test('no max supply hides the progress', () {
      final s = CoinOverview.parse({
        'summary': {
          'name': 'Eth',
          'supply': {'circulating': 100, 'max': null, 'has_max_supply': false},
        },
      }).summary!;
      expect(s.circulatingPctOfMax, isNull);
      expect(s.showsSupplyProgress, isFalse);
    });

    test('empty and null sections parse to null', () {
      expect(CoinOverview.parse({}).isEmpty, isTrue);
      final o = CoinOverview.parse({'summary': null, 'market': {}});
      expect(o.summary, isNull);
      expect(o.market, isNull);
      expect(CoinOverview.parse({'summary': {}}).summary, isNull);
    });

    test('garbage never throws', () {
      for (final junk in <Object?>[
        null,
        42,
        'text',
        [1, 2],
        {'summary': 'x', 'market': 5},
        {
          'summary': {
            'rank': 'abc',
            'market_cap': double.nan,
            'tags': 'not-a-list',
            'ath': 7,
            'changes': [1],
            'supply': 'x',
          },
          'market': {
            'futures': [],
            'liquidity': {'depth': 3},
            'activity': 'y',
          },
        },
        {
          'summary': {
            'name': 'ok',
            'market_cap': {'a': 1},
          },
        },
      ]) {
        expect(
          () => CoinOverview.parse(junk),
          returnsNormally,
          reason: '$junk',
        );
      }
      expect(CoinOverview.parse(null).isEmpty, isTrue);
      expect(CoinOverview.fromBody('not json').isEmpty, isTrue);
      expect(CoinOverview.fromBody('[]').isEmpty, isTrue);
      expect(CoinOverview.fromBody('').isEmpty, isTrue);
    });

    test('out of range values are clamped or dropped', () {
      final f = CoinOverview.parse({
        'market': {
          'futures': {
            'funding_percentile': 250,
            'long_share_pct': 140,
            'taker_buy_sell_1h': 'x',
          },
        },
      }).market!.futures!;
      expect(f.fundingPercentile, 100);
      expect(f.longSharePct, 100);
      expect(f.takerBuySell1h, isNull);
    });
  });

  group('DepthBand', () {
    test('imbalance needs both sides', () {
      expect(const DepthBand(bandPct: 1, bidUsd: 5).imbalance, isNull);
      expect(
        const DepthBand(bandPct: 1, bidUsd: 0, askUsd: 0).imbalance,
        isNull,
      );
      expect(
        const DepthBand(bandPct: 1, bidUsd: 3, askUsd: 1).imbalance,
        closeTo(0.5, 1e-9),
      );
    });
  });
}
