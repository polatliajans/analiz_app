import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/credit_package_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/utils/credit_pack_pricing.dart';

import 'helpers/home_fakes.dart';

CreditPackage _p(int id, int credits, String price, [String? sku]) =>
    CreditPackage(
      id: id,
      name: 'Pack $id',
      creditAmount: credits,
      price: price,
      storeProductIdAndroid: sku ?? 'sku_$id',
    );

// Typical ladder: the bigger the pack, the cheaper each credit.
final _packs = [_p(1, 50, '4.99'), _p(2, 150, '9.99'), _p(3, 400, '19.99')];

const _member = Member(id: 1, email: 'a@b.c', role: 'free', creditBalance: 25);

Future<void> _pump(
  WidgetTester tester, {
  List<CreditPackage>? packs,
  Map<String, String> store = const {},
  String locale = 'en',
  Size size = const Size(360, 1400),
  double textScale = 1,
  Future<List<CreditPackage>> Function()? loader,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(() => FakeAuth(_member)),
        creditPackageListProvider.overrideWith(
          (ref) => loader != null ? loader() : Future.value(packs ?? _packs),
        ),
        storePricesProvider.overrideWith((ref, ids) async => store),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const CreditPackagesScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  CreditPurchaseController.retryBackoff = const [];
  CreditPurchaseController.restoreGrace = Duration.zero;
  group('price parsing', () {
    test('common store formats', () {
      expect(parseStorePrice(r'$4.99')!.value, 4.99);
      expect(parseStorePrice('₺49,99')!.value, 49.99);
      expect(parseStorePrice('1.299,00 TL')!.value, 1299.0);
      expect(parseStorePrice('1,299.00 US\$')!.value, 1299.0);
      expect(parseStorePrice('4,99 €')!.value, 4.99);
      expect(parseStorePrice('¥500')!.value, 500);
      expect(parseStorePrice('1.299')!.value, 1299);
    });

    test('unparseable prices give null', () {
      expect(parseStorePrice('Free'), isNull);
      expect(parseStorePrice(''), isNull);
      expect(parseStorePrice('0,00'), isNull);
    });

    test('per-credit keeps symbol position and decimal mark', () {
      expect(formatPricePerCredit(r'$9.99', 100), r'$0.10');
      expect(formatPricePerCredit('49,99 ₺', 100), '0,50 ₺');
      expect(formatPricePerCredit(r'$4.99', 400), r'$0.012');
      expect(formatPricePerCredit('n/a', 100), isNull);
      expect(formatPricePerCredit(r'$4.99', 0), isNull);
    });
  });

  group('offers', () {
    test('best value = lowest price per credit, popular = middle pack', () {
      final o = buildCreditPackOffers(_packs, const {});
      expect(o.map((e) => e.bestValue), [false, false, true]);
      expect(o.map((e) => e.popular), [false, true, false]);
    });

    test('derived from data, not order or ids', () {
      final shuffled = [_packs[2], _packs[0], _packs[1]];
      final o = buildCreditPackOffers(shuffled, const {});
      expect(o.where((e) => e.bestValue).single.package.id, 3);
      expect(o.where((e) => e.popular).single.package.id, 2);
    });

    test('store prices win over backend ones, for label and ranking', () {
      final o = buildCreditPackOffers(_packs, const {
        'sku_1': '₺10,00',
        'sku_2': '₺100,00',
        'sku_3': '₺400,00',
      });
      expect(o[0].priceLabel, '₺10,00');
      // 10/50 = 0.20 is now the cheapest credit.
      expect(o.where((e) => e.bestValue).single.package.id, 1);
      expect(o[0].perCredit, '₺0,20');
    });

    test('unparseable store price falls back to backend pricing', () {
      final o = buildCreditPackOffers(_packs, const {
        'sku_1': 'Gratis',
        'sku_2': '₺100,00',
        'sku_3': '₺400,00',
      });
      expect(o[0].priceLabel, 'Gratis');
      expect(o[0].perCredit, isNull);
      // Ranking uses the backend prices for all packs: pack 3 is still best.
      expect(o.where((e) => e.bestValue).single.package.id, 3);
      expect(o[1].perCredit, '₺0,67');
    });

    test('no badges when nothing is comparable or all equal', () {
      expect(
        buildCreditPackOffers([_p(1, 100, '5.00')], const {}).single.bestValue,
        isFalse,
      );
      final flat = buildCreditPackOffers([
        _p(1, 100, '5.00'),
        _p(2, 200, '10.00'),
      ], const {});
      expect(flat.any((e) => e.bestValue), isFalse);
      final junk = buildCreditPackOffers([
        _p(1, 100, 'x'),
        _p(2, 200, 'y'),
      ], const {});
      expect(junk.any((e) => e.bestValue), isFalse);
      expect(junk.every((e) => e.perCredit == null), isTrue);
    });

    test('two packs: best value only, no popular', () {
      final o = buildCreditPackOffers([
        _p(1, 50, '5.00'),
        _p(2, 200, '10.00'),
      ], const {});
      expect(o.map((e) => e.bestValue), [false, true]);
      expect(o.any((e) => e.popular), isFalse);
    });
  });

  group('screen', () {
    testWidgets('balance hero, cards, badges, per-credit, CTA', (t) async {
      await _pump(
        t,
        store: const {'sku_1': r'$4.99', 'sku_2': r'$9.99', 'sku_3': r'$19.99'},
      );
      expect(find.byKey(const Key('creditSummaryTotal')), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byKey(const Key('credit-pack-1')), findsOneWidget);
      expect(find.byKey(const Key('credit-pack-amount-3')), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      // Best value sits on the 400 pack, popular on the 150 pack.
      expect(
        find.descendant(
          of: find.byKey(const Key('credit-pack-3')),
          matching: find.text('Best value'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('credit-pack-2')),
          matching: find.text('Popular'),
        ),
        findsOneWidget,
      );
      expect(find.text('Best value'), findsOneWidget);
      expect(find.text(r'$0.067 / credit'), findsOneWidget);
      expect(find.text(r'$0.050 / credit'), findsOneWidget);
      expect(find.text(r'Buy · $19.99'), findsOneWidget);
      expect(find.byKey(const Key('creditsHowItWorks')), findsOneWidget);
      expect(find.text('How credits work'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('unparseable price: no per-credit line, no crash', (t) async {
      await _pump(
        t,
        packs: [_p(1, 100, 'abc'), _p(2, 200, 'def')],
        store: const {'sku_1': 'Gratis', 'sku_2': 'Gratis'},
      );
      expect(find.byKey(const Key('credit-pack-per-1')), findsNothing);
      expect(find.text('Buy · Gratis'), findsNWidgets(2));
      expect(find.text('Best value'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('backend USD fallback when the store has no price', (t) async {
      await _pump(t);
      expect(find.text(r'Buy · $4.99'), findsOneWidget);
    });

    testWidgets('empty list shows the empty state', (t) async {
      await _pump(t, packs: const []);
      expect(find.byKey(const Key('creditsNoPackages')), findsOneWidget);
      expect(find.byKey(const Key('creditSummaryTotal')), findsOneWidget);
    });

    testWidgets('error state is preserved', (t) async {
      await _pump(t, loader: () => Future.error('boom'));
      expect(find.textContaining('boom'), findsOneWidget);
    });

    testWidgets('a pack without a store product id has a disabled button', (
      t,
    ) async {
      await _pump(
        t,
        packs: const [
          CreditPackage(id: 9, name: 'x', creditAmount: 10, price: '1.00'),
        ],
      );
      final b = t.widget<FilledButton>(
        find.byKey(const Key('credit-pack-buy-9')),
      );
      expect(b.onPressed, isNull);
    });

    for (final locale in ['tr', 'es']) {
      testWidgets('no overflow at 360dp / 1.6x ($locale)', (t) async {
        await _pump(
          t,
          locale: locale,
          textScale: 1.6,
          size: const Size(360, 3200),
        );
        expect(t.takeException(), isNull);
        expect(find.byKey(const Key('credit-badge-best')), findsOneWidget);
      });
    }
  });
}
