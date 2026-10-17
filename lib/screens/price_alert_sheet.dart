import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/price_alert_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../models/price_alert.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/live_chart_provider.dart';
import '../providers/price_alert_provider.dart';
import '../utils/price_alert_logic.dart';
import 'auth_screen.dart';
import 'subscription_screen.dart';

/// Explains that price alerts are a Pro feature and offers the upgrade.
Future<void> showProAlertPromo(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.workspace_premium_outlined, size: 36),
      title: Text(l10n.alertProTitle, textAlign: TextAlign.center),
      content: Text(l10n.alertProBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            navigator.push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
          child: Text(l10n.upgradeToPro),
        ),
      ],
    ),
  );
}

/// Entry point of the chart bell: guests get the login prompt, non-Pro
/// members the Pro promo, Pro members the alert sheet.
Future<void> openPriceAlertFlow(
  BuildContext context,
  WidgetRef ref, {
  required Coin coin,
  required ChartDataParams params,
}) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) {
    showLoginRequiredSnackBar(context);
    return;
  }
  if (auth.member?.role != 'pro') {
    await showProAlertPromo(context);
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PriceAlertSheet(coin: coin, params: params),
  );
}

/// "Set price alert" bottom sheet for one coin.
class PriceAlertSheet extends ConsumerStatefulWidget {
  final Coin coin;
  final ChartDataParams params;

  const PriceAlertSheet({super.key, required this.coin, required this.params});

  @override
  ConsumerState<PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends ConsumerState<PriceAlertSheet> {
  final _controller = TextEditingController();
  bool _touched = false;
  bool _busy = false;
  int? _cancelingId;
  Object? _error;

  Coin get _coin => widget.coin;

  double? get _currentPrice =>
      ref.read(liveChartProvider(widget.params)).price ?? _coin.lastPrice;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    final initial = _currentPrice;
    if (initial != null) _controller.text = formatAlertPrice(initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPercent(int percent) {
    final current = _currentPrice;
    if (current == null) return;
    _touched = true;
    _controller.text = formatAlertPrice(applyPercent(current, percent));
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  Future<void> _create(double target, AlertDirection direction) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(priceAlertApiProvider)
          .create(
            token,
            coinId: _coin.id,
            targetPrice: target,
            direction: direction,
          );
      ref.invalidate(priceAlertsProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.alertSetSuccess(_coin.symbol))),
      );
    } catch (e) {
      if (e is PriceAlertException &&
          e.kind == PriceAlertErrorKind.proRequired) {
        ref.read(authProvider.notifier).refreshMember();
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e;
      });
    }
  }

  Future<void> _cancel(PriceAlert alert) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    setState(() {
      _cancelingId = alert.id;
      _error = null;
    });
    try {
      await ref.read(priceAlertApiProvider).cancel(token, alert.id);
      ref.invalidate(priceAlertsProvider);
      if (!mounted) return;
      setState(() => _cancelingId = null);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancelingId = null;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final live = ref.watch(liveChartProvider(widget.params));
    final current = live.price ?? _coin.lastPrice;
    // Fill the field with the first price that arrives if none was known.
    if (!_touched && _controller.text.isEmpty && current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text.isEmpty && !_touched) {
          _controller.text = formatAlertPrice(current);
        }
      });
    }

    final target = parsePriceInput(_controller.text);
    final direction = directionForTarget(target, current);
    final canSubmit = !_busy && target != null && direction != null;

    final alertsAsync = ref.watch(priceAlertsProvider);
    final list = alertsAsync.value;
    final coinAlerts = list?.activeForCoin(_coin.id) ?? const <PriceAlert>[];

    String? hint;
    IconData hintIcon = Icons.info_outline;
    Color hintColor = scheme.onSurfaceVariant;
    if (current == null) {
      hint = l10n.alertWaitingPrice;
    } else if (direction == AlertDirection.above) {
      hint = l10n.alertWillTriggerAbove(formatAlertPrice(target!));
      hintIcon = Icons.trending_up;
      hintColor = Colors.green;
    } else if (direction == AlertDirection.below) {
      hint = l10n.alertWillTriggerBelow(formatAlertPrice(target!));
      hintIcon = Icons.trending_down;
      hintColor = Colors.red;
    } else {
      hint = l10n.alertEnterDifferentPrice;
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.alertSetTitle} - ${_coin.symbol}',
                      style: textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current == null
                    ? l10n.alertWaitingPrice
                    : l10n.alertCurrentPrice(formatAlertPrice(current)),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.alertTargetPriceLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _touched = true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 0,
                children: [
                  for (final p in alertQuickPercents)
                    ActionChip(
                      label: Text('${p > 0 ? '+' : ''}$p%'),
                      visualDensity: VisualDensity.compact,
                      onPressed: current == null
                          ? null
                          : () => _applyPercent(p),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(hintIcon, size: 18, color: hintColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hint, style: textTheme.bodySmall)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  priceAlertErrorText(l10n, _error!),
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
                if (_error is PriceAlertException &&
                    (_error as PriceAlertException).kind ==
                        PriceAlertErrorKind.proRequired)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.upgradeToPro),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canSubmit ? () => _create(target, direction) : null,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_alert_outlined),
                label: Text(l10n.alertSetButton),
              ),
              if (list != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.alertLimitInfo(list.active.length, list.maxActive),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (coinAlerts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.alertActiveForCoin, style: textTheme.titleSmall),
                for (final alert in coinAlerts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      alert.direction == AlertDirection.above
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: alert.direction == AlertDirection.above
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(alertDirectionText(l10n, alert)),
                    trailing: _cancelingId == alert.id
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: l10n.alertCancelTooltip,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _cancelingId != null
                                ? null
                                : () => _cancel(alert),
                          ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Above 100" / "Below 100" label for an alert.
String alertDirectionText(AppLocalizations l10n, PriceAlert alert) {
  final price = formatAlertPrice(alert.targetPrice);
  return alert.direction == AlertDirection.above
      ? l10n.alertDirectionAbove(price)
      : l10n.alertDirectionBelow(price);
}
