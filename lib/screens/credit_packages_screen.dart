import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../l10n/app_localizations.dart';
import '../models/credit_package.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_package_provider.dart';
import '../providers/store_price_provider.dart';

class CreditPackagesScreen extends ConsumerStatefulWidget {
  const CreditPackagesScreen({super.key});

  @override
  ConsumerState<CreditPackagesScreen> createState() =>
      _CreditPackagesScreenState();
}

class _CreditPackagesScreenState extends ConsumerState<CreditPackagesScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Tracks which store product IDs currently have a buy in flight, purely to
  // drive the busy spinner in the UI. This is NOT used to decide which
  // package gets credited — that is resolved from `purchase.productID`
  // against the fetched package list, so tap order / concurrent purchases
  // can never misattribute a credit.
  final Set<String> _pendingProductIds = {};

  @override
  void initState() {
    super.initState();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  CreditPackage? _resolvePackage(String productId) {
    final packages = ref.read(creditPackageListProvider).value;
    if (packages == null) return null;
    for (final package in packages) {
      if (package.storeProductIdAndroid == productId) {
        return package;
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.purchaseFailed('${purchase.error}'),
            ),
          ),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        setState(() => _pendingProductIds.remove(purchase.productID));

        // Identify which package this purchase belongs to strictly from the
        // data Google Play echoes back on the purchase itself, never from
        // mutable UI state — this is what makes crediting correct regardless
        // of tap order or overlapping purchases.
        final package = _resolvePackage(purchase.productID);
        final auth = ref.read(authProvider);

        if (package == null || auth.token == null) {
          // Unrecognized product (packages not loaded yet, stale product id,
          // no session, etc). Deliberately do NOT complete the purchase:
          // leaving it unfinished means Google Play will redeliver it via
          // purchaseStream on the next app start, giving a real retry path
          // instead of silently losing the paid credit.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.purchaseNoPackage),
              ),
            );
          }
          continue;
        }

        try {
          await ref
              .read(purchaseApiProvider)
              .verifyCreditPackagePurchase(
                token: auth.token!,
                creditPackageId: package.id,
                purchaseToken: purchase.verificationData.serverVerificationData,
              );
          await ref.read(authProvider.notifier).refreshMember();

          // Only complete/consume the purchase once the server has actually
          // confirmed and credited it. If verification throws below, we skip
          // this entirely and leave the purchase pending for retry.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.creditsAdded),
              ),
            );
          }
        } catch (e) {
          // Verification failed (network blip, 502, 422, timeout, ...).
          // Do NOT complete the purchase here — the user already paid, and
          // leaving it unfinished lets Google Play redeliver the same
          // purchase for another verification attempt instead of losing it.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.purchaseWillRetry('$e'),
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _buy(int packageId, String productId) async {
    // Guard re-entrancy before any await: a fast double-tap on the same
    // package's button must not fire buyConsumable twice.
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.purchaseServiceUnavailable,
            ),
          ),
        );
        return;
      }

      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        setState(() => _pendingProductIds.remove(productId));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.productNotFound),
          ),
        );
        return;
      }

      final param = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      final started = await _iap.buyConsumable(purchaseParam: param);
      if (!started) {
        // Request was not even submitted to Play Billing; no stream event
        // will arrive for it, so clear the busy marker immediately.
        setState(() => _pendingProductIds.remove(productId));
      }
    } catch (e) {
      // Any thrown error from the platform (e.g. a PlatformException from
      // buyConsumable) must still release the busy marker — otherwise this
      // package's buy button would be stuck spinning for the rest of the
      // app session.
      setState(() => _pendingProductIds.remove(productId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.purchaseStartFailed('$e'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packagesAsync = ref.watch(creditPackageListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.buyCredits)),
      body: packagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(AppLocalizations.of(context)!.errorOccurred('$error')),
        ),
        data: (packages) {
          final storePrices =
              ref
                  .watch(
                    storePricesProvider(
                      packages
                          .map((p) => p.storeProductIdAndroid)
                          .whereType<String>()
                          .join(','),
                    ),
                  )
                  .value ??
              const <String, String>{};

          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              final productId = package.storeProductIdAndroid;
              final isBusy =
                  productId != null && _pendingProductIds.contains(productId);
              return ListTile(
                title: Text(package.name),
                subtitle: Text(l10n.creditsCount(package.creditAmount)),
                trailing: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: productId == null
                            ? null
                            : () => _buy(package.id, productId),
                        child: Text(
                          storePrices[productId] ?? '${package.price} ₺',
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
