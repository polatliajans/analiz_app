import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../utils/home_logic.dart';
import 'home/home_sections.dart' show changeColor;

/// One watchlist entry: BASE/QUOTE with a Spot/Futures badge, formatted price,
/// a colored 24h change chip, abbreviated quote volume and a bell when the
/// member has an active price alert on the coin.
class WatchlistRow extends StatelessWidget {
  final Coin coin;
  final bool hasAlert;
  final VoidCallback onTap;

  const WatchlistRow({
    super.key,
    required this.coin,
    required this.onTap,
    this.hasAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final (base, quote) = splitSymbol(coin.symbol);
    final futures = coin.marketType == 'futures';
    final marketLabel = futures ? l10n.marketTypeFutures : l10n.marketTypeSpot;
    final price = coin.lastPrice == null
        ? '—'
        : formatUsdPrice(coin.lastPrice!, locale);
    final pct = coin.priceChangePercent24h;
    final color = changeColor(context, pct);
    final volume = coin.volume24h == null
        ? null
        : l10n.homeMktVolumeShort(formatVolumeUsd(coin.volume24h!, locale));
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final quoteSize = (theme.textTheme.titleMedium?.fontSize ?? 16) - 3;

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: [
        coin.symbol,
        marketLabel,
        price,
        if (pct != null) formatSignedPct(pct, locale),
        ?volume,
        if (hasAlert) l10n.alertTooltip,
      ].join(', '),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: LayoutBuilder(
            builder: (context, c) => Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: base,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (quote.isNotEmpty)
                                    TextSpan(
                                      text: '/$quote',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: quoteSize,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (hasAlert) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.notifications_active,
                              key: const Key('watchlist-alert-bell'),
                              size: 16,
                              color: scheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MarketBadge(label: marketLabel, futures: futures),
                          if (volume != null)
                            Text(volume, maxLines: 1, style: muted),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: c.maxWidth * 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          price,
                          key: const Key('watchlist-price'),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        key: const Key('watchlist-change-chip'),
                        constraints: const BoxConstraints(minWidth: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            pct == null ? '—' : formatSignedPct(pct, locale),
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketBadge extends StatelessWidget {
  final String label;
  final bool futures;
  const _MarketBadge({required this.label, required this.futures});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = futures ? scheme.tertiaryContainer : scheme.secondaryContainer;
    final fg = futures
        ? scheme.onTertiaryContainer
        : scheme.onSecondaryContainer;
    return Container(
      key: const Key('watchlist-market-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
