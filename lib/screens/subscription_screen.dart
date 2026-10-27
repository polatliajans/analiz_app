import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';
import '../models/subscription_plan.dart';
import '../providers/credit_purchase_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/store_price_provider.dart';
import '../providers/store_product_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/pro_purchase.dart';
import '../utils/subscription_period.dart';
import '../widgets/brand_page.dart';
import '../widgets/legal_links_row.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  // The purchase stream is listened to app-wide (creditPurchaseController),
  // which verifies subscriptions with the server too; this screen only starts
  // buys / restores and reflects the shared state (busy markers, notices).

  @override
  void initState() {
    super.initState();
    // Anything left unverified (offline earlier, plans not loaded) gets
    // another try as soon as the user opens the Pro page.
    Future.microtask(() {
      if (mounted && ref.read(proPurchaseAvailableProvider)) {
        ref.read(creditPurchaseControllerProvider.notifier).retryPending();
      }
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _onNotice(PurchaseNotice notice) {
    // Credit-pack notices belong to the credit shop.
    if (!notice.subscription) return;
    final l10n = AppLocalizations.of(context)!;
    switch (notice.kind) {
      case PurchaseNoticeKind.subscriptionActivated:
      case PurchaseNoticeKind.credited:
        _snack(l10n.proActivated);
      case PurchaseNoticeKind.alreadyProcessed:
      case PurchaseNoticeKind.rejected:
        _snack(notice.detail ?? '');
      case PurchaseNoticeKind.willRetry:
        _snack(l10n.purchaseWillRetry(notice.detail ?? ''));
      case PurchaseNoticeKind.storeFailed:
        _snack(l10n.purchaseFailed(notice.detail ?? ''));
      case PurchaseNoticeKind.proofMissing:
        _snack(l10n.purchaseProofMissing);
      case PurchaseNoticeKind.boundToOtherAccount:
        _snack(l10n.purchaseBoundToOtherAccount);
      case PurchaseNoticeKind.activeOtherStore:
        _snack(notice.detail ?? '');
    }
  }

  /// App Store: replays the user's past subscription transactions through the
  /// purchase stream (handled like a normal purchase, verified by the server).
  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    final failed = l10n.restorePurchasesFailed;
    final nothing = l10n.restoreNothingToRestore;
    try {
      final found = await ref
          .read(creditPurchaseControllerProvider.notifier)
          .restorePurchases();
      if (!found) _snack(nothing);
    } catch (_) {
      _snack(failed);
    }
  }

  Future<void> _manageSubscription() async {
    final failed = AppLocalizations.of(context)!.deleteAccountOpenFailedIos;
    var ok = false;
    try {
      ok = await launchUrl(
        LegalLinks.appStoreSubscriptions,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) _snack(failed);
  }

  Future<void> _buy(String productId) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(creditPurchaseControllerProvider.notifier);
    // Guard re-entrancy before any await: a fast double-tap on the same
    // plan's button must not fire buyNonConsumable twice.
    if (ref
        .read(creditPurchaseControllerProvider)
        .pending
        .contains(productId)) {
      return;
    }
    controller.beginBuy(productId);
    final iap = ref.read(inAppPurchaseProvider);

    try {
      final available = await iap.isAvailable();
      if (!available) {
        controller.endBuy(productId);
        _snack(l10n.purchaseServiceUnavailable);
        return;
      }

      final response = await iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        controller.endBuy(productId);
        _snack(l10n.productNotFound);
        return;
      }

      final param = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      final started = await iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        // Request was not even submitted to the store; no stream event
        // will arrive for it, so clear the busy marker immediately.
        controller.endBuy(productId);
      }
    } catch (e) {
      // Any thrown error from the platform (e.g. a PlatformException from
      // buyNonConsumable) must still release the busy marker, otherwise this
      // plan's buy button would be stuck spinning for the rest of the
      // app session.
      controller.endBuy(productId);
      _snack(l10n.purchaseStartFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Where Pro cannot be bought (central switch off) this page is only a
    // status view for members who are already Pro: no plans are fetched, no
    // price, no buy or restore button.
    final canBuy = ref.watch(proPurchaseAvailableProvider);
    final ios = ref.watch(purchaseIsIosProvider);
    final pendingProductIds = ref.watch(
      creditPurchaseControllerProvider.select((s) => s.pending),
    );
    ref.listen(creditPurchaseControllerProvider.select((s) => s.notice), (
      prev,
      next,
    ) {
      if (next != null && next.id != prev?.id) _onNotice(next);
    });
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
          // The store product id of a plan on the platform this runs on.
          String? productIdOf(SubscriptionPlan plan) => plan.productIdFor(
            ios ? TargetPlatform.iOS : TargetPlatform.android,
          );
          final productIds = plans
              .map(productIdOf)
              .whereType<String>()
              .join(',');
          final storePrices =
              ref.watch(storePricesProvider(productIds)).value ??
              const <String, String>{};
          // iOS shows the App Store's own title / price / billing period.
          final storeProducts = ios
              ? ref.watch(storeProductsProvider(productIds)).value ??
                    const <String, ProductDetails>{}
              : const <String, ProductDetails>{};
          // iOS: the store answered with products but not this plan's (not
          // configured / not approved yet): the server's USD price would
          // only lead to a failing purchase, so the button is disabled.
          // (An empty answer means the store itself is unreachable; the buy
          // attempt then reports that.)
          bool storeLacks(SubscriptionPlan plan) =>
              ios &&
              storeProducts.isNotEmpty &&
              !storeProducts.containsKey(productIdOf(plan));

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
                  body: ios
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
                    title: ios
                        ? _nonEmpty(storeProducts[productIdOf(plan)]?.title) ??
                              plan.name
                        : plan.name,
                    priceText:
                        storePrices[productIdOf(plan)] ??
                        ((double.tryParse(plan.price) ?? 0) > 0
                            ? '\$${plan.price}'
                            : l10n.buy),
                    periodText: ios
                        ? storeKitPeriodText(
                                storeProducts[productIdOf(plan)],
                                l10n,
                              ) ??
                              l10n.durationDays(plan.durationDays)
                        : l10n.durationDays(plan.durationDays),
                    autoRenewNote: ios ? l10n.subAutoRenewsIos : null,
                    isBusy:
                        productIdOf(plan) != null &&
                        pendingProductIds.contains(productIdOf(plan)),
                    unavailable: storeLacks(plan),
                    onBuy: productIdOf(plan) == null || storeLacks(plan)
                        ? null
                        : () => _buy(productIdOf(plan)!),
                  ),
              ],
              const SizedBox(height: 8),
              if (canBuy || isPro)
                Text(
                  ios ? l10n.subCancelNoteIos : l10n.subCancelNote,
                  key: const Key('subscription-terms-note'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (ios && (canBuy || isPro))
                TextButton(
                  key: const Key('manage-subscription'),
                  onPressed: _manageSubscription,
                  child: Text(l10n.subManageIos),
                ),
              if (ios && canBuy)
                OutlinedButton(
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
  final String title;
  final String priceText;
  final String periodText;

  /// iOS: "renews automatically until canceled", shown under the button.
  final String? autoRenewNote;
  final bool isBusy;
  final VoidCallback? onBuy;

  /// iOS: the App Store does not offer this plan right now.
  final bool unavailable;

  const _PlanCard({
    required this.plan,
    required this.title,
    required this.priceText,
    required this.periodText,
    required this.autoRenewNote,
    required this.isBusy,
    required this.onBuy,
    this.unavailable = false,
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
            title,
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
            periodText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: isBusy || unavailable ? null : onBuy,
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
          if (unavailable) ...[
            const SizedBox(height: 8),
            Text(
              l10n.subProductUnavailable,
              key: const Key('plan-unavailable'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ] else if (autoRenewNote != null) ...[
            const SizedBox(height: 8),
            Text(
              autoRenewNote!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _nonEmpty(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
