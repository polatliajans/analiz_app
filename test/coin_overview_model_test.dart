import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/chart_signal.dart';
import 'package:kriptoanaliz/models/coin_overview.dart';

/// A fully populated payload in the backend's real shape (CMC fields filled).
Map<String, dynamic> fullOverviewJson() => {
  'generated_at': '2026-10-21T10:00:00Z',
  'stale': false,
  'coin': {
    'id': 1,
    'symbol': 'BTCUSDT',
    'market_type': 'futures',
    'base_asset': 'BTC',
  },
  'summary': {
    'name': 'Bitcoin',
    'rank': 1,
    'market_cap_usd': 1600000000000,
    'fully_diluted_market_cap_usd': 1700000000000.0,
    'volume_24h_usd': 45000000000,
    'volume_to_market_cap_pct': 2.8,
    'circulating_supply_pct_of_max': 93.8,
    'has_max_supply': true,
    'change_pct': {'24h': 1.5, '7d': -3.2, '30d': 10.0, '90d': -12.5},
    'category': 'Layer 1',
    'tags': ['pow', 'store-of-value', ''],
    'platform': null,
    'date_launched': '2010-07-17',
    'age_days': 6200,
    'ath': {
      'price': 126000,
      'date': '2025-10-06',
      'dist_pct': -35.2,
      'days_since': 380,
    },
    'atl': {'price': 67.81, 'date': '2013-07-06', 'dist_pct': 120000},
    'listing_age_days': 3300,
    'new_listing': false,
  },
  'market': {
    'futures': true,
    'funding_rate_pct': 0.01,
    'funding_percentile_90': 85,
    'oi_change_pct': {'1h': 0.5, '4h': -1.0, '24h': 3.0, '7d': 8.0},
    'long_share_pct': 56,
    'long_short_ratio': 1.27,
    'top_trader_position_ls': 1.1,
    'taker_buy_sell_ratio_1h': 1.2,
    'taker_buy_sell_ratio_24h': 0.8,
    'basis_pct': 0.03,
    'liquidity': {
      'spread_bps': 0.8,
      'depth_bands': [
        {
          'window_pct': 2.0,
          'bid_depth_usd': 30000000,
          'ask_depth_usd': 20000000,
          'imbalance_ratio': 1.5,
          'complete': true,
        },
        {
          'window_pct': 1.0,
          'bid_depth_usd': 12000000,
          'ask_depth_usd': 15000000,
          'imbalance_ratio': 0.8,
          'complete': true,
        },
      ],
    },
    'activity': {
      'quote_volume_24h_usd': 45000000000,
      'trades_24h': 3200000,
      'volume_rank': 1,
      'rank_of': 300,
      'rank_scope': 'active futures USDT coins',
    },
  },
  'attribution': ['CoinMarketCap', 'Binance'],
};

Object? _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  group('real backend samples', () {
    test('SUI futures sample (CMC fields null)', () {
      final o = CoinOverview.parse(_fixture('overview_sui_futures.json'));
      expect(o.stale, isFalse);
      expect(o.attribution, ['Binance']);
      expect(o.generatedAt, isNotNull);

      final s = o.summary!;
      expect(s.name, isNull);
      expect(s.marketCap, isNull);
      expect(s.rank, isNull);
      expect(s.volumeToMarketCapPct, isNull);
      expect(s.showsSupplyProgress, isFalse);
      expect(s.change24h, 1.13);
      expect(s.change7d, -3.03);
      expect(s.change30d, 3.16);
      expect(s.change90d, 39.23);
      expect(s.ath!.price, 5.3699);
      expect(s.ath!.date, DateTime.parse('2025-01-06').toLocal());
      expect(s.ath!.distancePct, -81.57);
      expect(s.ath!.daysSince, 655);
      expect(s.atl!.price, 0.3615);
      expect(s.atl!.distancePct, 173.8);
      expect(s.listingAgeDays, 1269);
      expect(s.newListing, isFalse);

      final m = o.market!;
      expect(m.isFutures, isTrue);
      final f = m.futures!;
      expect(f.fundingRatePct, 0.0051, reason: 'already a percent');
      expect(f.fundingPercentile, 46.7);
      expect(f.oiChange1h, -0.06);
      expect(f.oiChange4h, -0.4);
      expect(f.oiChange24h, 0.03);
      expect(f.oiChange7d, -4.53);
      expect(f.longSharePct, 67.4, reason: 'already 0..100, never rescaled');
      expect(f.longShortRatio, 2.065);
      expect(f.topTraderRatio, 2.002);
      expect(f.takerBuySell1h, 0.691);
      expect(f.takerBuySell24h, 0.96);
      expect(f.basisPct, -0.048);

      final l = m.liquidity!;
      expect(l.spreadBps, 1.01);
      expect(l.depth.map((b) => b.windowPct), [1.0, 2.0]);
      expect(l.depth.first.bidUsd, 4445427.0);
      expect(l.depth.first.askUsd, 3530608.0);
      expect(l.depth.first.imbalance, 1.26);
      expect(l.depth.every((b) => b.complete), isTrue);

      final a = m.activity!;
      expect(a.volume24h, 142062383.0);
      expect(a.trades24h, 653305);
      expect(a.volumeRank, 22);
      expect(a.volumeRankTotal, 740);
      expect(a.rankScope, 'active futures USDT coins');
    });

    test('BTC spot sample: no futures metrics, one incomplete band', () {
      final o = CoinOverview.parse(_fixture('overview_btc_spot.json'));
      final m = o.market!;
      expect(m.isFutures, isFalse);
      expect(m.futures, isNull);
      final band = m.liquidity!.depth.single;
      expect(band.windowPct, 0.101);
      expect(band.complete, isFalse);
      expect(band.imbalance, 0.54);
      expect(m.liquidity!.spreadBps, 0.001);
      expect(m.activity!.volumeRank, 2);
      expect(m.activity!.volumeRankTotal, 503);
      expect(o.summary!.ath!.price, 126200.0);
      expect(o.summary!.atl!.distancePct, 2796.7);
    });

    test(
      'chart-signals items parse exactly candle_time, signal_type, strength',
      () {
        final s = ChartSignal.fromJson({
          'candle_time': '2026-10-23T12:00:00Z',
          'signal_type': 'sell',
          'strength': 3,
        });
        expect(s.signalType, 'sell');
        expect(s.strength, 3);
        expect(s.candleTime, DateTime.utc(2026, 10, 23, 12));
      },
    );
  });

  group('CoinOverview.parse (contract shape, populated)', () {
    test('full payload', () {
      final o = CoinOverview.parse(fullOverviewJson());
      expect(o.isEmpty, isFalse);
      expect(o.attribution, ['CoinMarketCap', 'Binance']);

      final s = o.summary!;
      expect(s.name, 'Bitcoin');
      expect(s.rank, 1);
      expect(s.marketCap, 1.6e12);
      expect(s.fdv, 1.7e12);
      expect(s.volume24h, 4.5e10);
      expect(s.volumeToMarketCapPct, 2.8, reason: 'a percent, not a ratio');
      expect(s.circulatingPctOfMax, 93.8);
      expect(s.hasMaxSupply, isTrue);
      expect(s.showsSupplyProgress, isTrue);
      expect(
        [s.change24h, s.change7d, s.change30d, s.change90d],
        [1.5, -3.2, 10.0, -12.5],
      );
      expect(s.ath!.distancePct, -35.2);
      expect(s.ath!.daysSince, 380);
      expect(s.atl!.distancePct, 120000);
      expect(s.category, 'Layer 1');
      expect(s.tags, ['pow', 'store-of-value']);
      expect(s.platform, isNull);
      expect(s.dateLaunched, isNotNull);
      expect(s.ageDays, 6200);
      expect(s.listingAgeDays, 3300);

      final f = o.market!.futures!;
      expect(f.fundingRatePct, 0.01);
      expect(f.fundingPercentile, 85);
      expect(f.longSharePct, 56);
      expect(f.topTraderRatio, 1.1);
      expect(f.takerBuySell1h, 1.2);
      expect(f.takerBuySell24h, 0.8);

      final l = o.market!.liquidity!;
      expect(l.depth.map((b) => b.windowPct), [1.0, 2.0], reason: 'sorted');
      expect(l.depth.first.imbalance, 0.8);
    });

    test('a long share below 1 percent is not rescaled', () {
      final f = CoinOverview.parse({
        'market': {'futures': true, 'long_share_pct': 0.5},
      }).market!.futures!;
      expect(f.longSharePct, 0.5);
    });

    test('has_max_supply false hides the progress', () {
      final s = CoinOverview.parse({
        'summary': {
          'name': 'Eth',
          'has_max_supply': false,
          'circulating_supply_pct_of_max': null,
        },
      }).summary!;
      expect(s.circulatingPctOfMax, isNull);
      expect(s.showsSupplyProgress, isFalse);
    });

    test('partial payload keeps only what is there', () {
      final o = CoinOverview.parse({
        'summary': {'name': 'Foo', 'market_cap_usd': '123.5', 'rank': null},
        'market': {
          'activity': {'volume_rank': 7, 'rank_of': null},
        },
      });
      expect(o.summary!.marketCap, 123.5);
      expect(o.summary!.fdv, isNull);
      expect(o.market!.futures, isNull);
      expect(o.market!.activity!.volumeRank, 7);
      expect(o.market!.activity!.volumeRankTotal, isNull);
    });

    test('empty and null sections parse to null', () {
      expect(CoinOverview.parse({}).isEmpty, isTrue);
      final o = CoinOverview.parse({'summary': null, 'market': null});
      expect(o.summary, isNull);
      expect(o.market, isNull);
      expect(CoinOverview.parse({'summary': {}}).summary, isNull);
      // All-null summary keys still count as no summary only when no change.
      expect(
        CoinOverview.parse({
          'summary': {'name': null, 'tags': [], 'new_listing': false},
        }).summary,
        isNull,
      );
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
            'market_cap_usd': double.nan,
            'tags': 'not-a-list',
            'ath': 7,
            'change_pct': [1],
          },
          'market': {
            'futures': [],
            'liquidity': {'depth_bands': 3},
            'activity': 'y',
          },
          'attribution': 'Binance',
        },
        {
          'summary': {
            'name': 'ok',
            'market_cap_usd': {'a': 1},
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
          'futures': true,
          'funding_percentile_90': 250,
          'long_share_pct': 140,
          'taker_buy_sell_ratio_1h': 'x',
        },
      }).market!.futures!;
      expect(f.fundingPercentile, 100);
      expect(f.longSharePct, 100);
      expect(f.takerBuySell1h, isNull);
    });
  });

  group('legacy alias fallbacks', () {
    test('older guessed keys still map', () {
      final o = CoinOverview.parse({
        'data': {
          'summary': {
            'name': 'Alias',
            'percent_change_24h': 2.0,
            'fully_diluted_market_cap': 5,
            'circulating_supply': 50,
            'max_supply': 100,
            'volume_to_market_cap': 0.148,
            'is_new_listing': true,
          },
          'market': {
            'derivatives': {
              'funding_rate': 0.0001,
              'long_share': 0.56,
              'oi_change_24h': 4,
            },
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
      expect(s.fdv, 5);
      expect(s.circulatingPctOfMax, 50);
      expect(s.volumeToMarketCapPct, closeTo(14.8, 1e-9));
      expect(s.newListing, isTrue);
      final f = o.market!.futures!;
      expect(f.fundingRatePct, closeTo(0.01, 1e-9));
      expect(f.longSharePct, closeTo(56, 1e-9));
      expect(f.oiChange24h, 4);
      expect(o.market!.isFutures, isTrue);
      final band = o.market!.liquidity!.depth.single;
      expect(band.windowPct, 1);
      expect(band.imbalance, 2.0);
      expect(band.complete, isTrue);
    });
  });

  group('DepthBand', () {
    test('imbalance ratio is given or bid/ask', () {
      expect(const DepthBand(windowPct: 1, bidUsd: 5).imbalance, isNull);
      expect(
        const DepthBand(windowPct: 1, bidUsd: 3, askUsd: 1).imbalance,
        3.0,
      );
      expect(
        const DepthBand(
          windowPct: 1,
          bidUsd: 3,
          askUsd: 1,
          imbalanceRatio: 2.9,
        ).imbalance,
        2.9,
      );
      expect(
        const DepthBand(windowPct: 1, bidUsd: 0, askUsd: 0).imbalance,
        isNull,
      );
    });
  });
}
