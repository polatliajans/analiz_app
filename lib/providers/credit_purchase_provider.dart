import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/purchase_api.dart' show PurchaseException;
import '../data/purchase_payload.dart';
import '../data/subscription_purchase_api.dart'
    show SubscriptionPurchaseException;
import '../models/credit_package.dart';
import '../models/subscription_plan.dart';
import '../utils/platform_info.dart';
import 'auth_provider.dart';
import 'credit_package_provider.dart';
import 'home_provider.dart';
import 'subscription_provider.dart';

/// The store plugin; overridden with a fake in tests.
final inAppPurchaseProvider = Provider<InAppPurchase>(
  (ref) => InAppPurchase.instance,
);

/// Whether the purchase handling runs the iOS rules (permanent server
/// rejections finish the transaction; a missing transaction id is an error).
final purchaseIsIosProvider = Provider<bool>((ref) => isIOS);

enum PurchaseNoticeKind {
  /// Credited; the balance was refreshed.
  credited,

  /// A Pro subscription was activated (bought or restored); the member was
  /// refreshed.
  subscriptionActivated,

  /// The server had already credited it; the transaction was finished.
  alreadyProcessed,

  /// Permanently rejected by the server (iOS: transaction finished).
  rejected,

  /// Temporary problem (network / store verification down): stays pending.
  willRetry,

  /// The store reported a failed purchase.
  storeFailed,

  /// iOS transaction without a usable id: stays pending.
  proofMissing,
}

/// One message for the UI. [id] makes every notice unique so listeners
/// react once per event.
class PurchaseNotice {
  final int id;
  final PurchaseNoticeKind kind;
  final String? detail;

  /// The notice is about a Pro subscription (shown by the Pro screen); false
  /// for credit packs (shown by the credit shop).
  final bool subscription;
  const PurchaseNotice(
    this.id,
    this.kind, [
    this.detail,
    this.subscription = false,
  ]);
}

class CreditPurchaseState {
  /// Store product ids with a buy in flight (drives the busy spinners).
  final Set<String> pending;
  final PurchaseNotice? notice;
  const CreditPurchaseState({this.pending = const {}, this.notice});

  CreditPurchaseState copyWith({
    Set<String>? pending,
    PurchaseNotice? notice,
  }) => CreditPurchaseState(
    pending: pending ?? this.pending,
    notice: notice ?? this.notice,
  );
}

/// Listens to the store's purchase stream for the whole app run (started at
/// launch from the root widget), so transactions StoreKit/Play re-deliver
/// at start (e.g. the app was killed after paying) are verified and credited
/// even while the credit screen is closed. Credit packs and Pro subscriptions
/// are both handled here (by the product's type, resolved from the package /
/// plan lists); screens only observe [state].
///
/// Idempotent: a purchase is processed once at a time and at most once per
/// run after it succeeded or was rejected (a user-requested restore is
/// verified again); the server is idempotent too.
class CreditPurchaseController extends Notifier<CreditPurchaseState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Purchases waiting for a session / the package list, by [_key].
  final Map<String, PurchaseDetails> _queue = {};
  final Set<String> _inFlight = {};
  final Set<String> _finished = {};
  int _noticeSeq = 0;

  @override
  CreditPurchaseState build() {
    ref.onDispose(() => _sub?.cancel());
    try {
      _sub = ref
          .read(inAppPurchaseProvider)
          .purchaseStream
          .listen(_onUpdate, onError: (_) {});
    } catch (_) {
      // Store plugin unavailable (tests, unsupported platform).
    }
    // A purchase that arrived before login is processed once the session
    // exists.
    ref.listen(authProvider.select((a) => a.token), (prev, next) {
      if (next != null) unawaited(retryPending());
    });
    return const CreditPurchaseState();
  }

  String _key(PurchaseDetails p) =>
      p.purchaseID ??
      '${p.productID}:${p.verificationData.serverVerificationData.hashCode}';

  void beginBuy(String productId) =>
      state = state.copyWith(pending: {...state.pending, productId});

  void endBuy(String productId) =>
      state = state.copyWith(pending: {...state.pending}..remove(productId));

  void _notice(
    PurchaseNoticeKind kind, [
    String? detail,
    bool subscription = false,
  ]) {
    state = state.copyWith(
      notice: PurchaseNotice(++_noticeSeq, kind, detail, subscription),
    );
  }

  TargetPlatform get _platform => ref.read(purchaseIsIosProvider)
      ? TargetPlatform.iOS
      : TargetPlatform.android;

  SubscriptionPlan? _planFor(String productId, List<SubscriptionPlan>? plans) {
    if (plans == null) return null;
    for (final plan in plans) {
      if (plan.productIdFor(_platform) == productId) return plan;
    }
    return null;
  }

  /// Best effort (cached plan list only): is [productId] a Pro plan?
  bool _isSubscriptionProduct(String productId) =>
      _planFor(productId, ref.read(subscriptionPlanListProvider).value) != null;

  /// App Store: asks StoreKit to replay the user's past transactions. They
  /// arrive on the purchase stream as `restored` and are re-verified with the
  /// server (idempotent there).
  Future<void> restorePurchases() =>
      ref.read(inAppPurchaseProvider).restorePurchases();

  Future<void> _complete(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    try {
      await ref.read(inAppPurchaseProvider).completePurchase(p);
    } catch (_) {}
  }

  Future<void> _onUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.error:
          endBuy(p.productID);
          // Nothing was charged: acknowledge so it leaves the queue.
          await _complete(p);
          _notice(
            PurchaseNoticeKind.storeFailed,
            '${p.error}',
            _isSubscriptionProduct(p.productID),
          );
        case PurchaseStatus.canceled:
          endBuy(p.productID);
          await _complete(p);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          endBuy(p.productID);
          // A restore is an explicit user action: verify it again even if
          // this transaction was already finished earlier in this run.
          if (p.status == PurchaseStatus.restored) _finished.remove(_key(p));
          _queue[_key(p)] = p;
          await _drain();
      }
    }
  }

  /// Re-tries every queued purchase (new session, screen opened, manual).
  Future<void> retryPending() => _drain();

  /// How long to wait for the package / plan list before giving up for now
  /// (Riverpod keeps retrying a failing provider in the background).
  static Duration packageWait = const Duration(seconds: 15);

  Future<List<T>?> _loaded<T>(FutureProvider<List<T>> provider) async {
    final current = ref.read(provider);
    if (current.hasValue) return current.value;
    if (current.hasError && !current.isLoading) return null;
    try {
      return await ref.read(provider.future).timeout(packageWait);
    } catch (_) {
      return null;
    }
  }

  Future<void> _drain() async {
    if (_queue.isEmpty) return;
    final token = ref.read(authProvider).token;
    if (token == null) return; // stays queued until login
    final packages = await _loaded(creditPackageListProvider);
    if (!ref.mounted) return;

    CreditPackage? packageOf(PurchaseDetails p) {
      for (final c in packages ?? const <CreditPackage>[]) {
        if (c.storeProductId == p.productID) return c;
      }
      return null;
    }

    // The plan list is only needed for products that are not credit packs.
    List<SubscriptionPlan>? plans;
    var plansTried = false;
    if (_queue.values.any((p) => packageOf(p) == null)) {
      plansTried = true;
      plans = await _loaded(subscriptionPlanListProvider);
      if (!ref.mounted) return;
    }

    for (final entry in _queue.entries.toList()) {
      final p = entry.value;
      final package = packageOf(p);
      if (package != null) {
        await _process(
          entry.key,
          p,
          subscription: false,
          verify: (proof) async {
            await ref
                .read(purchaseApiProvider)
                .verifyCreditPackagePurchase(
                  token: token,
                  creditPackageId: package.id,
                  proof: proof,
                );
          },
        );
        continue;
      }
      final plan = _planFor(p.productID, plans);
      if (plan != null) {
        await _process(
          entry.key,
          p,
          subscription: true,
          verify: (proof) async {
            await ref
                .read(subscriptionPurchaseApiProvider)
                .verifySubscriptionPurchase(
                  token: token,
                  subscriptionPlanId: plan.id,
                  proof: proof,
                );
          },
        );
        continue;
      }
      if (packages != null && plans != null) {
        // Neither a credit pack nor a Pro plan we know: leave it alone.
        _queue.remove(entry.key);
      }
    }
    // A list that could not be loaded (offline): try again on the next
    // trigger, with the purchases still queued.
    if (packages == null) ref.invalidate(creditPackageListProvider);
    if (plansTried && plans == null) {
      ref.invalidate(subscriptionPlanListProvider);
    }
  }

  Future<void> _process(
    String key,
    PurchaseDetails p, {
    required bool subscription,
    required Future<void> Function(PurchaseProof proof) verify,
  }) async {
    if (_finished.contains(key)) {
      _queue.remove(key);
      return;
    }
    if (!_inFlight.add(key)) return;
    try {
      final ios = ref.read(purchaseIsIosProvider);
      final proof = purchaseProofOf(p, ios: ios);
      if (proof == null) {
        // iOS without a numeric transaction id: never guess a token.
        // Left unfinished; the store redelivers it on the next launch.
        _queue.remove(key);
        _notice(PurchaseNoticeKind.proofMissing, null, subscription);
        return;
      }

      Future<void> finish(PurchaseNoticeKind kind, [String? detail]) async {
        await _complete(p);
        _finished.add(key);
        _queue.remove(key);
        _notice(kind, detail, subscription);
      }

      Future<void> failed(
        String message, {
        required bool alreadyProcessed,
        required bool permanent,
      }) async {
        if (alreadyProcessed) {
          // A restored subscription the server already knows is a success
          // for the user.
          if (subscription && p.status == PurchaseStatus.restored) {
            await finish(PurchaseNoticeKind.subscriptionActivated);
          } else {
            await finish(PurchaseNoticeKind.alreadyProcessed, message);
          }
        } else if (ios && permanent) {
          // Invalid / refunded: retrying never helps, and an unfinished
          // transaction would be redelivered (and rejected) forever.
          await finish(PurchaseNoticeKind.rejected, message);
        } else {
          // 502 / network: keep it pending for a retry.
          _notice(PurchaseNoticeKind.willRetry, message, subscription);
        }
      }

      try {
        await verify(proof);
        await ref.read(authProvider.notifier).refreshMember();
        ref.read(homeProvider.notifier).refresh(force: true);
        // Finish only after the server confirmed the credit / activation.
        await finish(
          subscription
              ? PurchaseNoticeKind.subscriptionActivated
              : PurchaseNoticeKind.credited,
        );
      } on PurchaseException catch (e) {
        await failed(
          e.message,
          alreadyProcessed: e.alreadyProcessed,
          permanent: e.permanent,
        );
      } on SubscriptionPurchaseException catch (e) {
        await failed(
          e.message,
          alreadyProcessed: e.alreadyProcessed,
          permanent: e.permanent,
        );
      } catch (e) {
        _notice(PurchaseNoticeKind.willRetry, '$e', subscription);
      }
    } finally {
      _inFlight.remove(key);
    }
  }
}

final creditPurchaseControllerProvider =
    NotifierProvider<CreditPurchaseController, CreditPurchaseState>(
      CreditPurchaseController.new,
    );
