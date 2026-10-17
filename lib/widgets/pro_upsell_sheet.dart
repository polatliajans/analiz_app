import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/subscription_screen.dart';

/// The Pro-only feature that triggered the upsell.
enum ProFeature {
  deepAnalysis,
  timeframe,
  strongSignals,
  watchlistLimit,
  priceAlert,
  generic,
}

/// Single Pro promo bottom sheet used by every locked feature. [count] and
/// [limit] only matter for [ProFeature.watchlistLimit].
Future<void> showProUpsell(
  BuildContext context,
  ProFeature feature, {
  int? count,
  int? limit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ProUpsellSheet(feature: feature, count: count, limit: limit),
  );
}

class _ProUpsellSheet extends ConsumerWidget {
  final ProFeature feature;
  final int? count;
  final int? limit;

  const _ProUpsellSheet({required this.feature, this.count, this.limit});

  (String, String) _texts(AppLocalizations l10n) {
    switch (feature) {
      case ProFeature.deepAnalysis:
        return (l10n.proUpsellDeepTitle, l10n.proUpsellDeepBody);
      case ProFeature.timeframe:
        return (l10n.proUpsellTimeframeTitle, l10n.proUpsellTimeframeBody);
      case ProFeature.strongSignals:
        return (
          l10n.proUpsellStrongSignalsTitle,
          l10n.proUpsellStrongSignalsBody,
        );
      case ProFeature.watchlistLimit:
        final l = limit ?? count ?? 0;
        return (
          l10n.proUpsellWatchlistTitle(count ?? l, l),
          l10n.proUpsellWatchlistBody,
        );
      case ProFeature.priceAlert:
        return (l10n.alertProTitle, l10n.alertProBody);
      case ProFeature.generic:
        return (l10n.proUpsellGenericTitle, l10n.proUpsellGenericBody);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (title, body) = _texts(l10n);
    final benefits = [
      l10n.proBenefitNoAds,
      l10n.proBenefitDeepAnalysis,
      l10n.proBenefitCredits,
      l10n.proBenefitAlerts,
      l10n.proBenefitTimeframes,
      l10n.proBenefitWatchlist,
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: scheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(l10n.proUpsellBenefitsHeading, style: textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final b in benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                final loggedIn = ref.read(authProvider).isLoggedIn;
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => loggedIn
                        ? const SubscriptionScreen()
                        : const AuthScreen(showGuest: false),
                  ),
                );
              },
              child: Text(l10n.upgradeToPro),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.proUpsellNotNow),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "Pro" badge shown next to locked items.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.proBadgeTooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          l10n.rolePro,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onTertiaryContainer,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
