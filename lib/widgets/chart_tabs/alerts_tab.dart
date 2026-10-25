import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/coin.dart';
import '../../models/price_alert.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chart_data_provider.dart';
import '../../providers/price_alert_provider.dart';
import '../../screens/price_alert_sheet.dart';
import 'tab_widgets.dart';

/// Past alerts shown under the active ones.
const maxPastAlertRows = 5;

/// "Alarmlar": the member's price alerts for [coin] and a shortcut to add one.
class AlertsTab extends ConsumerWidget {
  final Coin coin;
  final ChartDataParams params;

  const AlertsTab({super.key, required this.coin, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return GuestLockedTab(
        icon: Icons.notifications_none,
        title: l10n.alTabLoginHint,
      );
    }
    if (!ref.watch(isProProvider)) {
      return TabMessage(
        key: const Key('alerts-pro-upsell'),
        icon: Icons.notifications_active_outlined,
        title: l10n.alertProTitle,
        body: l10n.alertProBody,
        action: FilledButton(
          onPressed: () => showProAlertPromo(context),
          child: Text(l10n.upgradeToPro),
        ),
      );
    }
    final async = ref.watch(priceAlertsProvider);
    final list = async.value;
    if (list == null) {
      if (async.hasError) {
        return TabError(onRetry: () => ref.invalidate(priceAlertsProvider));
      }
      return const TabSkeleton(blocks: 2);
    }
    final mine = [
      for (final a in list.alerts)
        if (a.coinId == coin.id) a,
    ];
    final active = [
      for (final a in mine)
        if (a.isActive) a,
    ];
    final past = [
      for (final a in mine)
        if (!a.isActive) a,
    ].take(maxPastAlertRows).toList();

    final addButton = FilledButton.icon(
      key: const Key('alerts-add'),
      onPressed: () =>
          openPriceAlertFlow(context, ref, coin: coin, params: params),
      icon: const Icon(Icons.add_alert_outlined),
      label: Text(l10n.alTabAdd),
    );

    if (mine.isEmpty) {
      return TabMessage(
        icon: Icons.notifications_none,
        title: l10n.alTabEmpty,
        action: addButton,
      );
    }
    return TabPadding(
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: addButton),
        const SizedBox(height: 8),
        if (active.isNotEmpty) ...[
          Text(
            l10n.alertActiveForCoin,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final a in active) _AlertTile(alert: a),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.alTabHistory,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final a in past) _AlertTile(alert: a),
        ],
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final PriceAlert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final status = switch (alert.status) {
      PriceAlertStatus.active => null,
      PriceAlertStatus.triggered => l10n.alertStatusTriggered,
      PriceAlertStatus.canceled => l10n.alertStatusCanceled,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              alert.isActive
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(alertDirectionText(l10n, alert))),
            if (status != null) ...[
              const SizedBox(width: 8),
              Pill(text: status),
            ],
          ],
        ),
      ),
    );
  }
}
