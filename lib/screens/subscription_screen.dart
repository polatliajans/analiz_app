import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/subscription_purchase_api.dart'
    show SubscriptionPurchaseException;
import '../data/purchase_payload.dart';
import '../l10n/app_localizations.dart';
import '../models/subscription_plan.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/store_price_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/platform_info.dart';
import '../utils/pro_purchase.dart';
import '../widgets/brand_page.dart';
import '../widgets/legal_links_row.dart';

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
    // Status view only where Pro cannot be bought: nothing to listen to.
    if (!ref.read(proPurchaseAvailableProvider)) return;
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

  SubscriptionPlan? _resolvePlan(String productId) {
    final plans = ref.read(subscriptionPlanListProvider).value;
    if (plans == null) return null;
    for (final plan in plans) {
      if (plan.storeProductId == productId) {
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.purchaseFailed('${purchase.error}'),
            ),
          ),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        // The user backed out of the store sheet: release the busy marker and
        // finish the (uncharged) transaction.
        setState(() => _pendingProductIds.remove(purchase.productID));
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
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
              SnackBar(
                content: Text(AppLocalizations.of(context)!.purchaseNoPlan),
              ),
            );
          }
          continue;
        }

        try {
          await ref
              .read(subscriptionPurchaseApiProvider)
              .verifySubscriptionPurchase(
                token: auth.token!,
                subscriptionPlanId: plan.id,
                proof: purchaseProofOf(purchase),
              );
          await ref.read(authProvider.notifier).refreshMember();
          // Home shows the balance/Pro state from its own cached payload; refresh it too.
          ref.read(homeProvider.notifier).refresh(force: true);

          // Only complete/consume the purchase once the server has actually
          // confirmed and activated it. If verification throws below, we skip
          // this entirely and leave the purchase pending for retry.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.proActivated),
              ),
            );
          }
        } on SubscriptionPurchaseException catch (e) {
          if (!e.alreadyProcessed) {
            _showRetry(e);
            continue;
          }
          // Already activated on the server earlier: finish the store
          // transaction so it is not redelivered forever.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.message)));
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

  /// App Store: replays the user's past subscription transactions through the
  /// purchase stream (handled like a normal purchase, verified by the server).
  Future<void> _restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.restorePurchasesFailed),
        ),
      );
    }
  }

  void _showRetry(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.purchaseWillRetry('$e')),
      ),
    );
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
    // Where Pro cannot be bought (iOS v1) this page is only a status view for
    // members who are already Pro: no plans are fetched, no price, no buy or
    // restore button.
    final canBuy = ref.watch(proPurchaseAvailableProvider);
    final plansAsync = canBuy
        ? ref.watch(subscriptionPlanListProvider)
        : const AsyncData<List<SubscriptionPlan>>([]);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proSubscription)),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)!.errorOccurred('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (plans) {
          final storePrices =
              ref
                  .watch(
                    storePricesProvider(
                      plans
                          .map((p) => p.storeProductId)
                          .whereType<String>()
                          .join(','),
                    ),
                  )
                  .value ??
              const <String, String>{};

          // The monthly credit shown in the benefits is the plan's own value
          // (the server tops the member up to it), never a hard-coded number.
          final monthlyCredit = plans.fold<int>(
            0,
            (m, p) => p.monthlyCredit > m ? p.monthlyCredit : m,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              BrandHero(
                icon: Icons.workspace_premium_rounded,
                title: 'CryptoAnaliz Pro',
                tagline: l10n.subTagline,
              ),
              const SizedBox(height: 20),
              if (isPro) ...[
                _AlreadyProCard(
                  title: l10n.subAlreadyProTitle,
                  body: isIOS
                      ? l10n.subAlreadyProBodyIos
                      : l10n.subAlreadyProBody,
                ),
                const SizedBox(height: 20),
              ],
              BrandSectionHeading(l10n.proUpsellBenefitsHeading),
              const SizedBox(height: 8),
              BrandBenefitsCard(
                benefits: [
                  if (monthlyCredit > 0)
                    BrandBenefit(
                      Icons.toll_rounded,
                      l10n.subBenefitCreditsTitle(monthlyCredit),
                      l10n.subBenefitCreditsDesc,
                    ),
                  BrandBenefit(
                    Icons.query_stats_rounded,
                    l10n.proBenefitDeepAnalysis,
                    l10n.subBenefitDeepDesc,
                  ),
                  BrandBenefit(
                    Icons.notifications_active_rounded,
                    l10n.proBenefitAlerts,
                    l10n.subBenefitAlertsDesc,
                  ),
                  BrandBenefit(
                    Icons.speed_rounded,
                    l10n.proBenefitTimeframes,
                    l10n.subBenefitTimeframesDesc,
                  ),
                  BrandBenefit(
                    Icons.block_rounded,
                    l10n.proBenefitNoAds,
                    l10n.subBenefitNoAdsDesc,
                  ),
                ],
              ),
              if (!isPro && canBuy) ...[
                const SizedBox(height: 24),
                BrandSectionHeading(l10n.subPlansHeading),
                const SizedBox(height: 8),
                for (final plan in plans)
                  _PlanCard(
                    plan: plan,
                    priceText:
                        storePrices[plan.storeProductId] ??
                        ((double.tryParse(plan.price) ?? 0) > 0
                            ? '\$${plan.price}'
                            : l10n.buy),
                    isBusy:
                        plan.storeProductId != null &&
                        _pendingProductIds.contains(plan.storeProductId),
                    onBuy: plan.storeProductId == null
                        ? null
                        : () => _buy(plan.id, plan.storeProductId!),
                  ),
              ],
              const SizedBox(height: 8),
              if (canBuy || isPro)
                Text(
                  isIOS ? l10n.subCancelNoteIos : l10n.subCancelNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (isIOS && canBuy)
                TextButton(
                  key: const Key('restore-purchases'),
                  onPressed: _restore,
                  child: Text(l10n.restorePurchases),
                ),
              const LegalLinksRow(),
            ],
          );
        },
      ),
    );
  }
}

class _AlreadyProCard extends StatelessWidget {
  final String title;
  final String body;
  const _AlreadyProCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String priceText;
  final bool isBusy;
  final VoidCallback? onBuy;

  const _PlanCard({
    required this.plan,
    required this.priceText,
    required this.isBusy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandTeal.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plan.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            priceText,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.durationDays(plan.durationDays),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isBusy ? null : onBuy,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: brandTeal,
              foregroundColor: Colors.black,
              disabledBackgroundColor: brandTeal.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    l10n.subscribe,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
