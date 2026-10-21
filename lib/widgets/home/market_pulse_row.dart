import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_data.dart';
import '../../utils/home_logic.dart';
import 'fear_greed_gauge.dart';
import 'home_sections.dart';

/// Below this width the two pulse cards stack instead of sitting side by side.
const marketPulseStackBelow = 340.0;

/// Two half-width cards: Fear & Greed on the left, BTC on the right. Both have
/// the same height. Stacks on narrow screens; a card without data is dropped.
class MarketPulseRow extends StatelessWidget {
  final MarketPulse? market;

  const MarketPulseRow({super.key, required this.market});

  @override
  Widget build(BuildContext context) {
    final m = market;
    final l10n = AppLocalizations.of(context)!;
    if (m == null || !m.hasAnyData) {
      return HomeCard(
        title: l10n.homeMarketTitle,
        icon: Icons.show_chart,
        child: Text(
          l10n.homeMarketUnavailable,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final fg = m.fearGreed;
    final hasBtc =
        m.btc?.price != null ||
        m.btc?.dominancePct != null ||
        m.totalMarketCap?.usd != null;
    final cards = <Widget>[
      if (fg != null) _FearGreedCard(fg: fg),
      if (hasBtc) _BtcCard(btc: m.btc, cap: m.totalMarketCap, expand: false),
    ];
    if (cards.length == 1) return cards.first;

    // The threshold is on the screen width (the list adds 16dp each side).
    if (MediaQuery.sizeOf(context).width < marketPulseStackBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [cards[0], const SizedBox(height: 12), cards[1]],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          // Same height as its neighbour, so the BTC lines can sit at the
          // bottom.
          Expanded(
            child: _BtcCard(btc: m.btc, cap: m.totalMarketCap, expand: true),
          ),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final Widget child;
  const _PulseCard({required this.child});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

class _FearGreedCard extends StatelessWidget {
  final FearGreed fg;
  const _FearGreedCard({required this.fg});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final level = fearGreedLevel(fg.label, fg.value);
    final label = fearGreedText(l10n, level);
    final delta = fg.change7d;
    final deltaText = delta == null
        ? null
        : l10n.homeFngChange7d(delta > 0 ? '+$delta' : '$delta');

    return _PulseCard(
      child: Semantics(
        container: true,
        label:
            '${l10n.homeFearGreedTitle}. ${l10n.homeFngSemantics(fg.value, label)}'
            '${deltaText == null ? '' : ', $deltaText'}',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeFearGreedTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            // Fixed size (no LayoutBuilder: the row measures intrinsic height).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: FearGreedGauge(value: fg.value, width: 120),
            ),
            Text(
              '${fg.value}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (deltaText != null)
              Text(
                deltaText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BtcCard extends StatelessWidget {
  final BtcPulse? btc;
  final TotalMarketCap? cap;
  final bool expand;
  const _BtcCard({required this.btc, required this.cap, required this.expand});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final b = btc;
    final regime = b?.regime ?? 'unknown';
    final regimeLabel = regimeText(l10n, regime);

    Widget line(String label, String value, {Color? valueColor}) => Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          maxLines: 1,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );

    final capChange = cap?.change24hPct;
    final semantics = [
      'BTC',
      if (b?.price != null) formatUsdPrice(b!.price!, locale),
      if (b?.change24hPct != null) formatSignedPct(b!.change24hPct!, locale),
      if (regime != 'unknown') l10n.homeRegimeLabel(regimeLabel),
      if (b?.dominancePct != null)
        '${l10n.homeBtcDominance} ${formatPlainPct(b!.dominancePct!, locale)}',
      if (cap?.usd != null)
        '${l10n.homeTotalCap} ${formatCompactUsd(cap!.usd!, locale)}'
            '${capChange == null ? '' : ' ${formatSignedPct(capChange, locale)}'}',
    ].join(', ');

    return _PulseCard(
      child: Semantics(
        container: true,
        label: semantics,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'BTC',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                if (regime != 'unknown')
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _RegimeChip(regime: regime),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (b?.price != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatUsdPrice(b!.price!, locale),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (b?.change24hPct != null)
              Text(
                formatSignedPct(b!.change24hPct!, locale),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: changeColor(context, b.change24hPct),
                ),
              ),
            if (expand) const Spacer(),
            const SizedBox(height: 8),
            if (b?.dominancePct != null)
              line(
                l10n.homeBtcDominance,
                formatPlainPct(b!.dominancePct!, locale),
              ),
            if (cap?.usd != null) ...[
              const SizedBox(height: 2),
              line(
                l10n.homeTotalCap,
                capChange != null
                    ? formatSignedPct(capChange, locale)
                    : formatCompactUsd(cap!.usd!, locale),
                valueColor: capChange != null
                    ? changeColor(context, capChange)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegimeChip extends StatelessWidget {
  final String regime;
  const _RegimeChip({required this.regime});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = regime == 'bull'
        ? changeColor(context, 1)
        : regime == 'bear'
        ? changeColor(context, -1)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            regime == 'bull'
                ? Icons.trending_up
                : regime == 'bear'
                ? Icons.trending_down
                : Icons.trending_flat,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            regimeText(l10n, regime),
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
