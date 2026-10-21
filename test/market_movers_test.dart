import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/home_data.dart';
import 'package:kriptoanaliz/utils/home_logic.dart';

import 'helpers/home_fakes.dart';

void main() {
  group('MarketMovers parsing', () {
    test('parses the full contract', () {
      final d = HomeData.fromJson(fullHomeJson());
      final mm = d.marketMovers!;
      expect(mm.gainers.length, 7);
      expect(mm.losers.length, 7);
      expect(mm.volume.length, 7);
      final g = mm.gainers.first;
      expect(g.coinId, 100);
      expect(g.symbol, 'GAIN0USDT');
      expect(g.marketType, 'spot');
      expect(g.price, 2.0);
      expect(g.change24hPct, 20.0);
      expect(g.quoteVolumeUsd, 1200000000);
    });

    test('is null when missing, null, wrong type or empty', () {
      expect(HomeData.fromJson(<String, dynamic>{}).marketMovers, isNull);
      expect(HomeData.fromJson({'market_movers': null}).marketMovers, isNull);
      expect(HomeData.fromJson({'market_movers': 'x'}).marketMovers, isNull);
      expect(
        HomeData.fromJson({
          'market_movers': [1, 2],
        }).marketMovers,
        isNull,
      );
      expect(
        HomeData.fromJson({
          'market_movers': {'gainers': [], 'losers': [], 'volume': []},
        }).marketMovers,
        isNull,
      );
    });

    test('drops malformed rows, keeps the rest, tolerates numeric strings', () {
      final d = HomeData.fromJson({
        'market_movers': {
          'gainers': [
            null,
            'x',
            {'symbol': ''},
            {'price': 1},
            {
              'symbol': 'AAAUSDT',
              'price': '1.5',
              'change_24h_pct': 'abc',
              'quote_volume_usd': '2000',
              'coin_id': '9',
            },
          ],
          'losers': 'garbage',
        },
      });
      final mm = d.marketMovers!;
      expect(mm.gainers.length, 1);
      expect(mm.gainers.single.price, 1.5);
      expect(mm.gainers.single.change24hPct, isNull);
      expect(mm.gainers.single.quoteVolumeUsd, 2000);
      expect(mm.gainers.single.coinId, 9);
      expect(mm.losers, isEmpty);
      expect(mm.volume, isEmpty);
    });

    test('caps every list at 10 rows', () {
      final rows = [
        for (var i = 0; i < 25; i++) mover('C${i}USDT', i.toDouble(), id: i),
      ];
      final d = HomeData.fromJson({
        'market_movers': {'gainers': rows, 'losers': rows, 'volume': rows},
      });
      expect(d.marketMovers!.gainers.length, 10);
      expect(d.marketMovers!.losers.length, 10);
      expect(d.marketMovers!.volume.length, 10);
    });

    test('an old cached body without the field still parses', () {
      final json = fullHomeJson()..remove('market_movers');
      final d = HomeData.fromBody(homeResponse(json).rawBody);
      expect(d.marketMovers, isNull);
      expect(d.market, isNotNull);
    });
  });

  group('formatting helpers', () {
    test('splitSymbol', () {
      expect(splitSymbol('BTCUSDT'), ('BTC', 'USDT'));
      expect(splitSymbol('ETHBTC'), ('ETH', 'BTC'));
      expect(splitSymbol('SOLFDUSD'), ('SOL', 'FDUSD'));
      expect(splitSymbol('1000PEPEUSDT'), ('1000PEPE', 'USDT'));
      expect(splitSymbol('USDT'), ('USDT', ''));
      expect(splitSymbol('WEIRD'), ('WEIRD', ''));
    });

    test('formatVolumeShort', () {
      expect(formatVolumeShort(1.2e9, 'en'), '1.2B');
      expect(formatVolumeShort(345e6, 'en'), '345M');
      expect(formatVolumeShort(12.34e6, 'en'), '12.3M');
      expect(formatVolumeShort(5600, 'en'), '5.6K');
      expect(formatVolumeShort(2.5e12, 'en'), '2.5T');
      expect(formatVolumeShort(950, 'en'), '950');
      expect(formatVolumeShort(1.2e9, 'tr'), '1,2B');
    });
  });
}
