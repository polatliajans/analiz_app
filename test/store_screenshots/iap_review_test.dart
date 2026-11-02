// App Store Connect in-app-purchase REVIEW screenshots (plain app screens, no
// marketing frame). Opt-in:
//   IAP_REVIEW=1 STORE_SHOT_PROFILE=ios flutter test test/store_screenshots/iap_review_test.dart
// Output: store_assets/iap_review/raw/*.png (RGBA); tool/iap_review_finalize.py
// flattens them to RGB into store_assets/iap_review/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/credit_package_provider.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/store_product_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';

import 'shot_support.dart';
import 'store_screenshots_test.dart' show makeContainer;

const _out = 'store_assets/iap_review/raw';

class _NoStore implements InAppPurchase {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle(WidgetTester tester, [int steps = 10]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

const _packs = [
  ('Mini Paket', 30, '2.99'),
  ('Başlangıç Paketi', 80, '7.49'),
  ('Plus Paket', 200, '17.99'),
  ('Maks Paket', 500, '39.99'),
  ('Mega Paket', 1000, '74.99'),
];

void main() {
  setUpAll(loadStoreFonts);
  final skip = Platform.environment['IAP_REVIEW'] != '1' || !iosProfile;

  testWidgets('credits', (tester) async {
    usePhoneSurface(tester);
    final packages = [
      for (var i = 0; i < _packs.length; i++)
        CreditPackage(
          id: i + 1,
          name: _packs[i].$1,
          creditAmount: _packs[i].$2,
          price: _packs[i].$3,
          storeProductIdAndroid: 'credits_${_packs[i].$2}',
        ),
    ];
    final prices = {
      for (final p in packages) p.storeProductIdAndroid!: '\$${p.price}',
    };
    final c = await makeContainer(
      tester,
      extra: [
        inAppPurchaseProvider.overrideWithValue(_NoStore()),
        creditPackageListProvider.overrideWith((ref) async => packages),
        storePricesProvider.overrideWith((ref, ids) async => prices),
      ],
    );
    await tester.pumpWidget(
      shotApp(lang: 'en', home: const CreditPackagesScreen(), container: c),
    );
    await _settle(tester);
    await _save(tester, 'credits_top');
    final list = find.byType(ListView).first;
    for (final dy in [300.0, 1000.0]) {
      await tester.drag(list, Offset(0, -dy));
      await _settle(tester);
      await _save(tester, 'credits_scroll_${dy.toInt()}');
    }
  }, skip: skip);

  testWidgets('pro', (tester) async {
    usePhoneSurface(tester);
    final product = AppStoreProductDetails(
      id: 'ios_pro_monthly',
      title: 'Aylık Pro',
      description: 'Pro',
      price: '\$19.99',
      rawPrice: 19.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
      skProduct: SKProductWrapper(
        productIdentifier: 'ios_pro_monthly',
        localizedTitle: 'Aylık Pro',
        localizedDescription: 'Pro',
        priceLocale: SKPriceLocaleWrapper(
          currencySymbol: '\$',
          currencyCode: 'USD',
          countryCode: 'US',
        ),
        price: '19.99',
        subscriptionPeriod: SKProductSubscriptionPeriodWrapper(
          numberOfUnits: 1,
          unit: SKSubscriptionPeriodUnit.month,
        ),
      ),
    );
    final c = await makeContainer(
      tester,
      extra: [
        purchaseIsIosProvider.overrideWithValue(true),
        inAppPurchaseProvider.overrideWithValue(_NoStore()),
        subscriptionPlanListProvider.overrideWith(
          (ref) async => const [
            SubscriptionPlan(
              id: 1,
              name: 'Aylık Pro',
              price: '19.99',
              durationDays: 30,
              storeProductIdAndroid: 'pro_monthly',
              appleProductId: 'ios_pro_monthly',
              monthlyCredit: 300,
            ),
          ],
        ),
        storePricesProvider.overrideWith(
          (ref, ids) async => const {'ios_pro_monthly': '\$19.99'},
        ),
        storeProductsProvider.overrideWith(
          (ref, ids) async => {'ios_pro_monthly': product},
        ),
      ],
    );
    await tester.pumpWidget(
      shotApp(lang: 'en', home: const SubscriptionScreen(), container: c),
    );
    await _settle(tester);
    await _save(tester, 'pro_top');
    final list = find.byType(ListView).first;
    for (final dy in [600.0, 3000.0]) {
      await tester.drag(list, Offset(0, -dy));
      await _settle(tester);
      await _save(tester, 'pro_scroll_${dy.toInt()}');
    }
  }, skip: skip);
}
