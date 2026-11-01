import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kriptoanaliz/data/purchase_api.dart';
import 'package:kriptoanaliz/data/purchase_payload.dart';
import 'package:kriptoanaliz/data/subscription_purchase_api.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/auth_prompt_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/credit_package_provider.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/analytics_fakes.dart';
import 'helpers/home_fakes.dart';

class _FakeIap implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api extends PurchaseApi {
  @override
  Future<PurchaseResult> verifyCreditPackagePurchase({
    required String token,
    required int creditPackageId,
    required PurchaseProof proof,
  }) async => const PurchaseResult(creditBalance: 100, alreadyProcessed: false);
}

class _SubApi extends SubscriptionPurchaseApi {
  @override
  Future<SubscriptionPurchaseResult> verifySubscriptionPurchase({
    required String token,
    required int subscriptionPlanId,
    required PurchaseProof proof,
  }) async =>
      const SubscriptionPurchaseResult(role: 'pro', alreadyProcessed: false);
}

class _Auth extends FakeAuth {
  _Auth() : super(testMember);
  @override
  Future<void> refreshMember() async {}
}

class _Home extends HomeNotifier {
  @override
  HomeState build() => const HomeState();
  @override
  Future<void> refresh({bool force = false}) async {}
}

const _pkg = CreditPackage(
  id: 7,
  name: '100',
  creditAmount: 100,
  price: '1',
  storeProductIdAndroid: 'credits_100',
);
const _plan = SubscriptionPlan(
  id: 3,
  name: 'Pro Monthly',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  appleProductId: 'ios_pro_monthly',
);

PurchaseDetails _purchase(String product, PurchaseStatus status) {
  final p = PurchaseDetails(
    purchaseID: '${1000000000 + product.hashCode.abs() % 1000}',
    productID: product,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'l',
      serverVerificationData: 'receipt',
      source: 'app_store',
    ),
    transactionDate: '0',
    status: status,
  );
  p.pendingCompletePurchase = true;
  return p;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  CreditPurchaseController.retryBackoff = const [];
  CreditPurchaseController.restoreGrace = Duration.zero;

  late RecordingAnalyticsService analytics;
  late _FakeIap iap;

  ProviderContainer make() {
    analytics = RecordingAnalyticsService();
    iap = _FakeIap();
    final c = ProviderContainer(
      overrides: [
        analyticsProvider.overrideWithValue(analytics),
        inAppPurchaseProvider.overrideWithValue(iap),
        purchaseIsIosProvider.overrideWithValue(true),
        authProvider.overrideWith(_Auth.new),
        purchaseApiProvider.overrideWithValue(_Api()),
        subscriptionPurchaseApiProvider.overrideWithValue(_SubApi()),
        subscriptionPlanListProvider.overrideWith((ref) async => [_plan]),
        homeProvider.overrideWith(_Home.new),
        creditPackageListProvider.overrideWith((ref) async => [_pkg]),
      ],
    );
    addTearDown(c.dispose);
    c.listen(creditPurchaseControllerProvider, (_, _) {});
    return c;
  }

  List<String> names() => analytics.events.map((e) => e.name).toList();

  test('beginBuy logs credit_purchase_started with the product id', () {
    final c = make();
    c.read(creditPurchaseControllerProvider.notifier).beginBuy('credits_100');
    expect(names(), ['credit_purchase_started']);
    expect(analytics.events.single.params, {'item_id': 'credits_100'});
  });

  test('a server-confirmed credit pack logs purchase', () async {
    make();
    iap.controller.add([_purchase('credits_100', PurchaseStatus.purchased)]);
    await _settle();
    expect(names(), ['purchase']);
    expect(analytics.events.single.params['item_id'], 'credits_100');
  });

  test(
    'a server-confirmed new subscription logs subscription_started',
    () async {
      make();
      iap.controller.add([
        _purchase('ios_pro_monthly', PurchaseStatus.purchased),
      ]);
      await _settle();
      expect(names(), ['subscription_started']);
    },
  );

  test('a restored subscription is not logged as a new start', () async {
    make();
    iap.controller.add([_purchase('ios_pro_monthly', PurchaseStatus.restored)]);
    await _settle();
    expect(names(), isEmpty);
  });

  test('restorePurchases logs restore_tapped', () async {
    final c = make();
    await c.read(creditPurchaseControllerProvider.notifier).restorePurchases();
    expect(names(), ['restore_tapped']);
  });

  test('continue as guest logs login with method guest', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final rec = RecordingAnalyticsService();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(rec),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authPromptDoneProvider.notifier).continueAsGuest();
    expect(rec.events.single.name, 'login');
    expect(rec.events.single.params, {'method': 'guest'});
    expect(c.read(authPromptDoneProvider), isTrue);
  });
}
