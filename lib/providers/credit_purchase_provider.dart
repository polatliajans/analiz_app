import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/purchase_api.dart' show PurchaseException;
import '../data/purchase_payload.dart';
import '../models/credit_package.dart';
import '../utils/platform_info.dart';
import 'auth_provider.dart';
import 'credit_package_provider.dart';
import 'home_provider.dart';

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
  const PurchaseNotice(this.id, this.kind, [this.detail]);
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
/// even while the credit screen is closed. Screens only observe [state].
///
/// Idempotent: a purchase is processed once at a time and at most once per
/// run after it succeeded or was rejected; the server is idempotent too.
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

  void _notice(PurchaseNoticeKind kind, [String? detail]) {
    state = state.copyWith(notice: PurchaseNotice(++_noticeSeq, kind, detail));
  }

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
          _notice(PurchaseNoticeKind.storeFailed, '${p.error}');
        case PurchaseStatus.canceled:
          endBuy(p.productID);
          await _complete(p);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          endBuy(p.productID);
          _queue[_key(p)] = p;
          await _drain();
      }
    }
  }

  /// Re-tries every queued purchase (new session, screen opened, manual).
  Future<void> retryPending() => _drain();

  /// How long to wait for the package list before giving up for now
  /// (Riverpod keeps retrying a failing provider in the background).
  static Duration packageWait = const Duration(seconds: 15);

  Future<List<CreditPackage>?> _packages() async {
    final current = ref.read(creditPackageListProvider);
    if (current.hasValue) return current.value;
    if (current.hasError && !current.isLoading) return null;
    try {
      return await ref
          .read(creditPackageListProvider.future)
          .timeout(packageWait);
    } catch (_) {
      return null;
    }
  }

  Future<void> _drain() async {
    if (_queue.isEmpty) return;
    final token = ref.read(authProvider).token;
    if (token == null) return; // stays queued until login
    final packages = await _packages();
    if (!ref.mounted) return;
    if (packages == null) {
      // Package list not loaded (offline): try again on the next trigger.
      ref.invalidate(creditPackageListProvider);
      return;
    }
    for (final entry in _queue.entries.toList()) {
      final p = entry.value;
      CreditPackage? package;
      for (final c in packages) {
        if (c.storeProductId == p.productID) package = c;
      }
      if (package == null) {
        // Not a credit pack (e.g. a subscription handled by its own
        // screen): leave it alone.
        _queue.remove(entry.key);
        continue;
      }
      await _process(entry.key, p, package, token);
    }
  }

  Future<void> _process(
    String key,
    PurchaseDetails p,
    CreditPackage package,
    String token,
  ) async {
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
        _notice(PurchaseNoticeKind.proofMissing);
        return;
      }
      try {
        await ref
            .read(purchaseApiProvider)
            .verifyCreditPackagePurchase(
              token: token,
              creditPackageId: package.id,
              proof: proof,
            );
        await ref.read(authProvider.notifier).refreshMember();
        ref.read(homeProvider.notifier).refresh(force: true);
        // Finish only after the server confirmed the credit.
        await _complete(p);
        _finished.add(key);
        _queue.remove(key);
        _notice(PurchaseNoticeKind.credited);
      } on PurchaseException catch (e) {
        if (e.alreadyProcessed) {
          await _complete(p);
          _finished.add(key);
          _queue.remove(key);
          _notice(PurchaseNoticeKind.alreadyProcessed, e.message);
        } else if (ios && e.permanent) {
          // Invalid / refunded: retrying never helps, and an unfinished
          // transaction would be redelivered (and rejected) forever.
          await _complete(p);
          _finished.add(key);
          _queue.remove(key);
          _notice(PurchaseNoticeKind.rejected, e.message);
        } else {
          // 502 / network: keep it pending for a retry.
          _notice(PurchaseNoticeKind.willRetry, e.message);
        }
      } catch (e) {
        _notice(PurchaseNoticeKind.willRetry, '$e');
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
