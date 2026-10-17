import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/price_alert_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../models/price_alert.dart';
import '../providers/auth_provider.dart';
import '../providers/coin_list_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../utils/price_alert_logic.dart';
import 'price_alert_sheet.dart';

/// Profile -> "My alerts": active and past price alerts of the member.
class AlarmsScreen extends ConsumerStatefulWidget {
  const AlarmsScreen({super.key});

  @override
  ConsumerState<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends ConsumerState<AlarmsScreen> {
  /// Ids removed by swiping; hidden immediately until the list reloads.
  final Set<int> _hidden = {};
  int? _busyId;

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Cancels [alert]; returns whether it worked.
  Future<bool> _cancel(PriceAlert alert) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyId = alert.id);
    try {
      await ref.read(priceAlertApiProvider).cancel(token, alert.id);
      ref.invalidate(priceAlertsProvider);
      if (mounted) _snack(l10n.alertCanceled);
      return true;
    } catch (e) {
      if (mounted) _snack(priceAlertErrorText(l10n, e));
      return false;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _rearm(PriceAlert alert) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyId = alert.id);
    try {
      await ref
          .read(priceAlertApiProvider)
          .create(
            token,
            coinId: alert.coinId,
            targetPrice: alert.targetPrice,
            direction: alert.direction,
          );
      ref.invalidate(priceAlertsProvider);
      if (mounted) _snack(l10n.alertRearmed);
    } catch (e) {
      if (e is PriceAlertException &&
          e.kind == PriceAlertErrorKind.proRequired) {
        ref.read(authProvider.notifier).refreshMember();
      }
      if (mounted) _snack(priceAlertErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openCoin(PriceAlert alert) async {
    final navigator = Navigator.of(context);
    final selected = ref.read(selectedCoinProvider.notifier);
    final tab = ref.read(homeTabProvider.notifier);
    Coin? coin;
    try {
      final coins = await ref.read(coinListProvider(alert.marketType).future);
      for (final c in coins) {
        if (c.id == alert.coinId) {
          coin = c;
          break;
        }
      }
    } catch (_) {}
    coin ??= Coin(
      id: alert.coinId,
      symbol: alert.symbol,
      name: alert.symbol,
      marketType: alert.marketType,
      lastPrice: null,
      priceChangePercent24h: null,
      volume24h: null,
    );
    selected.select(coin);
    tab.select(chartTabIndex);
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(isProProvider);
    final async = ref.watch(priceAlertsProvider);
    final data = async.value;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myAlerts),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.alertsTabActive),
              Tab(text: l10n.alertsTabHistory),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!isPro) _ProBanner(onUpgrade: () => showProAlertPromo(context)),
            Expanded(
              child: data == null
                  ? (async.hasError
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    priceAlertErrorText(l10n, async.error!),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () =>
                                      ref.invalidate(priceAlertsProvider),
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()))
                  : TabBarView(
                      children: [
                        _buildList(
                          l10n,
                          [
                            for (final a in data.active)
                              if (!_hidden.contains(a.id)) a,
                          ],
                          l10n.alertsEmptyActive,
                          active: true,
                          isPro: isPro,
                          footer: l10n.alertLimitInfo(
                            data.active.length,
                            data.maxActive,
                          ),
                        ),
                        _buildList(
                          l10n,
                          data.history,
                          l10n.alertsEmptyHistory,
                          active: false,
                          isPro: isPro,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    AppLocalizations l10n,
    List<PriceAlert> alerts,
    String emptyText, {
    required bool active,
    required bool isPro,
    String? footer,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        _hidden.clear();
        ref.invalidate(priceAlertsProvider);
        await ref
            .read(priceAlertsProvider.future)
            .catchError((_) => const PriceAlertList());
      },
      child: alerts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 48),
                Text(emptyText, textAlign: TextAlign.center),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: alerts.length + (footer == null ? 0 : 1),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == alerts.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      footer!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                final alert = alerts[i];
                final tile = _AlertTile(
                  alert: alert,
                  busy: _busyId == alert.id,
                  onTap: () => _openCoin(alert),
                  onCancel: active ? () => _cancel(alert) : null,
                  onRearm: isPro && alert.status == PriceAlertStatus.triggered
                      ? () => _rearm(alert)
                      : null,
                );
                if (!active) return tile;
                return Dismissible(
                  key: ValueKey('alert-${alert.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  confirmDismiss: (_) => _cancel(alert),
                  onDismissed: (_) => setState(() => _hidden.add(alert.id)),
                  child: tile,
                );
              },
            ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProBanner({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.tertiaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.alertProTitle,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
          TextButton(onPressed: onUpgrade, child: Text(l10n.upgradeToPro)),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final PriceAlert alert;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRearm;

  const _AlertTile({
    required this.alert,
    required this.busy,
    required this.onTap,
    this.onCancel,
    this.onRearm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final above = alert.direction == AlertDirection.above;

    String? statusLine;
    if (alert.status == PriceAlertStatus.triggered) {
      final at = alert.triggeredAt;
      final when = at == null
          ? ''
          : DateFormat.yMMMd(
              Localizations.localeOf(context).toString(),
            ).add_Hm().format(at);
      final price = alert.triggeredPrice;
      statusLine =
          '${l10n.alertStatusTriggered}: ${l10n.alertTriggeredAt(when, price == null ? '-' : formatAlertPrice(price))}';
    } else if (alert.status == PriceAlertStatus.canceled) {
      statusLine = l10n.alertStatusCanceled;
    }

    Widget? trailing;
    if (busy) {
      trailing = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (onCancel != null) {
      trailing = IconButton(
        tooltip: l10n.alertCancelTooltip,
        icon: const Icon(Icons.close),
        onPressed: onCancel,
      );
    } else if (onRearm != null) {
      trailing = TextButton(onPressed: onRearm, child: Text(l10n.alertRearm));
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(
        above ? Icons.trending_up : Icons.trending_down,
        color: above ? Colors.green : Colors.red,
      ),
      title: Row(
        children: [
          Flexible(child: Text(alert.symbol, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              alert.marketType == 'futures' ? 'Futures' : 'Spot',
              style: textTheme.labelSmall,
            ),
          ),
        ],
      ),
      subtitle: Text(
        statusLine == null
            ? alertDirectionText(l10n, alert)
            : '${alertDirectionText(l10n, alert)}\n$statusLine',
      ),
      isThreeLine: statusLine != null,
      trailing: trailing,
    );
  }
}
