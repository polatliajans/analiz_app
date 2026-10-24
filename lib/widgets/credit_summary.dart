import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/credit_breakdown.dart';
import '../models/member.dart';

/// Localized, locale-aware short date for a renewal timestamp.
String formatRenewalDate(BuildContext context, DateTime renewAt) =>
    DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(renewAt.toLocal());

/// Friendly label for a credit-transaction type; null for unknown types so
/// callers keep showing the server description / raw type.
String? creditTransactionLabel(AppLocalizations l10n, String? type) =>
    isMonthlyResetType(type) ? l10n.creditTxMonthlyReset : null;

/// Total / monthly / purchased summary plus the no-carry-over policy.
///
/// With an old server (no breakdown) only the total and the generic policy
/// text are shown. [compact] swaps the long policy for a one-line version and
/// drops the title / total (the account card already shows its own total).
class CreditSummary extends StatelessWidget {
  final Member member;
  final bool compact;
  final Color? textColor;
  final DateTime? now;

  const CreditSummary({
    super.key,
    required this.member,
    this.compact = false,
    this.textColor,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final b = member.credits;
    final base = theme.textTheme.bodyMedium?.copyWith(color: textColor);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: textColor ?? scheme.onSurfaceVariant,
    );

    final days = b.daysUntilRenewal(now ?? DateTime.now());
    final fraction = b.planFraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            l10n.creditSummaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.creditSummaryTotal(member.creditBalance),
            key: const Key('creditSummaryTotal'),
            style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
          ),
        ],
        if (b.hasPlan) ...[
          const SizedBox(height: 12),
          Text(
            b.planCreditTotal != null
                ? l10n.creditSummaryMonthly(b.planCredits!, b.planCreditTotal!)
                : l10n.creditSummaryMonthlyLeft(b.planCredits!),
            key: const Key('creditSummaryMonthly'),
            style: base,
          ),
          if (fraction != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('creditSummaryProgress'),
                value: fraction,
                minHeight: 8,
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
            style: base,
          ),
        ],
        if (b.purchasedCredits != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.creditSummaryPurchased(b.purchasedCredits!),
            key: const Key('creditSummaryPurchased'),
            style: base,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          compact
              ? l10n.creditPolicyShort
              : (b.planCreditTotal != null && b.planCreditTotal! > 0
                    ? l10n.creditPolicyWithTotal(b.planCreditTotal!)
                    : l10n.creditPolicyGeneric),
          key: const Key('creditSummaryPolicy'),
          style: small,
        ),
      ],
    );
  }
}
