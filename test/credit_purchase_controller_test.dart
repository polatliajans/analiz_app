import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
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
  int restores = 0;

  /// What a restore delivers on the purchase stream while it runs.
  List<PurchaseDetails> restoreEmits = const [];

  /// Never completes when true (a store without a completion signal).
  bool restoreHangs = false;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    if (restoreHangs) return Completer<void>().future;
    if (restoreEmits.isNotEmpty) controller.add(restoreEmits);
  }

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
  CreditPurchaseController.retryBackoff = const [];
  CreditPurchaseController.restoreGrace = Duration.zero;
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

  group('iOS hardening', () {
    AppStorePurchaseDetails sk({
      required PurchaseStatus status,
      String? id = '2000000999',
      String? original,
      String product = 'ios_pro_monthly',
    }) {
      final p = AppStorePurchaseDetails(
        purchaseID: id,
        productID: product,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'l',
          serverVerificationData: 'receipt',
          source: 'app_store',
        ),
        transactionDate: '0',
        status: status,
        skPaymentTransaction: SKPaymentTransactionWrapper(
          payment: SKPaymentWrapper(productIdentifier: product),
          transactionState: SKPaymentTransactionStateWrapper.restored,
          transactionIdentifier: id,
          originalTransaction: original == null
              ? null
              : SKPaymentTransactionWrapper(
                  payment: SKPaymentWrapper(productIdentifier: product),
                  transactionState: SKPaymentTransactionStateWrapper.purchased,
                  transactionIdentifier: original,
                ),
        ),
      );
      p.pendingCompletePurchase = true;
      return p;
    }

    const backoff = [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ];

    test('restored uses the ORIGINAL transaction id (subscription)', () async {
      make([_ok]);
      iap.controller.add([
        sk(status: PurchaseStatus.restored, original: '1000000777'),
      ]);
      await _settle();
      expect(subApi.lastProof!.token, '1000000777');
    });

    test('restored uses the ORIGINAL transaction id (consumable)', () async {
      make([_ok]);
      iap.controller.add([
        sk(
          status: PurchaseStatus.restored,
          original: '1000000555',
          product: 'credits_100',
        ),
      ]);
      await _settle();
      expect(api.lastProof!.token, '1000000555');
    });

    test('restored without an original falls back to its own id', () async {
      make([_ok]);
      iap.controller.add([sk(status: PurchaseStatus.restored)]);
      await _settle();
      expect(subApi.lastProof!.token, '2000000999');
    });

    test('a fresh purchase keeps its own id even with an original', () async {
      make([_ok]);
      iap.controller.add([
        sk(status: PurchaseStatus.purchased, original: '1000000777'),
      ]);
      await _settle();
      expect(subApi.lastProof!.token, '2000000999');
    });

    test('a non-numeric original id is still rejected', () async {
      final c = make([_ok]);
      iap.controller.add([
        sk(status: PurchaseStatus.restored, original: 'abc'),
      ]);
      await _settle();
      expect(subApi.calls, 0);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.proofMissing,
      );
    });

    test('transient failures are retried with backoff, then succeed', () {
      fakeAsync((async) {
        CreditPurchaseController.retryBackoff = backoff;
        addTearDown(() => CreditPurchaseController.retryBackoff = const []);
        final c = make(
          [_ok],
          subScript: [
            SubscriptionPurchaseException('502'),
            SubscriptionPurchaseException('502'),
            _subOk,
          ],
        );
        iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
        async.elapse(const Duration(milliseconds: 500));
        expect(subApi.calls, 1);
        async.elapse(const Duration(seconds: 2));
        expect(subApi.calls, 2);
        expect(iap.completed, isEmpty);
        async.elapse(const Duration(seconds: 5));
        expect(subApi.calls, 3);
        expect(iap.completed, ['ios_pro_monthly']);
        expect(
          c.read(creditPurchaseControllerProvider).notice!.kind,
          PurchaseNoticeKind.subscriptionActivated,
        );
      });
    });

    test('after the retries are used up it stays pending (willRetry)', () {
      fakeAsync((async) {
        CreditPurchaseController.retryBackoff = backoff;
        addTearDown(() => CreditPurchaseController.retryBackoff = const []);
        final c = make(
          [_ok],
          subScript: [SubscriptionPurchaseException('502')],
        );
        iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
        async.elapse(const Duration(seconds: 30));
        expect(subApi.calls, 4); // first try + 3 retries
        expect(iap.completed, isEmpty);
        expect(
          c.read(creditPurchaseControllerProvider).notice!.kind,
          PurchaseNoticeKind.willRetry,
        );
      });
    });

    test('permanent rejections are not retried', () {
      fakeAsync((async) {
        CreditPurchaseController.retryBackoff = backoff;
        addTearDown(() => CreditPurchaseController.retryBackoff = const []);
        make(
          [_ok],
          subScript: [SubscriptionPurchaseException('bad', permanent: true)],
        );
        iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
        async.elapse(const Duration(seconds: 30));
        expect(subApi.calls, 1);
        expect(iap.completed, ['ios_pro_monthly']);
      });
    });

    test('bound to another account: finished, specific notice', () async {
      final c = make(
        [_ok],
        subScript: [
          SubscriptionPurchaseException(
            'linked',
            permanent: true,
            code: 'subscription_bound_to_other_account',
          ),
        ],
      );
      iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
      await _settle();
      expect(iap.completed, ['ios_pro_monthly']);
      expect(subApi.calls, 1);
      expect(
        c.read(creditPurchaseControllerProvider).notice!.kind,
        PurchaseNoticeKind.boundToOtherAccount,
      );
    });

    test('active subscription at the other store: finished + notice', () async {
      final c = make(
        [_ok],
        subScript: [
          SubscriptionPurchaseException(
            'use Google Play',
            permanent: true,
            code: 'subscription_active_other_store',
          ),
        ],
      );
      iap.controller.add([_purchase(product: 'ios_pro_monthly')]);
      await _settle();
      expect(iap.completed, ['ios_pro_monthly']);
      final n = c.read(creditPurchaseControllerProvider).notice!;
      expect(n.kind, PurchaseNoticeKind.activeOtherStore);
      expect(n.detail, 'use Google Play');
      expect(n.subscription, isTrue);
    });

    test('restore with nothing delivered reports false', () async {
      final c = make([_ok]);
      final found = await c
          .read(creditPurchaseControllerProvider.notifier)
          .restorePurchases();
      expect(iap.restores, 1);
      expect(found, isFalse);
    });

    test('restore that delivers a purchase reports true', () async {
      final c = make([_ok]);
      iap.restoreEmits = [
        _purchase(product: 'ios_pro_monthly', status: PurchaseStatus.restored),
      ];
      final found = await c
          .read(creditPurchaseControllerProvider.notifier)
          .restorePurchases();
      expect(found, isTrue);
    });

    test('restore without a completion signal gives up after the timeout', () {
      fakeAsync((async) {
        final c = make([_ok]);
        iap.restoreHangs = true;
        bool? found;
        c
            .read(creditPurchaseControllerProvider.notifier)
            .restorePurchases()
            .then((v) => found = v);
        async.elapse(const Duration(seconds: 5));
        expect(found, isNull);
        async.elapse(const Duration(seconds: 2));
        expect(found, isFalse);
      });
    });
  });
}
