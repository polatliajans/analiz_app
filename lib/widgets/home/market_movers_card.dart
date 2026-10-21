import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_data.dart';
import '../../utils/home_logic.dart';
import 'home_sections.dart';

enum MarketMoversTab { gainers, losers, volume }

/// Rows shown before "show more" is tapped.
const marketMoversCollapsedRows = 5;

/// "Piyasa": exchange-wide gainers / losers / volume leaders with a segmented
/// control and a compact list, in the spirit of an exchange home screen.
class MarketMoversCard extends StatefulWidget {
  final MarketMovers movers;
  final void Function(MarketMover) onTap;

  const MarketMoversCard({
    super.key,
    required this.movers,
    required this.onTap,
  });

  @override
  State<MarketMoversCard> createState() => _MarketMoversCardState();
}

class _MarketMoversCardState extends State<MarketMoversCard> {
  MarketMoversTab _tab = MarketMoversTab.gainers;
  bool _expanded = false;

  List<MarketMover> _rows(MarketMoversTab tab) {
    switch (tab) {
      case MarketMoversTab.gainers:
        return widget.movers.gainers;
      case MarketMoversTab.losers:
        return widget.movers.losers;
      case MarketMoversTab.volume:
        return widget.movers.volume;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final all = _rows(_tab);
    final shown = _expanded ? all : all.take(marketMoversCollapsedRows);
    final canExpand = all.length > marketMoversCollapsedRows;

    return HomeCard(
      title: l10n.homeMktTitle,
      icon: Icons.bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Segments(
            labels: [
              l10n.homeMktGainers,
              l10n.homeMktLosers,
              l10n.homeMktVolume,
            ],
            selected: _tab.index,
            onSelected: (i) => setState(() {
              _tab = MarketMoversTab.values[i];
              _expanded = false;
            }),
          ),
          const SizedBox(height: 4),
          for (final m in shown)
            _MoverRow(
              key: ValueKey('mover-${_tab.name}-${m.marketType}-${m.symbol}'),
              mover: m,
              locale: locale,
              showVolume: _tab == MarketMoversTab.volume,
              onTap: () => widget.onTap(m),
            ),
          if (canExpand)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? l10n.homeMktLess : l10n.homeMktMore),
              ),
            ),
        ],
      ),
    );
  }
}

/// Overflow-proof segmented control (labels scale down instead of wrapping).
class _Segments extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const _Segments({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: labels[i],
                excludeSemantics: true,
                onTap: () => onSelected(i),
                child: Material(
                  color: i == selected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelected(i),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: i == selected
                                        ? scheme.onPrimary
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoverRow extends StatelessWidget {
  final MarketMover mover;
  final String locale;
  final bool showVolume;
  final VoidCallback onTap;

  const _MoverRow({
    super.key,
    required this.mover,
    required this.locale,
    required this.showVolume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (base, quote) = splitSymbol(mover.symbol);
    final futures = mover.marketType == 'futures';
    final price = mover.price == null
        ? '—'
        : formatUsdPrice(mover.price!, locale);
    final pct = mover.change24hPct;
    final color = changeColor(context, pct);
    final vol = mover.quoteVolumeUsd == null
        ? null
        : formatVolumeShort(mover.quoteVolumeUsd!, locale);
    final volText = vol == null ? null : l10n.homeMktVolumeShort(vol);

    return HomeTapRow(
      onTap: onTap,
      semanticsLabel: [
        mover.symbol,
        price,
        if (pct != null) formatSignedPct(pct, locale),
        if (showVolume && volText != null) volText,
      ].join(', '),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: base,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (quote.isNotEmpty)
                        TextSpan(
                          text: '/$quote',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize:
                                (theme.textTheme.bodyMedium?.fontSize ?? 14) -
                                1,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (futures)
                        TextSpan(
                          text: ' · Futures',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize:
                                (theme.textTheme.bodyMedium?.fontSize ?? 14) -
                                2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                if (showVolume && volText != null)
                  Text(
                    volText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            maxLines: 1,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 74,
            padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }
}

/// A short horizontal row of shortcuts into the rest of the app.
class HomeQuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key? key;

  const HomeQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.key,
  });
}

class HomeQuickActions extends StatelessWidget {
  final List<HomeQuickAction> actions;

  const HomeQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final fit =
            (constraints.maxWidth - gap * (actions.length - 1)) /
            actions.length;
        final itemWidth = fit < 76 * scale ? 76.0 * scale : fit;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: itemWidth,
                  child: Semantics(
                    button: true,
                    label: actions[i].label,
                    excludeSemantics: true,
                    onTap: actions[i].onTap,
                    child: InkWell(
                      key: actions[i].key,
                      borderRadius: BorderRadius.circular(12),
                      onTap: actions[i].onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                actions[i].icon,
                                size: 22,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actions[i].label,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
