import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription_plan.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Tracks which store product IDs currently have a buy in flight, purely to
  // drive the busy spinner in the UI. This is NOT used to decide which
  // plan gets activated — that is resolved from `purchase.productID`
  // against the fetched plan list, so tap order / concurrent purchases
  // can never misattribute an activation.
  final Set<String> _pendingProductIds = {};

  @override
  void initState() {
    super.initState();
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  SubscriptionPlan? _resolvePlan(String productId) {
    final plans = ref.read(subscriptionPlanListProvider).value;
    if (plans == null) return null;
    for (final plan in plans) {
      if (plan.storeProductIdAndroid == productId) {
        return plan;
      }
    }
    return null;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        setState(() => _pendingProductIds.remove(purchase.productID));
        // No successful charge occurred here, so it's safe to acknowledge
        // and clear this transaction instead of leaving it pending forever.
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Satın alma başarısız: ${purchase.error}')),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        setState(() => _pendingProductIds.remove(purchase.productID));

        // Identify which plan this purchase belongs to strictly from the
        // data Google Play echoes back on the purchase itself, never from
        // mutable UI state — this is what makes activation correct regardless
        // of tap order or overlapping purchases.
        final plan = _resolvePlan(purchase.productID);
        final auth = ref.read(authProvider);

        if (plan == null || auth.token == null) {
          // Unrecognized product (plans not loaded yet, stale product id,
          // no session, etc). Deliberately do NOT complete the purchase:
          // leaving it unfinished means Google Play will redeliver it via
          // purchaseStream on the next app start, giving a real retry path
          // instead of silently losing the paid subscription.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Satın alma doğrulanamadı, abonelik planı bilgisi bulunamadı. Uygulamayı yeniden açtığınızda tekrar denenecek.'),
              ),
            );
          }
          continue;
        }

        try {
          await ref.read(subscriptionPurchaseApiProvider).verifySubscriptionPurchase(
                token: auth.token!,
                subscriptionPlanId: plan.id,
                purchaseToken: purchase.verificationData.serverVerificationData,
              );
          await ref.read(authProvider.notifier).refreshMember();

          // Only complete/consume the purchase once the server has actually
          // confirmed and activated it. If verification throws below, we skip
          // this entirely and leave the purchase pending for retry.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pro aboneliğiniz aktifleştirildi.')),
            );
          }
        } catch (e) {
          // Verification failed (network blip, 502, 422, timeout, ...).
          // Do NOT complete the purchase here — the user already paid, and
          // leaving it unfinished lets Google Play redeliver the same
          // purchase for another verification attempt instead of losing it.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e Satın alma tekrar denenecek.')),
            );
          }
        }
      }
    }
  }

  Future<void> _buy(int planId, String productId) async {
    // Guard re-entrancy before any await: a fast double-tap on the same
    // plan's button must not fire buyNonConsumable twice.
    if (_pendingProductIds.contains(productId)) {
      return;
    }
    setState(() => _pendingProductIds.add(productId));

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        setState(() => _pendingProductIds.remove(productId));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alma servisi kullanılamıyor.')),
        );
        return;
      }

      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        setState(() => _pendingProductIds.remove(productId));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün mağazada bulunamadı.')),
        );
        return;
      }

      final param = PurchaseParam(productDetails: response.productDetails.first);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        // Request was not even submitted to Play Billing; no stream event
        // will arrive for it, so clear the busy marker immediately.
        setState(() => _pendingProductIds.remove(productId));
      }
    } catch (e) {
      // Any thrown error from the platform (e.g. a PlatformException from
      // buyNonConsumable) must still release the busy marker — otherwise this
      // plan's buy button would be stuck spinning for the rest of the
      // app session.
      setState(() => _pendingProductIds.remove(productId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alma başlatılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlanListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pro Abonelik')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Bir hata oluştu: $error')),
        data: (plans) => ListView.builder(
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final productId = plan.storeProductIdAndroid;
            final isBusy = productId != null && _pendingProductIds.contains(productId);
            return ListTile(
              title: Text(plan.name),
              subtitle: Text('${plan.durationDays} gün'),
              trailing: isBusy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: productId == null ? null : () => _buy(plan.id, productId),
                      child: Text('${plan.price} ₺'),
                    ),
            );
          },
        ),
      ),
    );
  }
}
