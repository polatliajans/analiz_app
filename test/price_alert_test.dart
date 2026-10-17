import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/price_alert_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/price_alert.dart';
import 'package:kriptoanaliz/utils/price_alert_logic.dart';

void main() {
  group('directionForTarget', () {
    test('above, below and equal', () {
      expect(directionForTarget(110, 100), AlertDirection.above);
      expect(directionForTarget(90, 100), AlertDirection.below);
      expect(directionForTarget(100, 100), isNull);
    });

    test('null or non-finite inputs', () {
      expect(directionForTarget(null, 100), isNull);
      expect(directionForTarget(100, null), isNull);
      expect(directionForTarget(double.nan, 100), isNull);
    });
  });

  group('applyPercent', () {
    test('moves the price by the percentage', () {
      expect(applyPercent(100, 5), 105);
      expect(applyPercent(100, -10), 90);
      expect(applyPercent(67000, 1), 67670);
    });

    test('keeps small prices precise without float noise', () {
      expect(applyPercent(0.00001234, 10), 0.00001357);
      expect(formatAlertPrice(applyPercent(0.1, 1)), '0.101');
    });

    test('every quick percent is symmetric in sign', () {
      for (final p in alertQuickPercents) {
        final r = applyPercent(1000, p);
        expect(p > 0 ? r > 1000 : r < 1000, isTrue);
      }
      expect(alertQuickPercents, containsAll([-10, -5, -2, -1, 1, 2, 5, 10]));
    });
  });

  group('formatAlertPrice', () {
    test('scales decimals to the price and trims zeros', () {
      expect(formatAlertPrice(67234.5), '67234.5');
      expect(formatAlertPrice(67234), '67234');
      expect(formatAlertPrice(3.5), '3.5');
      expect(formatAlertPrice(0.5), '0.5');
      expect(formatAlertPrice(0.000012), '0.000012');
      expect(formatAlertPrice(0.00000123), '0.00000123');
    });

    test('never uses exponent notation and rejects non-positive', () {
      expect(formatAlertPrice(0.00000001), '0.00000001');
      expect(formatAlertPrice(0), '0');
      expect(formatAlertPrice(-5), '0');
    });
  });

  group('parsePriceInput', () {
    test('accepts dot and comma decimals', () {
      expect(parsePriceInput('12.5'), 12.5);
      expect(parsePriceInput(' 12,5 '), 12.5);
    });

    test('rejects empty, malformed and non-positive', () {
      expect(parsePriceInput(''), isNull);
      expect(parsePriceInput('abc'), isNull);
      expect(parsePriceInput('0'), isNull);
      expect(parsePriceInput('-3'), isNull);
    });
  });

  group('PriceAlertList.fromJson', () {
    final json = {
      'max_active': 20,
      'alerts': [
        {
          'id': 1,
          'coin_id': 7,
          'symbol': 'BTCUSDT',
          'market_type': 'spot',
          'target_price': '70000.00000000',
          'direction': 'above',
          'status': 'active',
          'triggered_at': null,
          'triggered_price': null,
          'created_at': '2026-10-17T10:00:00+00:00',
        },
        {
          'id': 2,
          'coin_id': 7,
          'symbol': 'BTCUSDT',
          'market_type': 'spot',
          'target_price': '60000.5',
          'direction': 'below',
          'status': 'triggered',
          'triggered_at': '2026-10-17T11:00:00+00:00',
          'triggered_price': '59999.9',
          'created_at': '2026-10-17T09:00:00+00:00',
        },
        {
          'id': 3,
          'coin_id': 9,
          'symbol': 'PEPEUSDT',
          'market_type': 'futures',
          'target_price': '0.00001234',
          'direction': 'above',
          'status': 'canceled',
          'triggered_at': null,
          'triggered_price': null,
          'created_at': '2026-10-16T09:00:00+00:00',
        },
      ],
    };

    test('parses fields and splits active/history', () {
      final list = PriceAlertList.fromJson(json);
      expect(list.maxActive, 20);
      expect(list.alerts, hasLength(3));
      final first = list.alerts.first;
      expect(first.targetPrice, 70000);
      expect(first.direction, AlertDirection.above);
      expect(first.status, PriceAlertStatus.active);
      expect(first.triggeredAt, isNull);
      final second = list.alerts[1];
      expect(second.direction, AlertDirection.below);
      expect(second.triggeredPrice, 59999.9);
      expect(second.triggeredAt, isNotNull);
      expect(list.alerts[2].targetPrice, 0.00001234);
      expect(list.active.map((a) => a.id), [1]);
      expect(list.history.map((a) => a.id), [2, 3]);
      expect(list.activeForCoin(7).map((a) => a.id), [1]);
      expect(list.activeForCoin(9), isEmpty);
    });

    test('empty payload gives defaults', () {
      final list = PriceAlertList.fromJson({});
      expect(list.alerts, isEmpty);
      expect(list.maxActive, 20);
    });
  });

  group('error mapping', () {
    test('maps API codes to kinds', () {
      expect(
        priceAlertErrorKindFromCode('pro_required'),
        PriceAlertErrorKind.proRequired,
      );
      expect(
        priceAlertErrorKindFromCode('alert_limit_reached'),
        PriceAlertErrorKind.limitReached,
      );
      expect(
        priceAlertErrorKindFromCode('alert_duplicate'),
        PriceAlertErrorKind.duplicate,
      );
      expect(priceAlertErrorKindFromCode('x'), PriceAlertErrorKind.other);
      expect(priceAlertErrorKindFromCode(null), PriceAlertErrorKind.other);
    });

    test('parses response bodies', () {
      final limit = PriceAlertException.fromResponse(
        422,
        '{"code":"alert_limit_reached","message":"m","limit":20}',
      );
      expect(limit.kind, PriceAlertErrorKind.limitReached);
      expect(limit.limit, 20);
      expect(
        PriceAlertException.fromResponse(403, '{"code":"pro_required"}').kind,
        PriceAlertErrorKind.proRequired,
      );
      expect(
        PriceAlertException.fromResponse(
          422,
          '{"code":"alert_duplicate"}',
        ).kind,
        PriceAlertErrorKind.duplicate,
      );
      expect(
        PriceAlertException.fromResponse(401, 'not json').kind,
        PriceAlertErrorKind.unauthorized,
      );
      expect(
        PriceAlertException.fromResponse(500, '').kind,
        PriceAlertErrorKind.other,
      );
    });

    test('localized messages differ per kind and include the limit', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final pro = priceAlertErrorText(
        l10n,
        const PriceAlertException(PriceAlertErrorKind.proRequired),
      );
      final limit = priceAlertErrorText(
        l10n,
        const PriceAlertException(PriceAlertErrorKind.limitReached, limit: 5),
      );
      final dup = priceAlertErrorText(
        l10n,
        const PriceAlertException(PriceAlertErrorKind.duplicate),
      );
      expect({pro, limit, dup}, hasLength(3));
      expect(limit, contains('5'));
      expect(priceAlertErrorText(l10n, Exception('x')), isNotEmpty);
    });
  });
}
