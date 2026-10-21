import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/models/home_data.dart';

import 'helpers/home_fakes.dart';

void main() {
  test('parses a full response', () {
    final d = HomeData.fromJson(fullHomeJson());
    expect(d.market!.fearGreed!.value, 53);
    expect(d.market!.fearGreed!.label, 'Neutral');
    expect(d.market!.fearGreed!.change7d, -8);
    expect(d.market!.btc!.regime, 'bull');
    expect(d.market!.btc!.price, 82000.0);
    expect(d.market!.btc!.dominancePct, 60.2);
    expect(d.market!.totalMarketCap!.usd, 2738271923149);
    expect(d.events.length, 2);
    expect(d.events.first.isHigh, isTrue);
    expect(d.radar.first.symbol, 'ETHUSDT');
    expect(d.radar.first.isBuy, isTrue);
    expect(d.radar.last.marketType, 'futures');
    expect(d.movers.length, 2);
    expect(d.lastAnalysis!.id, 12);
    expect(d.lastAnalysis!.bias, 'bearish');
    expect(d.lastAnalysis!.cached, isTrue);
    expect(d.credits!.balance, 80);
    expect(d.credits!.isPro, isFalse);
    expect(d.generatedAt, DateTime.utc(2026, 10, 21, 10));
  });

  test('partial response: missing sections and keys are tolerated', () {
    final d = HomeData.fromJson({
      'market': {
        'fear_greed': {'value': 'x'},
        'btc': {'price': '81000.5'},
      },
      'radar': [
        {'symbol': 'BTCUSDT', 'timeframe': '1h', 'direction': 'buy'},
        {'symbol': 'BROKEN'}, // dropped: no timeframe/direction
        'garbage',
      ],
      'last_analysis': {'symbol': 'ETHUSDT', 'bias': 'weird', 'extra': 1},
      'unknown_field': {'a': 1},
    });
    expect(d.market!.fearGreed, isNull); // value not numeric
    expect(d.market!.btc!.price, 81000.5);
    expect(d.market!.btc!.regime, 'unknown');
    expect(d.market!.hasAnyData, isTrue);
    expect(d.radar.length, 1);
    expect(d.radar.first.strength, 1);
    expect(d.radar.first.marketType, 'spot');
    expect(d.events, isEmpty);
    expect(d.movers, isEmpty);
    expect(d.lastAnalysis!.bias, 'neutral');
    expect(d.lastAnalysis!.cached, isFalse);
    expect(d.credits, isNull);
  });

  test('empty response', () {
    final d = HomeData.fromJson(emptyHomeJson());
    expect(d.market, isNull);
    expect(d.events, isEmpty);
    expect(d.radar, isEmpty);
    expect(d.movers, isEmpty);
    expect(d.lastAnalysis, isNull);
    expect(d.credits!.balance, 5);
    expect(HomeData.fromJson(<String, dynamic>{}).market, isNull);
  });

  test('garbage input never throws and yields empty data', () {
    for (final junk in <Object?>[null, 5, 'str', <dynamic>[], true]) {
      final d = HomeData.fromJson(junk);
      expect(d.market, isNull);
      expect(d.radar, isEmpty);
      expect(d.credits, isNull);
    }
    final d = HomeData.fromJson({
      'market': 'nope',
      'events': 'nope',
      'radar': {'a': 1},
      'movers': [null, 1, 'x', <String, dynamic>{}],
      'last_analysis': [],
      'credits': 7,
    });
    expect(d.market, isNull);
    expect(d.events, isEmpty);
    expect(d.radar, isEmpty);
    expect(d.movers, isEmpty);
    expect(d.lastAnalysis, isNull);
    expect(d.credits, isNull);
  });

  test('lists are capped at 5 and fear/greed value is clamped', () {
    final d = HomeData.fromJson({
      'market': {
        'fear_greed': {'value': 250},
      },
      'movers': [
        for (var i = 0; i < 9; i++) {'symbol': 'C$i'},
      ],
    });
    expect(d.movers.length, 5);
    expect(d.market!.fearGreed!.value, 100);
  });

  test('fromBody rejects non-object bodies and accepts objects', () {
    expect(() => HomeData.fromBody('[1,2]'), throwsFormatException);
    expect(() => HomeData.fromBody('not json'), throwsFormatException);
    expect(HomeData.fromBody(jsonEncode(fullHomeJson())).credits!.balance, 80);
  });

  test('stale flag is read when present', () {
    expect(
      HomeData.fromJson({'stale': true, 'market': null}).marketStale,
      true,
    );
    expect(HomeData.fromJson({'market': null}).marketStale, false);
  });
}
