import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/purchase_api.dart' show PurchaseException;
import '../data/purchase_payload.dart';
import '../l10n/app_localizations.dart';
import '../models/credit_breakdown.dart';
import '../models/credit_package.dart';
import '../models/member.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_package_provider.dart';
import '../providers/home_provider.dart';
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
      if (package.storeProductId == productId) {
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
                proof: purchaseProofOf(purchase),
              );
          await ref.read(authProvider.notifier).refreshMember();
          // Home shows the balance from its own cached payload; refresh it too.
          ref.read(homeProvider.notifier).refresh(force: true);

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
        } on PurchaseException catch (e) {
          if (!e.alreadyProcessed) {
            _showRetry(e);
            continue;
          }
          // Already credited on the server earlier: finish the store
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

  void _showRetry(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.purchaseWillRetry('$e')),
      ),
    );
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
    final member = ref.watch(authProvider.select((a) => a.member));

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
                      _pendingProductIds.contains(offer.package.storeProductId),
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
