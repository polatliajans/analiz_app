import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/candle.dart';
import '../../models/chart_signal.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chart_data_provider.dart';
import '../../providers/live_chart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/overview_format.dart';
import '../../utils/price_alert_logic.dart';
import '../../utils/timeframes.dart';
import 'tab_widgets.dart';

/// Most rows shown; older arrows are not worth a long list.
const maxSignalRows = 40;

/// Stable identity of a signal row.
String signalKey(ChartSignal s) =>
    '${s.candleTime.millisecondsSinceEpoch}-${s.signalType}';

/// Newest first, capped at [maxSignalRows].
List<ChartSignal> recentSignals(List<ChartSignal> signals) {
  final sorted = [...signals]
    ..sort((a, b) => b.candleTime.compareTo(a.candleTime));
  return sorted.length > maxSignalRows
      ? sorted.sublist(0, maxSignalRows)
      : sorted;
}

/// "Sinyaller": the engine's recent arrows for the chart's coin/timeframe,
/// taken from the data the chart already loaded.
class SignalsTab extends ConsumerWidget {
  final ChartDataParams params;
  final String? selectedKey;
  final ValueChanged<ChartSignal> onSelect;

  const SignalsTab({
    super.key,
    required this.params,
    required this.onSelect,
    this.selectedKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (!ref.watch(authProvider.select((a) => a.isLoggedIn))) {
      return GuestLockedTab(icon: Icons.show_chart, title: l10n.sgGuestHint);
    }
    if (!supportsSignals(params.timeframe)) {
      return TabMessage(icon: Icons.show_chart, title: l10n.sgUnsupported);
    }
    final live = ref.watch(liveChartProvider(params));
    final gate = ref.watch(featureGateProvider);
    final visible = recentSignals(gate.visibleSignals(live.signals));
    if (visible.isEmpty) {
      if (live.loading && live.candles.isEmpty) return const TabSkeleton();
      return TabMessage(
        icon: Icons.show_chart,
        title: l10n.sgEmptyTitle,
        body: l10n.sgEmptyBody,
      );
    }
    final current =
        live.price ?? (live.candles.isEmpty ? null : live.candles.last.close);
    return TabPadding(
      children: [
        for (final s in visible)
          SignalRow(
            signal: s,
            candles: live.candles,
            timeframeMs: timeframeMs[params.timeframe]!,
            currentPrice: current,
            selected: signalKey(s) == selectedKey,
            onTap: () => onSelect(s),
          ),
        HintText(l10n.sgTapHint),
      ],
    );
  }
}

class SignalRow extends StatelessWidget {
  final ChartSignal signal;
  final List<Candle> candles;
  final int timeframeMs;
  final double? currentPrice;
  final bool selected;
  final VoidCallback onTap;

  const SignalRow({
    super.key,
    required this.signal,
    required this.candles,
    required this.timeframeMs,
    required this.currentPrice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isBuy = signal.signalType == 'buy';
    final color = trendColor(context, isBuy ? 1 : -1);
    final price = priceAtSignal(candles, signal, timeframeMs);
    final move = movePercent(price, currentPrice);
    // A move in the signal's direction is "good" (green), against it red.
    final favourable = move == null ? 0.0 : (isBuy ? move : -move);
    return Card(
      key: Key('signal-${signalKey(signal)}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected ? theme.colorScheme.secondaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Pill(
                    text: isBuy ? l10n.homeSignalBuy : l10n.homeSignalSell,
                    color: color,
                    icon: isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.homeSignalStrength(signal.strength),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat.MMMd(
                  locale,
                ).add_Hm().format(signal.candleTime.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (price != null)
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      l10n.sgPriceAtSignal(formatAlertPrice(price)),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (move != null)
                      Text(
                        l10n.sgSinceSignal(formatSignedPct(move)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: trendColor(context, favourable),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
