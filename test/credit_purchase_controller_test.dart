import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kriptoanaliz/data/purchase_api.dart';
import 'package:kriptoanaliz/data/subscription_purchase_api.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/data/purchase_payload.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/credit_package_provider.dart';
import 'package:kriptoanaliz/providers/credit_purchase_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';

import 'helpers/home_fakes.dart';

class _FakeIap implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase.productID);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api extends PurchaseApi {
  final List<Object> script; // PurchaseResult or Exception, consumed in order
  int calls = 0;
  PurchaseProof? lastProof;
  _Api(this.script);

  @override
  Future<PurchaseResult> verifyCreditPackagePurchase({
    required String token,
    required int creditPackageId,
    required PurchaseProof proof,
  }) async {
    lastProof = proof;
    final r = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (r is Exception) throw r;
    return r as PurchaseResult;
  }
}

class _SubApi extends SubscriptionPurchaseApi {
  final List<Object> script; // SubscriptionPurchaseResult or Exception
  int calls = 0;
  int? lastPlanId;
  PurchaseProof? lastProof;
  _SubApi(this.script);

  @override
  Future<SubscriptionPurchaseResult> verifySubscriptionPurchase({
    required String token,
    required int subscriptionPlanId,
    required PurchaseProof proof,
  }) async {
    lastPlanId = subscriptionPlanId;
    lastProof = proof;
    final r = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (r is Exception) throw r;
    return r as SubscriptionPurchaseResult;
  }
}

class _Auth extends FakeAuth {
  int refreshed = 0;
  final bool loggedIn;
  _Auth({this.loggedIn = true}) : super(loggedIn ? testMember : null);

  @override
  Future<void> refreshMember() async => refreshed++;

  void login() => state = const AuthState(token: 'tok', member: testMember);
}

class _Home extends HomeNotifier {
  static int refreshes = 0;
  @override
  HomeState build() => const HomeState();
  @override
  Future<void> refresh({bool force = false}) async => refreshes++;
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
const _subOk = SubscriptionPurchaseResult(role: 'pro', alreadyProcessed: false);
const _ok = PurchaseResult(creditBalance: 100, alreadyProcessed: false);

PurchaseDetails _purchase({
  String product = 'credits_100',
  String? id = '1000000123',
  PurchaseStatus status = PurchaseStatus.purchased,
}) {
  final p = PurchaseDetails(
    purchaseID: id,
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
  CreditPurchaseController.packageWait = const Duration(milliseconds: 200);
  late _FakeIap iap;
  late _Auth auth;
  late _Api api;
  late _SubApi subApi;

  ProviderContainer make(
    List<Object> script, {
    bool ios = true,
    bool loggedIn = true,
    Future<List<CreditPackage>> Function()? packages,
    List<Object> subScript = const [_subOk],
  }) {
    iap = _FakeIap();
    auth = _Auth(loggedIn: loggedIn);
    api = _Api(script);
    subApi = _SubApi(subScript);
    _Home.refreshes = 0;
    final List<Override> overrides = [
      inAppPurchaseProvider.overrideWithValue(iap),
      purchaseIsIosProvider.overrideWithValue(ios),
      authProvider.overrideWith(() => auth),
      purchaseApiProvider.overrideWithValue(api),
      subscriptionPurchaseApiProvider.overrideWithValue(subApi),
      subscriptionPlanListProvider.overrideWith((ref) async => [_plan]),
      homeProvider.overrideWith(_Home.new),
      creditPackageListProvider.overrideWith(
        (ref) => (packages ?? () async => [_pkg])(),
      ),
    ];
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    // The root widget does this at launch.
    c.listen(creditPurchaseControllerProvider, (_, _) {});
    return c;
  }

  test('credits a delivered purchase without any screen open', () async {
    final c = make([_ok]);
    iap.controller.add([_purchase()]);
    await _settle();
    expect(api.calls, 1);
    expect(api.lastProof!.token, '1000000123');
    expect(iap.completed, ['credits_100']);
    expect(auth.refreshed, 1);
    expect(_Home.refreshes, 1);
    expect(
      c.read(creditPurchaseControllerProvider).notice!.kind,
      PurchaseNoticeKind.credited,
    );
  });

  test('duplicate delivery of the same transaction credits once', () async {
    make([_ok]);
    final p = _purchase();
    iap.controller.add([p]);
    iap.controller.add([p]);
    await _settle();
    iap.controller.add([p]);
    await _settle();
    expect(api.calls, 1);
    expect(iap.completed, ['credits_100']);
  });

  test('purchase delivered before login is credited after login', () async {
    final c = make([_ok], loggedIn: false);
    iap.controller.add([_purchase()]);
    await _settle();
    expect(api.calls, 0);
    expect(iap.completed, isEmpty);
    auth.login();
    await _settle();
    expect(api.calls, 1);
    expect(iap.completed, ['credits_100']);
    expect(
      c.read(creditPurchaseControllerProvider).notice!.kind,
      PurchaseNoticeKind.credited,
    );
  });

  test(
    'iOS permanent 422 finishes the transaction and shows one error',
    () async {
      final c = make([PurchaseException('invalid', permanent: true)]);
      final p = _purchase();
      iap.controller.add([p]);
      await _settle();
      iap.controller.add([p]); // redelivery must not re-run or re-notify
      await _settle();
      expect(api.calls, 1);
      expect(iap.completed, ['credits_100']);
      final n = c.read(creditPurchaseControllerProvider).notice!;
      expect(n.kind, PurchaseNoticeKind.rejected);
      expect(n.detail, 'invalid');
    },
  );

  test(
    'Android permanent 422 keeps the old behaviour (not finished)',
    () async {
      final c = make([
        PurchaseException('invalid', permanent: true),
      ], ios: false);
      iap.controller.add([_purchase(id: 'GPA.1')]);
      await _settle();
      expect(iap.completed, isEmpty);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.willRetry,
      );
    },
  );

  test('502/network keeps it pending and a later retry credits it', () async {
    final c = make([PurchaseException('store down'), _ok]);
    iap.controller.add([_purchase()]);
    await _settle();
    expect(iap.completed, isEmpty);
    expect(
      c.read(creditPurchaseControllerProvider).notice!.kind,
      PurchaseNoticeKind.willRetry,
    );
    await c.read(creditPurchaseControllerProvider.notifier).retryPending();
    expect(api.calls, 2);
    expect(iap.completed, ['credits_100']);
  });

  test('already processed finishes the transaction', () async {
    final c = make([PurchaseException('dup', alreadyProcessed: true)]);
    iap.controller.add([_purchase()]);
    await _settle();
    expect(iap.completed, ['credits_100']);
    expect(
      c.read(creditPurchaseControllerProvider).notice!.kind,
      PurchaseNoticeKind.alreadyProcessed,
    );
  });

  test(
    'iOS without a numeric transaction id: error state, not finished',
    () async {
      final c = make([_ok]);
      iap.controller.add([_purchase(id: null)]);
      await _settle();
      expect(api.calls, 0);
      expect(iap.completed, isEmpty);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.proofMissing,
      );
    },
  );

  test('unknown products (neither pack nor plan) are ignored', () async {
    make([_ok]);
    iap.controller.add([_purchase(product: 'something_else')]);
    await _settle();
    expect(api.calls, 0);
    expect(subApi.calls, 0);
    expect(iap.completed, isEmpty);
  });

  group('subscriptions', () {
    test('iOS purchase goes to the subscription endpoint, finished after '
        'success', () async {
      final c = make([_ok]);
      iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
      await _settle();
      expect(api.calls, 0);
      expect(subApi.calls, 1);
      expect(subApi.lastPlanId, 3);
      expect(subApi.lastProof!.token, '1000000123');
      expect(subApi.lastProof!.receipt, 'receipt');
      expect(iap.completed, ['ios_pro_monthly']);
      expect(auth.refreshed, 1);
      final n = c.read(creditPurchaseControllerProvider).notice!;
      expect(n.kind, PurchaseNoticeKind.subscriptionActivated);
      expect(n.subscription, isTrue);
    });

    test('iOS does not match the Android product id', () async {
      make([_ok]);
      iap.controller.add([_purchase(product: 'pro_monthly')]);
      await _settle();
      expect(subApi.calls, 0);
      expect(iap.completed, isEmpty);
    });

    test('Android purchase uses the Play product id and token', () async {
      make([_ok], ios: false);
      iap.controller.add([_purchase(product: 'pro_monthly', id: 'GPA.1')]);
      await _settle();
      expect(subApi.calls, 1);
      expect(subApi.lastProof!.token, 'receipt');
      expect(iap.completed, ['pro_monthly']);
    });

    test('duplicate delivery verifies once', () async {
      make([_ok]);
      final p = _purchase(product: 'ios_pro_monthly');
      iap.controller.add([p]);
      iap.controller.add([p]);
      await _settle();
      iap.controller.add([p]);
      await _settle();
      expect(subApi.calls, 1);
      expect(iap.completed, ['ios_pro_monthly']);
    });

    test('restored is re-verified (idempotent) and finished', () async {
      final c = make([_ok]);
      iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
      await _settle();
      expect(subApi.calls, 1);
      iap.controller.add([
        _purchase(product: 'ios_pro_monthly', status: PurchaseStatus.restored),
      ]);
      await _settle();
      expect(subApi.calls, 2);
      expect(iap.completed, ['ios_pro_monthly', 'ios_pro_monthly']);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.subscriptionActivated,
      );
    });

    test('restored that the server already knows counts as success', () async {
      final c = make(
        [_ok],
        subScript: [
          SubscriptionPurchaseException('dup', alreadyProcessed: true),
        ],
      );
      iap.controller.add([
        _purchase(product: 'ios_pro_monthly', status: PurchaseStatus.restored),
      ]);
      await _settle();
      expect(iap.completed, ['ios_pro_monthly']);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.subscriptionActivated,
      );
    });

    test('iOS permanent 422 finishes the transaction', () async {
      final c = make(
        [_ok],
        subScript: [SubscriptionPurchaseException('bad', permanent: true)],
      );
      final p = _purchase(product: 'ios_pro_monthly');
      iap.controller.add([p]);
      await _settle();
      iap.controller.add([p]);
      await _settle();
      expect(subApi.calls, 1);
      expect(iap.completed, ['ios_pro_monthly']);
      final n = c.read(creditPurchaseControllerProvider).notice!;
      expect(n.kind, PurchaseNoticeKind.rejected);
      expect(n.subscription, isTrue);
    });

    test('Android permanent 422 stays pending (unchanged)', () async {
      final c = make(
        [_ok],
        ios: false,
        subScript: [SubscriptionPurchaseException('bad', permanent: true)],
      );
      iap.controller.add([_purchase(product: 'pro_monthly', id: 'GPA.1')]);
      await _settle();
      expect(iap.completed, isEmpty);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.willRetry,
      );
    });

    test('502 / network keeps it pending, a retry then activates', () async {
      final c = make(
        [_ok],
        subScript: [SubscriptionPurchaseException('down'), _subOk],
      );
      iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
      await _settle();
      expect(iap.completed, isEmpty);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.willRetry,
      );
      await c.read(creditPurchaseControllerProvider.notifier).retryPending();
      expect(subApi.calls, 2);
      expect(iap.completed, ['ios_pro_monthly']);
    });

    test('credit packs and subscriptions in one burst both succeed', () async {
      make([_ok]);
      iap.controller.add([
        _purchase(),
        _purchase(product: 'ios_pro_monthly', id: '1000000124'),
      ]);
      await _settle();
      expect(api.calls, 1);
      expect(subApi.calls, 1);
      expect(iap.completed, ['credits_100', 'ios_pro_monthly']);
    });
  });

  test('package list failure keeps the purchase for a later retry', () async {
    var fail = true;
    final c = make(
      [_ok],
      packages: () async {
        if (fail) throw Exception('offline');
        return [_pkg];
      },
    );
    iap.controller.add([_purchase()]);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(api.calls, 0);
    fail = false;
    await c.read(creditPurchaseControllerProvider.notifier).retryPending();
    await _settle();
    expect(api.calls, 1);
    expect(iap.completed, ['credits_100']);
  });

  test('store error and cancel clear the spinner and finish', () async {
    final c = make([_ok]);
    final n = c.read(creditPurchaseControllerProvider.notifier);
    n.beginBuy('credits_100');
    expect(c.read(creditPurchaseControllerProvider).pending, {'credits_100'});
    iap.controller.add([_purchase(status: PurchaseStatus.canceled)]);
    await _settle();
    expect(c.read(creditPurchaseControllerProvider).pending, isEmpty);
    expect(iap.completed, ['credits_100']);
    expect(api.calls, 0);
  });

  testWidgets('credit screen reflects the shared state (spinner, snackbar)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    iap = _FakeIap();
    auth = _Auth();
    api = _Api([_ok]);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          inAppPurchaseProvider.overrideWithValue(iap),
          purchaseIsIosProvider.overrideWithValue(true),
          authProvider.overrideWith(() => auth),
          purchaseApiProvider.overrideWithValue(api),
          homeProvider.overrideWith(_Home.new),
          creditPackageListProvider.overrideWith((ref) async => [_pkg]),
          storePricesProvider.overrideWith((ref, ids) async => {}),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CreditPackagesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreditPackagesScreen)),
    );
    container
        .read(creditPurchaseControllerProvider.notifier)
        .beginBuy('credits_100');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    iap.controller.add([_purchase()]);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.creditsAdded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(api.calls, 1);
  });
}
