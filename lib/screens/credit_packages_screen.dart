import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart' show PurchaseParam;

import '../l10n/app_localizations.dart';
import '../models/credit_breakdown.dart';
import '../models/member.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_package_provider.dart';
import '../providers/credit_purchase_provider.dart';
import '../providers/store_price_provider.dart';
import '../utils/credit_pack_pricing.dart';
import '../widgets/brand_page.dart';
import '../widgets/credit_summary.dart';

class CreditPackagesScreen extends ConsumerStatefulWidget {
  const CreditPackagesScreen({super.key});

  @override
  ConsumerState<CreditPackagesScreen> createState() =>
      _CreditPackagesScreenState();
}

class _CreditPackagesScreenState extends ConsumerState<CreditPackagesScreen> {
  // The purchase stream is listened to app-wide (creditPurchaseController);
  // this screen only starts buys and reflects the shared state.

  @override
  void initState() {
    super.initState();
    // Anything left unverified (offline earlier, packages not loaded) gets
    // another try as soon as the user opens the shop.
    Future.microtask(() {
      if (mounted) {
        ref.read(creditPurchaseControllerProvider.notifier).retryPending();
      }
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _onNotice(PurchaseNotice notice) {
    // Pro subscription notices belong to the Pro page.
    if (notice.subscription) return;
    final l10n = AppLocalizations.of(context)!;
    switch (notice.kind) {
      case PurchaseNoticeKind.credited:
      case PurchaseNoticeKind.subscriptionActivated:
        _snack(l10n.creditsAdded);
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

  Future<void> _buy(int packageId, String productId) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(creditPurchaseControllerProvider.notifier);
    // Guard re-entrancy before any await: a fast double-tap on the same
    // package's button must not fire buyConsumable twice.
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
      final started = await iap.buyConsumable(purchaseParam: param);
      if (!started) {
        // Request was not even submitted to the store; no stream event
        // will arrive for it, so clear the busy marker immediately.
        controller.endBuy(productId);
      }
    } catch (e) {
      // Any thrown error from the platform must still release the busy
      // marker, or this package's buy button would spin for the rest of the
      // app session.
      controller.endBuy(productId);
      if (!mounted) return;
      _snack(l10n.purchaseStartFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final packagesAsync = ref.watch(creditPackageListProvider);
    final member = ref.watch(authProvider.select((a) => a.member));
    final pendingProductIds = ref.watch(
      creditPurchaseControllerProvider.select((s) => s.pending),
    );
    ref.listen(creditPurchaseControllerProvider.select((s) => s.notice), (
      prev,
      next,
    ) {
      if (next != null && next.id != prev?.id) _onNotice(next);
    });

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
                          .map((p) => p.storeProductId)
                          .whereType<String>()
                          .join(','),
                    ),
                  )
                  .value ??
              const <String, String>{};
          // The server's fallback prices are USD; the store's own localized price wins.
          final offers = buildCreditPackOffers(packages, storePrices);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (member != null) ...[
                CreditBalanceHero(member: member),
                const SizedBox(height: 20),
              ],
              BrandSectionHeading(l10n.creditsChoosePack),
              const SizedBox(height: 10),
              if (offers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.creditsNoPackages,
                    key: const Key('creditsNoPackages'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final offer in offers) ...[
                CreditPackCard(
                  key: ValueKey('credit-pack-${offer.package.id}'),
                  offer: offer,
                  busy:
                      offer.package.storeProductId != null &&
                      pendingProductIds.contains(offer.package.storeProductId),
                  onBuy: offer.package.storeProductId == null
                      ? null
                      : () => _buy(
                          offer.package.id,
                          offer.package.storeProductId!,
                        ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              const CreditsHowItWorks(),
            ],
          );
        },
      ),
    );
  }
}

/// Balance hero: total credits, plus the monthly / purchased split when the
/// server sent it.
class CreditBalanceHero extends StatelessWidget {
  final Member member;
  final DateTime? now;
  const CreditBalanceHero({super.key, required this.member, this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final CreditBreakdown b = member.credits;
    final fraction = b.planFraction;
    final days = b.daysUntilRenewal(now ?? DateTime.now());
    final soft = Colors.white.withValues(alpha: 0.9);
    final small = text.bodySmall?.copyWith(color: soft);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0A8F70), Color(0xFF1B4FC9)],
        ),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creditSummaryTitle,
            style: text.titleSmall?.copyWith(color: soft),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.toll_rounded,
                size: 34,
                color: Color(0xFFFFD54F),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${member.creditBalance}',
                    key: const Key('creditSummaryTotal'),
                    style: text.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.creditsUnit,
                style: text.titleMedium?.copyWith(color: soft),
              ),
            ],
          ),
          if (b.hasPlan) ...[
            const SizedBox(height: 14),
            Text(
              b.planCreditTotal != null
                  ? l10n.creditSummaryMonthly(
                      b.planCredits!,
                      b.planCreditTotal!,
                    )
                  : l10n.creditSummaryMonthlyLeft(b.planCredits!),
              key: const Key('creditSummaryMonthly'),
              style: text.bodyMedium?.copyWith(color: Colors.white),
            ),
            if (fraction != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const Key('creditSummaryProgress'),
                  value: fraction,
                  minHeight: 8,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ],
          ],
          if (b.renewAt != null && days != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.creditSummaryRenewal(
                formatRenewalDate(context, b.renewAt!),
                days,
              ),
              key: const Key('creditSummaryRenewal'),
              style: small,
            ),
          ],
          if (b.purchasedCredits != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.creditSummaryPurchased(b.purchasedCredits!),
              key: const Key('creditSummaryPurchased'),
              style: text.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

/// One premium pack card: big credit amount, price per credit, optional
/// badge and a single buy button carrying the store price.
class CreditPackCard extends StatelessWidget {
  final CreditPackOffer offer;
  final bool busy;
  final VoidCallback? onBuy;

  const CreditPackCard({
    super.key,
    required this.offer,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pkg = offer.package;
    final best = offer.bestValue;
    final badge = best
        ? l10n.creditsBadgeBest
        : (offer.popular ? l10n.creditsBadgePopular : null);
    const radius = 20.0;

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: scheme.surfaceContainerHigh,
        // Best value gets the brand gradient as a frame instead.
        border: best ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room for the badge pinned to the top corner.
          if (badge != null) const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [brandTeal, brandBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.toll_rounded, color: Color(0xFFFFD54F)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      children: [
                        Text(
                          '${pkg.creditAmount}',
                          key: Key('credit-pack-amount-${pkg.id}'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.creditsUnit,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      pkg.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (offer.perCredit != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.creditsPerCredit(offer.perCredit!),
              key: Key('credit-pack-per-${pkg.id}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('credit-pack-buy-${pkg.id}'),
              onPressed: busy ? null : onBuy,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.creditsBuyFor(offer.priceLabel),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );

    final framed = best
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius + 2),
              gradient: const LinearGradient(
                colors: [brandTeal, brandBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: card,
          )
        : card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        framed,
        if (badge != null)
          PositionedDirectional(
            top: best ? 14 : 12,
            end: best ? 16 : 14,
            child: Container(
              key: Key(best ? 'credit-badge-best' : 'credit-badge-popular'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: best ? null : scheme.secondaryContainer,
                gradient: best
                    ? const LinearGradient(
                        colors: [Color(0xFF0A8F70), Color(0xFF1B4FC9)],
                      )
                    : null,
              ),
              child: Text(
                badge,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: best ? Colors.white : scheme.onSecondaryContainer,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact "how credits work" explainer; only states rules the app already
/// documents (monthly credits don't carry over, purchased ones never expire,
/// monthly are spent first).
class CreditsHowItWorks extends StatelessWidget {
  const CreditsHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rows = [
      (Icons.psychology_outlined, l10n.creditsHowUse),
      (Icons.autorenew_rounded, l10n.creditsHowMonthly),
      (Icons.all_inclusive_rounded, l10n.creditsHowPurchased),
    ];
    return Container(
      key: const Key('creditsHowItWorks'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.creditsHowTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final r in rows) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r.$1, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.$2,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
