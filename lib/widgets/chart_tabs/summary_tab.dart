import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/coin.dart';
import '../../models/coin_overview.dart';
import '../../theme/app_theme.dart';
import '../../utils/overview_format.dart';
import '../../utils/price_alert_logic.dart';
import 'overview_body.dart';
import 'tab_widgets.dart';

/// "Ozet": coin summary from the overview endpoint's `summary` section.
class SummaryTab extends StatelessWidget {
  final Coin coin;
  const SummaryTab({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OverviewBody(
      coinId: coin.id,
      builder: (context, overview) {
        final s = overview.summary;
        if (s == null) {
          return TabMessage(icon: Icons.info_outline, title: l10n.ovEmpty);
        }
        return SummaryContent(
          coin: coin,
          summary: s,
          sources: overview.attribution,
        );
      },
    );
  }
}

class SummaryContent extends StatelessWidget {
  final Coin coin;
  final OverviewSummary summary;

  /// Data sources served by the backend; the default line is used if empty.
  final List<String> sources;

  const SummaryContent({
    super.key,
    required this.coin,
    required this.summary,
    this.sources = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final s = summary;

    final tiles = <Widget>[
      if (s.marketCap != null)
        _Tile(
          label: l10n.ovMarketCap,
          value: formatCompactUsd(s.marketCap!, locale),
          termId: 'marketcap',
        ),
      if (s.fdv != null)
        _Tile(
          label: l10n.ovFdv,
          value: formatCompactUsd(s.fdv!, locale),
          termId: 'fdv',
        ),
      if (s.volume24h != null)
        _Tile(
          label: l10n.ovVolume24h,
          value: formatCompactUsd(s.volume24h!, locale),
          termId: 'volume',
        ),
      if (s.volumeToMarketCapPct != null)
        _Tile(
          label: l10n.ovVolMcap,
          value: formatPlainPct(s.volumeToMarketCapPct!, digits: 1),
          termId: 'volmcap',
        ),
    ];

    final changePills = <Widget>[
      for (final (label, v) in [
        (l10n.ovPeriod24h, s.change24h),
        (l10n.ovPeriod7d, s.change7d),
        (l10n.ovPeriod30d, s.change30d),
        (l10n.ovPeriod90d, s.change90d),
      ])
        if (v != null)
          ChangePill(label: label, value: formatSignedPct(v), sign: v),
    ];

    final extremes = <Widget>[
      if (s.ath != null) _ExtremeCard(title: l10n.ovAth, extreme: s.ath!),
      if (s.atl != null) _ExtremeCard(title: l10n.ovAtl, extreme: s.atl!),
    ];

    final infoRows = <Widget>[
      if (s.category != null)
        LabelValueRow(label: l10n.ovCategory, value: s.category!),
      if (s.platform != null)
        LabelValueRow(label: l10n.ovPlatform, value: s.platform!),
      if (s.ageDays != null)
        LabelValueRow(label: l10n.ovCoinAge, value: ageText(l10n, s.ageDays!)),
      if (s.listingAgeDays != null)
        LabelValueRow(
          label: l10n.ovListingAge,
          value: ageText(l10n, s.listingAgeDays!),
        ),
    ];

    return TabPadding(
      children: [
        _Header(coin: coin, summary: s),
        const SizedBox(height: 12),
        if (tiles.isNotEmpty) ...[
          AdaptiveGrid(children: tiles),
          const SizedBox(height: 12),
        ],
        if (_hasSupply(s)) _SupplyCard(summary: s),
        if (changePills.isNotEmpty)
          SectionCard(
            title: l10n.ovPriceChangeTitle,
            child: Wrap(spacing: 8, runSpacing: 8, children: changePills),
          ),
        if (extremes.isNotEmpty) ...[
          AdaptiveGrid(children: extremes),
          const SizedBox(height: 12),
        ],
        if (infoRows.isNotEmpty || s.tags.isNotEmpty || s.newListing)
          SectionCard(
            title: l10n.ovCategory,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...infoRows,
                if (s.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in s.tags) Pill(text: t)],
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          sources.isEmpty
              ? l10n.ovSource
              : l10n.ovSourceFrom(sources.join(', ')),
          key: const Key('overview-attribution'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static bool _hasSupply(OverviewSummary s) =>
      s.circulatingSupply != null ||
      s.totalSupply != null ||
      s.maxSupply != null ||
      s.circulatingPctOfMax != null ||
      s.hasMaxSupply == false;
}

class _Header extends StatelessWidget {
  final Coin coin;
  final OverviewSummary summary;
  const _Header({required this.coin, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = summary.name ?? coin.name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.rank != null)
                Pill(
                  key: const Key('overview-rank'),
                  text: '#${summary.rank}',
                  color: theme.colorScheme.primary,
                ),
              if (summary.newListing)
                Pill(
                  key: const Key('overview-new-listing'),
                  text: l10n.ovNewListing,
                  color: theme.colorScheme.tertiary,
                  icon: Icons.fiber_new_outlined,
                ),
            ],
          ),
        ),
        if (summary.rank != null) const GlossaryHelp(termId: 'rank'),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final String? termId;

  const _Tile({required this.label, required this.value, this.termId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (termId != null) GlossaryHelp(termId: termId!),
        ],
      ),
    );
  }
}

class _SupplyCard extends StatelessWidget {
  final OverviewSummary summary;
  const _SupplyCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final s = summary;
    final pct = s.circulatingPctOfMax;
    return SectionCard(
      title: l10n.ovSupplyTitle,
      termId: 'supply',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.circulatingSupply != null)
            LabelValueRow(
              label: l10n.ovCirculating,
              value: formatCompactNumber(s.circulatingSupply!, locale),
            ),
          if (s.totalSupply != null)
            LabelValueRow(
              label: l10n.ovTotalSupply,
              value: formatCompactNumber(s.totalSupply!, locale),
            ),
          if (s.maxSupply != null)
            LabelValueRow(
              label: l10n.ovMaxSupply,
              value: formatCompactNumber(s.maxSupply!, locale),
            )
          else if (s.hasMaxSupply == false)
            LabelValueRow(label: l10n.ovMaxSupply, value: l10n.ovNoMaxSupply),
          if (s.showsSupplyProgress && pct != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('overview-supply-progress'),
                value: pct / 100,
                minHeight: 8,
              ),
            ),
            HintText(l10n.ovCirculatingOfMax(pct.toStringAsFixed(0))),
          ],
        ],
      ),
    );
  }
}

class _ExtremeCard extends StatelessWidget {
  final String title;
  final PriceExtreme extreme;
  const _ExtremeCard({required this.title, required this.extreme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final e = extreme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (e.price != null)
              Text(
                formatAlertPrice(e.price!),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (e.date != null)
              Text(
                DateFormat.yMMMd(locale).format(e.date!),
                style: theme.textTheme.bodySmall,
              ),
            if (e.distancePct != null)
              Text(
                l10n.ovFromCurrent(formatSignedPct(e.distancePct!, digits: 1)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trendColor(context, e.distancePct),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
