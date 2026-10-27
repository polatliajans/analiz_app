import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:kriptoanaliz/data/purchase_payload.dart';
import 'package:kriptoanaliz/data/subscription_purchase_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/store_product_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/utils/pro_purchase.dart';
import 'package:kriptoanaliz/utils/subscription_period.dart';
import 'package:kriptoanaliz/widgets/home/home_top_cards.dart';
import 'package:kriptoanaliz/widgets/pro_upsell_sheet.dart';

import 'helpers/home_fakes.dart';
import 'helpers/home_harness.dart';

const _free = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'user',
  creditBalance: 80,
);
const _plan = SubscriptionPlan(
  id: 1,
  name: 'CryptoAnaliz Pro Monthly',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  appleProductId: 'ios_pro_monthly',
  monthlyCredit: 300,
);

class _FakeIap implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  int restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppStoreProductDetails _storeProduct({
  String id = 'ios_pro_monthly',
  String title = 'Pro (monthly)',
  SKProductSubscriptionPeriodWrapper? period,
}) => AppStoreProductDetails(
  id: id,
  title: title,
  description: 'd',
  price: 'TRY 349,99',
  rawPrice: 349.99,
  currencyCode: 'TRY',
  currencySymbol: 'TRY',
  skProduct: SKProductWrapper(
    productIdentifier: id,
    localizedTitle: title,
    localizedDescription: 'd',
    priceLocale: SKPriceLocaleWrapper(
      currencySymbol: 'TRY',
      currencyCode: 'TRY',
      countryCode: 'TR',
    ),
    price: '349.99',
    subscriptionPeriod:
        period ??
        SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.month,
        ),
  ),
);

Widget _app(Widget home, {required List<Override> overrides}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  CreditPurchaseController.retryBackoff = const [];
  CreditPurchaseController.restoreGrace = Duration.zero;
  final noPro = proPurchaseAvailableProvider.overrideWithValue(false);

  group('proPurchaseAvailableFor', () {
    test('true on both platforms', () {
      expect(proPurchaseAvailableFor(TargetPlatform.iOS), isTrue);
      expect(proPurchaseAvailableFor(TargetPlatform.android), isTrue);
    });

    test('provider follows the simulated platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final c = ProviderContainer();
      try {
        expect(c.read(proPurchaseAvailableProvider), isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        c.dispose();
      }
    });

    test('proUpgradeScreen routes by availability', () {
      expect(proUpgradeScreen(available: false), isA<CreditPackagesScreen>());
      expect(proUpgradeScreen(available: true), isA<SubscriptionScreen>());
    });
  });

  group('home top cards on iOS', () {
    testWidgets('free member: Pro promo and credit card side by side', (
      tester,
    ) async {
      await pumpHome(
        tester,
        member: _free,
        handler: okHome(fullHomeJson()),
        extraOverrides: [
          purchaseIsIosProvider.overrideWithValue(true),
          subscriptionPlanListProvider.overrideWith((ref) async => []),
          storePricesProvider.overrideWith((ref, ids) async => {}),
        ],
      );
      final promo = find.byKey(const ValueKey('home-pro-promo'));
      final card = find.byKey(const ValueKey('home-credit-card'));
      expect(promo, findsOneWidget);
      expect(card, findsOneWidget);
      // Side by side: same row, neither full width.
      expect(tester.getTopLeft(promo).dy, tester.getTopLeft(card).dy);
      expect(tester.getSize(card).width, lessThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the central switch can still hide the promo', (tester) async {
      await pumpHome(
        tester,
        member: _free,
        handler: okHome(fullHomeJson()),
        extraOverrides: [noPro],
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.byKey(const ValueKey('home-credit-card')), findsOneWidget);
    });

    testWidgets('HomeTopCards(showPro: false) renders only credits', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HomeTopCards(
              showPro: false,
              credits: 5,
              onPro: () {},
              onCredits: () {},
            ),
          ),
          overrides: const [],
        ),
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.byKey(const ValueKey('home-credit-card')), findsOneWidget);
    });
  });

  group('Pro upsell on iOS', () {
    testWidgets('showProUpsell shows the normal Pro sheet', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showProUpsell(context, ProFeature.generic),
              child: const Text('open'),
            ),
          ),
          overrides: [
            purchaseIsIosProvider.overrideWithValue(true),
            authProvider.overrideWith(() => FakeAuth(_free)),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = await _en();
      expect(find.text(l10n.upgradeToPro), findsOneWidget);
    });

    testWidgets('showProUpsell with the switch off: neutral note, no sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showProUpsell(context, ProFeature.deepAnalysis),
                child: const Text('open'),
              ),
            ),
          ),
          overrides: [noPro],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final l10n = await _en();
      expect(find.text(l10n.featureNotAvailable), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('ProBadge is shown', (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: ProBadge()), overrides: const []),
      );
      expect(find.text('Pro'), findsOneWidget);
    });
  });

  group('SubscriptionScreen paywall on iOS', () {
    late _FakeIap iap;

    List<Override> overrides({
      required bool pro,
      bool ios = true,
      bool storeKit = true,
      Map<String, ProductDetails>? products,
    }) {
      iap = _FakeIap();
      return [
        purchaseIsIosProvider.overrideWithValue(ios),
        inAppPurchaseProvider.overrideWithValue(iap),
        isProProvider.overrideWithValue(pro),
        authProvider.overrideWith(() => FakeAuth(_free)),
        subscriptionPlanListProvider.overrideWith((ref) async => [_plan]),
        storePricesProvider.overrideWith(
          (ref, ids) async => {
            'ios_pro_monthly': 'TRY 349,99',
            'pro_monthly': 'TRY 349,99',
          },
        ),
        storeProductsProvider.overrideWith(
          (ref, ids) async =>
              products ??
              (storeKit ? {'ios_pro_monthly': _storeProduct()} : {}),
        ),
      ];
    }

    Future<void> pumpScreen(WidgetTester tester, List<Override> o) async {
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const SubscriptionScreen(), overrides: o));
      await tester.pumpAndSettle();
    }

    testWidgets('shows StoreKit title, price, period and the legal block', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: false));
      final l10n = await _en();
      expect(find.text('Pro (monthly)'), findsOneWidget); // store title
      expect(find.text('TRY 349,99'), findsOneWidget); // store price
      expect(find.text(l10n.subPeriodMonth(1)), findsOneWidget);
      expect(find.text(l10n.subAutoRenewsIos), findsOneWidget);
      final note = tester.widget<Text>(
        find.byKey(const Key('subscription-terms-note')),
      );
      expect(note.data, l10n.subCancelNoteIos);
      expect(note.data, contains('Apple ID'));
      expect(note.data, contains('24 hours'));
      expect(note.data, contains('until you cancel'));
      expect(find.byKey(const Key('manage-subscription')), findsOneWidget);
      expect(find.byKey(const Key('restore-purchases')), findsOneWidget);
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
      expect(find.byKey(const Key('legal-privacy')), findsOneWidget);
      expect(find.text(l10n.subscribe), findsOneWidget);
      // No trial is advertised.
      expect(
        find.textContaining(RegExp('trial', caseSensitive: false)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to the plan name / duration without StoreKit', (
      tester,
    ) async {
      final o = overrides(pro: false, storeKit: false);
      await pumpScreen(tester, o);
      final l10n = await _en();
      expect(find.text(_plan.name), findsOneWidget);
      expect(find.text(l10n.durationDays(30)), findsOneWidget);
    });

    testWidgets('Subscribe is disabled when the store lacks the plan', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        overrides(pro: false, products: {'other': _storeProduct(id: 'other')}),
      );
      final l10n = await _en();
      expect(find.byKey(const Key('plan-unavailable')), findsOneWidget);
      expect(find.text(l10n.subProductUnavailable), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Subscribe stays enabled when the plan is in the store', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: false));
      expect(find.byKey(const Key('plan-unavailable')), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('restore with nothing to restore tells the user', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: false));
      await tester.tap(find.byKey(const Key('restore-purchases')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final l10n = await _en();
      expect(find.text(l10n.restoreNothingToRestore), findsOneWidget);
    });

    testWidgets('restore button replays the store transactions', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: false));
      await tester.tap(find.byKey(const Key('restore-purchases')));
      await tester.pump();
      expect(iap.restores, 1);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Pro member: status card, manage + restore, no plans', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: true));
      final l10n = await _en();
      expect(find.text(l10n.subAlreadyProTitle), findsOneWidget);
      expect(find.text(l10n.subscribe), findsNothing);
      expect(find.byKey(const Key('manage-subscription')), findsOneWidget);
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
    });

    testWidgets('Android: unchanged (no restore, no manage, Play note)', (
      tester,
    ) async {
      await pumpScreen(tester, overrides(pro: false, ios: false));
      final l10n = await _en();
      expect(find.byKey(const Key('restore-purchases')), findsNothing);
      expect(find.byKey(const Key('manage-subscription')), findsNothing);
      expect(find.text(l10n.subCancelNote), findsOneWidget);
      expect(find.text(_plan.name), findsOneWidget);
      expect(find.text(l10n.durationDays(30)), findsOneWidget);
      expect(find.text(l10n.subAutoRenewsIos), findsNothing);
    });

    testWidgets('central switch off: status view only', (tester) async {
      await pumpScreen(tester, [...overrides(pro: false), noPro]);
      final l10n = await _en();
      expect(find.text(l10n.subscribe), findsNothing);
      expect(find.byKey(const Key('restore-purchases')), findsNothing);
    });
  });

  group('storeKitPeriodText', () {
    test('maps StoreKit units', () async {
      final l10n = await _en();
      String? text(int n, SKSubscriptionPeriodUnit u) => storeKitPeriodText(
        _storeProduct(
          period: SKProductSubscriptionPeriodWrapper(numberOfUnits: n, unit: u),
        ),
        l10n,
      );
      expect(text(1, SKSubscriptionPeriodUnit.month), 'per month');
      expect(text(3, SKSubscriptionPeriodUnit.month), 'every 3 months');
      expect(text(1, SKSubscriptionPeriodUnit.year), 'per year');
      expect(text(1, SKSubscriptionPeriodUnit.week), 'per week');
      expect(text(7, SKSubscriptionPeriodUnit.day), 'every 7 days');
      expect(storeKitPeriodText(null, l10n), isNull);
    });
  });

  group('subscription purchase request', () {
    Future<(http.Request, Object?)> post(
      TargetPlatform platform,
      PurchaseProof proof,
      int status, [
      String body = '{"role":"pro","already_processed":false}',
    ]) async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(body, status);
      });
      debugDefaultTargetPlatformOverride = platform;
      Object? outcome;
      try {
        await http.runWithClient(() async {
          try {
            outcome = await SubscriptionPurchaseApi()
                .verifySubscriptionPurchase(
                  token: 't',
                  subscriptionPlanId: 5,
                  proof: proof,
                );
          } catch (e) {
            outcome = e;
          }
        }, () => client);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
      return (seen, outcome);
    }

    test('iOS sends platform and transaction id (no receipt)', () async {
      final (req, outcome) = await post(
        TargetPlatform.iOS,
        const PurchaseProof('1000000123', 'base64receipt'),
        200,
      );
      expect(req.url.path, endsWith('/purchases/subscriptions/5'));
      expect(req.bodyFields, {
        'platform': 'ios',
        'purchase_token': '1000000123',
      });
      expect(outcome, isA<SubscriptionPurchaseResult>());
      expect((outcome as SubscriptionPurchaseResult).role, 'pro');
    });

    test(
      '422 subscription_bound_to_other_account is permanent with code',
      () async {
        final (_, outcome) = await post(
          TargetPlatform.iOS,
          const PurchaseProof('1000000123'),
          422,
          '{"code":"subscription_bound_to_other_account","message":"x"}',
        );
        final e = outcome as SubscriptionPurchaseException;
        expect(e.code, 'subscription_bound_to_other_account');
        expect(e.permanent, isTrue);
        expect(e.alreadyProcessed, isFalse);
        expect(e.message, contains('another account'));
      },
    );

    test('409 subscription_active_other_store carries its code', () async {
      final (_, outcome) = await post(
        TargetPlatform.iOS,
        const PurchaseProof('1000000123'),
        409,
        '{"code":"subscription_active_other_store","message":"x"}',
      );
      final e = outcome as SubscriptionPurchaseException;
      expect(e.code, 'subscription_active_other_store');
      expect(e.message, contains('Google Play'));
    });

    test('Android keeps the single-field body', () async {
      final (req, _) = await post(
        TargetPlatform.android,
        const PurchaseProof('play-token'),
        200,
      );
      expect(req.bodyFields, {'purchase_token': 'play-token'});
    });

    test('422 is permanent, 502 is transient, already processed', () async {
      const proof = PurchaseProof('1', 'r');
      var (_, o) = await post(TargetPlatform.iOS, proof, 422, '{}');
      expect(o, isA<SubscriptionPurchaseException>());
      expect((o as SubscriptionPurchaseException).permanent, isTrue);
      (_, o) = await post(TargetPlatform.iOS, proof, 502, '{}');
      expect((o as SubscriptionPurchaseException).permanent, isFalse);
      expect(o.alreadyProcessed, isFalse);
      (_, o) = await post(
        TargetPlatform.iOS,
        proof,
        422,
        jsonEncode({'code': 'purchase_already_processed'}),
      );
      expect((o as SubscriptionPurchaseException).alreadyProcessed, isTrue);
    });
  });
}
