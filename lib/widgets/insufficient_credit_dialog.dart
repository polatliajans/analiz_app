import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads_controller.dart';
import '../data/ad_analysis_api.dart';
import '../l10n/app_localizations.dart';
import '../models/credit_breakdown.dart';
import '../providers/ad_analysis_provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/price_alert_provider.dart';
import '../screens/credit_packages_screen.dart';
import '../screens/subscription_screen.dart';
import 'credit_summary.dart';

enum AnalysisKind { quick, deep }

/// What the dialog offers besides buying credits / going Pro.
enum AdOffer { none, available, capReached, emailUnverified }

/// Pure decision: ads only ever pay for a QUICK analysis of a Free member.
AdOffer adOfferFor({
  required AnalysisKind kind,
  required bool isPro,
  required bool isLoggedIn,
  required bool emailVerified,
  required bool configEnabled,
  AdAnalysisStatus? status,
}) {
  if (kind != AnalysisKind.quick || isPro || !isLoggedIn || !configEnabled) {
    return AdOffer.none;
  }
  if (!emailVerified) return AdOffer.emailUnverified;
  if (status == null) return AdOffer.none;
  if (status.eligible) return AdOffer.available;
  return switch (status.reason) {
    'cap_reached' => AdOffer.capReached,
    'email_unverified' => AdOffer.emailUnverified,
    _ => AdOffer.none,
  };
}

/// Shown when an analysis is refused with 402. Resolves to true when the
/// member chose "watch an ad and analyze" (quick analysis only); the caller
/// then runs the ad flow.
Future<bool> showInsufficientCreditDialog(
  BuildContext context, {
  AnalysisKind kind = AnalysisKind.quick,
}) async {
  final watch = await showDialog<bool>(
    context: context,
    builder: (_) => InsufficientCreditDialog(kind: kind),
  );
  return watch ?? false;
}

class InsufficientCreditDialog extends ConsumerStatefulWidget {
  final AnalysisKind kind;
  const InsufficientCreditDialog({super.key, required this.kind});

  @override
  ConsumerState<InsufficientCreditDialog> createState() =>
      _InsufficientCreditDialogState();
}

class _InsufficientCreditDialogState
    extends ConsumerState<InsufficientCreditDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.kind == AnalysisKind.quick) {
      Future.microtask(() {
        if (mounted) ref.read(adsControllerProvider.notifier).preloadRewarded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final auth = ref.watch(authProvider);
    final isPro = ref.watch(isProProvider);
    final configEnabled = ref.watch(
      appConfigProvider.select((c) => c.adAnalysisEnabled),
    );
    final quick = widget.kind == AnalysisKind.quick;
    final wantsStatus =
        quick &&
        !isPro &&
        auth.isLoggedIn &&
        configEnabled &&
        (auth.member?.emailVerified ?? false);
    final status = wantsStatus
        ? ref.watch(adAnalysisStatusProvider).value
        : null;
    final offer = adOfferFor(
      kind: widget.kind,
      isPro: isPro,
      isLoggedIn: auth.isLoggedIn,
      emailVerified: auth.member?.emailVerified ?? false,
      configEnabled: configEnabled,
      status: status,
    );

    final body = !quick
        ? l10n.insufficientCreditDeepBody
        : offer == AdOffer.available
        ? l10n.insufficientCreditBodyWithAd
        : l10n.insufficientCreditBody;

    return AlertDialog(
      icon: const Icon(Icons.toll_outlined),
      title: Text(l10n.insufficientCreditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(body),
          if (creditNote(l10n, context, auth.member?.credits)
              case final note?) ...[
            const SizedBox(height: 8),
            Text(
              note,
              key: const Key('creditRenewalNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (!quick) ...[
            const SizedBox(height: 8),
            Text(
              l10n.adAnalysisDeepAlwaysCredits,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (offer == AdOffer.available) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('watchAdButton'),
              onPressed: () => navigator.pop(true),
              icon: const Icon(Icons.ondemand_video_outlined),
              label: Text(l10n.adAnalysisWatchButton),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.adAnalysisRemainingToday(status?.remainingToday ?? 0),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (offer == AdOffer.capReached) ...[
            const SizedBox(height: 12),
            Text(l10n.adAnalysisCapReached),
          ],
          if (offer == AdOffer.emailUnverified) ...[
            const SizedBox(height: 12),
            Text(l10n.adAnalysisEmailUnverified),
          ],
        ],
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: Text(l10n.cancel),
        ),
        if (!isPro)
          OutlinedButton(
            key: const Key('goProButton'),
            onPressed: () {
              navigator.pop(false);
              navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
            child: Text(l10n.upgradeToPro),
          ),
        FilledButton(
          key: const Key('buyCreditsButton'),
          onPressed: () {
            navigator.pop(false);
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => const CreditPackagesScreen(),
              ),
            );
          },
          child: Text(l10n.buyCredits),
        ),
      ],
    );
  }
}

/// One short line: the renewal date when it is within a week, else a reminder
/// that purchased credits never expire; null when there is nothing to add.
String? creditNote(
  AppLocalizations l10n,
  BuildContext context,
  CreditBreakdown? b, {
  DateTime? now,
}) {
  if (b == null) return null;
  final days = b.daysUntilRenewal(now ?? DateTime.now());
  if (b.renewAt != null && days != null && days <= 7) {
    return l10n.insufficientRenewsOn(formatRenewalDate(context, b.renewAt!));
  }
  final purchased = b.purchasedCredits;
  if (purchased != null && purchased > 0) {
    return l10n.insufficientKeepsPurchased(purchased);
  }
  return null;
}
