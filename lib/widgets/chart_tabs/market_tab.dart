import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/coin.dart';
import '../../models/coin_overview.dart';
import '../../theme/app_theme.dart';
import '../../utils/overview_format.dart';
import 'overview_body.dart';
import 'tab_widgets.dart';

/// Funding percentile at/above which (or at/below the mirror) a hint shows.
const fundingHighPercentile = 80.0;
const fundingLowPercentile = 20.0;

/// Taker buy/sell ratio band treated as balanced.
const takerBalancedLow = 0.9;
const takerBalancedHigh = 1.1;

/// "Piyasa": derivatives (futures only), liquidity and activity.
class MarketTab extends StatelessWidget {
  final Coin coin;
  const MarketTab({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OverviewBody(
      coinId: coin.id,
      builder: (context, overview) {
        final m = overview.market;
        if (m == null) {
          return TabMessage(icon: Icons.insights_outlined, title: l10n.mkEmpty);
        }
        return MarketContent(
          isFutures: coin.marketType == 'futures',
          market: m,
        );
      },
    );
  }
}

class MarketContent extends StatelessWidget {
  final bool isFutures;
  final OverviewMarket market;

  const MarketContent({
    super.key,
    required this.isFutures,
    required this.market,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = market.futures;
    return TabPadding(
      children: [
        if (isFutures && f != null) FuturesSection(metrics: f),
        if (!isFutures)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              key: const Key('market-spot-note'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: HintText(l10n.mkSpotNote)),
              ],
            ),
          ),
        if (market.liquidity != null)
          LiquiditySection(liquidity: market.liquidity!),
        if (market.activity != null)
          ActivitySection(activity: market.activity!),
      ],
    );
  }
}

// ---------------------------------------------------------------- futures

class FuturesSection extends StatelessWidget {
  final FuturesMetrics metrics;
  const FuturesSection({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = metrics;
    return Column(
      key: const Key('market-futures'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (m.fundingRatePct != null || m.fundingPercentile != null)
          _FundingCard(metrics: m),
        if (_hasOi(m))
          SectionCard(
            title: l10n.mkOpenInterest,
            termId: 'openinterest',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (label, v) in [
                      (l10n.ovPeriod1h, m.oiChange1h),
                      (l10n.ovPeriod4h, m.oiChange4h),
                      (l10n.ovPeriod24h, m.oiChange24h),
                      (l10n.ovPeriod7d, m.oiChange7d),
                    ])
                      if (v != null)
                        ChangePill(
                          label: label,
                          value: formatSignedPct(v),
                          sign: v,
                        ),
                  ],
                ),
                HintText(l10n.mkOiHint),
              ],
            ),
          ),
        if (m.longSharePct != null ||
            m.longShortRatio != null ||
            m.topTraderRatio != null)
          _LongShortCard(metrics: m),
        if (m.takerBuySell1h != null || m.takerBuySell24h != null)
          _TakerCard(metrics: m),
        if (m.basisPct != null) _BasisCard(basisPct: m.basisPct!),
      ],
    );
  }

  static bool _hasOi(FuturesMetrics m) =>
      m.oiChange1h != null ||
      m.oiChange4h != null ||
      m.oiChange24h != null ||
      m.oiChange7d != null;
}

class _FundingCard extends StatelessWidget {
  final FuturesMetrics metrics;
  const _FundingCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rate = metrics.fundingRatePct;
    final pctile = metrics.fundingPercentile;
    final hint = pctile == null
        ? null
        : pctile >= fundingHighPercentile
        ? l10n.mkFundingHintHigh
        : pctile <= fundingLowPercentile
        ? l10n.mkFundingHintLow
        : l10n.mkFundingHintNormal;
    return SectionCard(
      title: l10n.mkFunding,
      termId: 'funding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rate != null)
            Text(
              '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(4)}%',
              key: const Key('market-funding-rate'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: trendColor(context, rate),
              ),
            ),
          if (pctile != null) ...[
            const SizedBox(height: 8),
            _Gauge(fraction: pctile / 100),
            HintText(l10n.mkFundingPercentile(pctile.toStringAsFixed(0))),
          ],
          if (hint != null) HintText(hint),
        ],
      ),
    );
  }
}

/// Track with a marker at [fraction] (0..1).
class _Gauge extends StatelessWidget {
  final double fraction;
  const _Gauge({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = fraction.clamp(0.0, 1.0);
    return SizedBox(
      key: const Key('market-gauge'),
      height: 14,
      child: LayoutBuilder(
        builder: (context, c) {
          const thumb = 14.0;
          final left = (c.maxWidth - thumb) * f;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                left: left,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LongShortCard extends StatelessWidget {
  final FuturesMetrics metrics;
  const _LongShortCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = metrics;
    final share = m.longSharePct;
    return SectionCard(
      title: l10n.mkLongShort,
      termId: 'longshort',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (share != null) ...[
            RatioBar(
              fraction: share / 100,
              leftColor: trendColor(context, 1),
              rightColor: trendColor(context, -1),
            ),
            HintText(l10n.mkLongShare(share.toStringAsFixed(0))),
            const SizedBox(height: 4),
          ],
          if (m.longShortRatio != null)
            LabelValueRow(
              label: l10n.mkLsRatio,
              value: formatRatio(m.longShortRatio!),
            ),
          if (m.topTraderRatio != null)
            LabelValueRow(
              label: l10n.mkTopTrader,
              value: formatRatio(m.topTraderRatio!),
            ),
          HintText(l10n.mkLongShortHint),
        ],
      ),
    );
  }
}

class _TakerCard extends StatelessWidget {
  final FuturesMetrics metrics;
  const _TakerCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = metrics;
    final lead = m.takerBuySell24h ?? m.takerBuySell1h!;
    final hint = lead > takerBalancedHigh
        ? l10n.mkTakerHintBuy
        : lead < takerBalancedLow
        ? l10n.mkTakerHintSell
        : l10n.mkTakerHintBalanced;
    Widget row(String label, double? ratio) {
      if (ratio == null || ratio < 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabelValueRow(label: label, value: formatRatio(ratio)),
            RatioBar(
              fraction: ratio / (1 + ratio),
              leftColor: trendColor(context, 1),
              rightColor: trendColor(context, -1),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: l10n.mkTaker,
      termId: 'takerratio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(l10n.ovPeriod1h, m.takerBuySell1h),
          row(l10n.ovPeriod24h, m.takerBuySell24h),
          HintText(hint),
        ],
      ),
    );
  }
}

class _BasisCard extends StatelessWidget {
  final double basisPct;
  const _BasisCard({required this.basisPct});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = basisPct > 0.005
        ? l10n.mkBasisHintPos
        : basisPct < -0.005
        ? l10n.mkBasisHintNeg
        : null;
    return SectionCard(
      title: l10n.mkBasis,
      termId: 'basis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatSignedPct(basisPct),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: trendColor(context, basisPct),
            ),
          ),
          if (hint != null) HintText(hint),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- liquidity

class LiquiditySection extends StatelessWidget {
  final LiquidityMetrics liquidity;
  const LiquiditySection({super.key, required this.liquidity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final l = liquidity;
    final up = trendColor(context, 1);
    final down = trendColor(context, -1);
    return SectionCard(
      title: l10n.mkLiquidityTitle,
      child: Column(
        key: const Key('market-liquidity'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (l.spreadBps != null)
            LabelValueRow(
              label: l10n.mkSpread,
              value: l10n.mkSpreadValue(l.spreadBps!.toStringAsFixed(1)),
            ),
          if (l.depth.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.mkDepthTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.mkDepthBid,
                    style: theme.textTheme.labelSmall?.copyWith(color: up),
                  ),
                ),
                Text(
                  l10n.mkDepthAsk,
                  style: theme.textTheme.labelSmall?.copyWith(color: down),
                ),
              ],
            ),
            for (final band in l.depth) _DepthRow(band: band, locale: locale),
            HintText(l10n.mkDepthNote),
          ],
        ],
      ),
    );
  }
}

class _DepthRow extends StatelessWidget {
  final DepthBand band;
  final String locale;
  const _DepthRow({required this.band, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bid = band.bidUsd, ask = band.askUsd;
    final imb = band.imbalance;
    final total = (bid ?? 0) + (ask ?? 0);
    final bandText = band.bandPct == band.bandPct.roundToDouble()
        ? band.bandPct.toStringAsFixed(0)
        : band.bandPct.toString();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('±$bandText%', style: theme.textTheme.labelMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bid == null ? '-' : formatCompactUsd(bid, locale)}'
                  ' / ${ask == null ? '-' : formatCompactUsd(ask, locale)}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RatioBar(
            fraction: total > 0 ? (bid ?? 0) / total : 0.5,
            leftColor: trendColor(context, 1),
            rightColor: trendColor(context, -1),
          ),
          if (imb != null)
            HintText(
              l10n.mkDepthImbalance(formatSignedPct(imb * 100, digits: 0)),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- activity

class ActivitySection extends StatelessWidget {
  final ActivityMetrics activity;
  const ActivitySection({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final a = activity;
    final rank = a.volumeRank;
    final total = a.volumeRankTotal;
    return SectionCard(
      title: l10n.mkActivityTitle,
      child: Column(
        key: const Key('market-activity'),
        children: [
          if (a.volume24h != null)
            LabelValueRow(
              label: l10n.mkVolume24h,
              value: formatCompactUsd(a.volume24h!, locale),
              termId: 'volume',
            ),
          if (a.trades24h != null)
            LabelValueRow(
              label: l10n.mkTrades24h,
              value: formatCompactNumber(a.trades24h!.toDouble(), locale),
            ),
          if (rank != null)
            LabelValueRow(
              label: l10n.mkVolumeRank,
              value: total != null ? '$rank/$total' : '#$rank',
            ),
        ],
      ),
    );
  }
}
