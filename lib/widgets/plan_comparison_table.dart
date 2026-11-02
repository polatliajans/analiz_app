import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_config.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

/// Used only while the server has not told the app the real amounts.
/// Mirrors the server defaults (Free: `monthly_free_credit_amount` = 10, Pro:
/// the active plan's `monthly_credit` = 300), which the app's own credit-policy
/// copy also quotes.
const fallbackFreeMonthlyCredits = 10;
const fallbackProMonthlyCredits = 300;

/// What one plan offers for one row.
class PlanCell {
  /// Check mark (true) or cross (false); ignored when [text] is set.
  final bool included;

  /// A value shown instead of a mark (a number, "Unlimited", ...).
  final String? text;

  const PlanCell.check() : included = true, text = null;
  const PlanCell.cross() : included = false, text = null;
  const PlanCell.text(String this.text) : included = false;

  factory PlanCell.flag(bool included) =>
      included ? const PlanCell.check() : const PlanCell.cross();
}

class PlanRow {
  final String label;
  final PlanCell free;
  final PlanCell pro;
  const PlanRow(this.label, this.free, this.pro);
}

/// The rows of the Free vs Pro table, derived only from facts the server
/// enforces (see each line). [freeCredits] / [proCredits] are the monthly
/// plan credits when known.
List<PlanRow> planComparisonRows(
  AppLocalizations l10n,
  PlanConfig plan, {
  required int freeCredits,
  required int proCredits,
}) {
  final freeLevels = plan.freeMaxSignalStrength;
  final watchlistMax = plan.freeWatchlistMax;
  return [
    // CreditWallet::allotmentFor: Free = setting, Pro = subscription plan.
    PlanRow(
      l10n.planCmpRowCredits,
      PlanCell.text('$freeCredits'),
      PlanCell.text('$proCredits'),
    ),
    // ChartSignalController: Free capped at free_max_signal_strength.
    PlanRow(
      l10n.planCmpRowSignalLevels,
      PlanCell.text(freeLevels <= 1 ? '1' : '1–$freeLevels'),
      const PlanCell.text('1–3'),
    ),
    // PlanLimits::isTimeframeLocked (chart + analysis).
    if (plan.proOnlyTimeframes.isNotEmpty)
      PlanRow(
        l10n.planCmpRowTimeframes(plan.proOnlyTimeframes.join(', ')),
        const PlanCell.cross(),
        const PlanCell.check(),
      ),
    // AiAnalysisController: any member, costs credits.
    PlanRow(
      l10n.planCmpRowQuick,
      const PlanCell.check(),
      const PlanCell.check(),
    ),
    // DeepAnalysisController: deep_analysis_requires_pro.
    PlanRow(
      l10n.planCmpRowDeep,
      PlanCell.flag(!plan.deepAnalysisRequiresPro),
      const PlanCell.check(),
    ),
    // WatchlistController: free_watchlist_max, Pro unlimited.
    PlanRow(
      l10n.planCmpRowWatchlist,
      watchlistMax == null
          ? PlanCell.text(l10n.planCmpUnlimited)
          : PlanCell.text('$watchlistMax'),
      PlanCell.text(l10n.planCmpUnlimited),
    ),
    // PriceAlertController: Pro only (alerts_require_pro).
    PlanRow(
      l10n.planCmpRowAlerts,
      PlanCell.flag(!plan.alertsRequirePro),
      const PlanCell.check(),
    ),
    // NotifyWatchlistSignals: Pro watchers only.
    PlanRow(
      l10n.planCmpRowSignalPush,
      const PlanCell.cross(),
      const PlanCell.check(),
    ),
    // RadarAccess: Free limited terms / count, Pro all terms + AI notes.
    PlanRow(
      l10n.planCmpRowRadar,
      PlanCell.text(l10n.planCmpLimited),
      const PlanCell.check(),
    ),
    // AppConfig: Pro gets no ad placements.
    PlanRow(
      l10n.planCmpRowNoAds,
      const PlanCell.cross(),
      const PlanCell.check(),
    ),
  ];
}

/// Free vs Pro table with the amounts taken from the server's plan config
/// (and the Pro subscription plans), so it follows admin changes. No prices.
class PlanComparison extends ConsumerWidget {
  const PlanComparison({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plan = ref.watch(appConfigProvider.select((c) => c.plan));
    final member = ref.watch(authProvider.select((s) => s.member));
    final plans = ref.watch(subscriptionPlanListProvider).value;

    final fromPlans = (plans ?? const []).fold<int>(
      0,
      (m, p) => p.monthlyCredit > m ? p.monthlyCredit : m,
    );
    final own = member?.credits.planCreditTotal;
    final ownCredits = own != null && own > 0 ? own : null;
    final freeCredits =
        plan.freeMonthlyCredits ??
        (member != null && member.role != 'pro' ? ownCredits : null) ??
        fallbackFreeMonthlyCredits;
    final proCredits = fromPlans > 0
        ? fromPlans
        : (member?.role == 'pro' ? ownCredits : null) ??
              fallbackProMonthlyCredits;

    return PlanComparisonTable(
      rows: planComparisonRows(
        l10n,
        plan,
        freeCredits: freeCredits,
        proCredits: proCredits,
      ),
    );
  }
}

/// The table itself: pure presentation of [rows].
class PlanComparisonTable extends StatelessWidget {
  final List<PlanRow> rows;
  const PlanComparisonTable({super.key, required this.rows});

  static const _labelFlex = 5;
  static const _valueFlex = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      key: const Key('plan-comparison'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 22,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.planCmpTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ExcludeSemantics(
            child: _RowFrame(
              header: true,
              label: Text(
                l10n.planCmpFeature,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              free: _fit(
                Text(
                  l10n.roleFree,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              pro: _fit(
                Text(
                  l10n.rolePro,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _buildRow(context, l10n, rows[i], i),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              l10n.planCmpFootnote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fit(Widget child) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);

  String _spoken(AppLocalizations l10n, PlanCell cell) =>
      cell.text ??
      (cell.included ? l10n.planCmpIncluded : l10n.planCmpNotIncluded);

  Widget _buildRow(
    BuildContext context,
    AppLocalizations l10n,
    PlanRow row,
    int index,
  ) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: l10n.planCmpRowSemantics(
        row.label,
        _spoken(l10n, row.free),
        _spoken(l10n, row.pro),
      ),
      child: ExcludeSemantics(
        child: _RowFrame(
          key: ValueKey('plan-row-$index'),
          label: Text(row.label, style: theme.textTheme.bodyMedium),
          free: _cell(context, row.free),
          pro: _cell(context, row.pro, strong: true),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, PlanCell cell, {bool strong = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = cell.text;
    if (text != null) {
      return _fit(
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }
    return cell.included
        ? Icon(Icons.check_circle_rounded, size: 22, color: scheme.primary)
        : Icon(
            Icons.remove_circle_outline_rounded,
            size: 22,
            color: scheme.outline,
          );
  }
}

/// One table line: the label and the two value columns; the Pro column is
/// tinted so the eye can follow it down the table.
class _RowFrame extends StatelessWidget {
  final Widget label;
  final Widget free;
  final Widget pro;
  final bool header;

  const _RowFrame({
    super.key,
    required this.label,
    required this.free,
    required this.pro,
    this.header = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: header ? 0 : 0.6),
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: PlanComparisonTable._labelFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: label,
                ),
              ),
            ),
            Expanded(
              flex: PlanComparisonTable._valueFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Center(child: free),
              ),
            ),
            Expanded(
              flex: PlanComparisonTable._valueFlex,
              child: ColoredBox(
                color: scheme.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Center(child: pro),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
