import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/glossary_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/home_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/glossary_logic.dart';
import '../../utils/home_logic.dart';

/// FRED requires this exact notice wherever its data is used.
const fredDisclaimer =
    'This product uses the FRED® API but is not endorsed or certified by the '
    'Federal Reserve Bank of St. Louis.';

Color changeColor(BuildContext context, double? pct) =>
    trendColor(context, pct);

String _marketSuffix(String marketType) =>
    marketType == 'futures' ? ' · Futures' : '';

/// Standard card for a home section: a title row and content.
class HomeCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const HomeCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A tappable row with a minimum 48dp touch height.
class HomeTapRow extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget child;

  const HomeTapRow({
    super.key,
    required this.onTap,
    required this.semanticsLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;
  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

// ---------------------------------------------------------------- Header

/// One slim top band: member name on the left, credit balance and plan chips
/// on the right. It sits below the status bar (the screen adds that inset).
class HomeHeader extends StatelessWidget {
  final String? name;
  final int? credits;
  final bool isPro;
  final String? staleNote;
  final VoidCallback onCredits;
  final VoidCallback onPro;

  const HomeHeader({
    super.key,
    required this.name,
    required this.credits,
    required this.isPro,
    required this.staleNote,
    required this.onCredits,
    required this.onPro,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final n = name?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: n.isEmpty
                  ? const SizedBox.shrink()
                  : Semantics(
                      header: true,
                      child: Text(
                        n,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (credits != null) ...[
                      _BandChip(
                        key: const ValueKey('home-credits-chip'),
                        icon: Icons.toll_outlined,
                        label: l10n.creditsCount(credits!),
                        onTap: onCredits,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _BandChip(
                      key: const ValueKey('home-plan-chip'),
                      icon: isPro
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      label: isPro ? l10n.rolePro : l10n.roleFree,
                      highlighted: isPro,
                      onTap: onPro,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (staleNote != null) ...[
          const SizedBox(height: 4),
          Semantics(
            liveRegion: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    staleNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact tappable chip of the top band (36dp tall).
class _BandChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _BandChip({
    super.key,
    required this.icon,
    required this.label,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlighted
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = highlighted ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeGuestCard extends StatelessWidget {
  final VoidCallback onLogin;
  const HomeGuestCard({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HomeCard(
      title: l10n.homeGuestTitle,
      icon: Icons.dashboard_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MutedText(l10n.homeGuestBody),
          const SizedBox(height: 12),
          FilledButton(onPressed: onLogin, child: Text(l10n.logInOrSignUp)),
        ],
      ),
    );
  }
}

class HomeErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const HomeErrorCard({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HomeCard(
      title: l10n.homeErrorTitle,
      icon: Icons.cloud_off_outlined,
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ),
    );
  }
}

// ---------------------------------------------------------------- Resume

class ResumeCard extends StatelessWidget {
  final String symbol;
  final String marketType;
  final String timeframe;
  final VoidCallback onTap;

  const ResumeCard({
    super.key,
    required this.symbol,
    required this.marketType,
    required this.timeframe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final text = '$symbol${_marketSuffix(marketType)} · $timeframe';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '${l10n.homeResumeTitle}: $text. ${l10n.homeResumeOpen}',
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeResumeTitle,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Market

String regimeText(AppLocalizations l10n, String regime) {
  switch (regime) {
    case 'bull':
      return l10n.homeRegimeBull;
    case 'bear':
      return l10n.homeRegimeBear;
    case 'sideways':
      return l10n.homeRegimeSideways;
  }
  return l10n.homeRegimeUnknown;
}

// ---------------------------------------------------------------- Movers

class MoversCard extends StatelessWidget {
  final List<HomeMover> movers;
  final void Function(HomeMover) onTap;
  final VoidCallback onOpenWatchlist;

  const MoversCard({
    super.key,
    required this.movers,
    required this.onTap,
    required this.onOpenWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    return HomeCard(
      title: l10n.homeMoversTitle,
      icon: Icons.star_outline,
      child: movers.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(l10n.homeMoversEmpty),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onOpenWatchlist,
                  child: Text(l10n.homeMoversEmptyAction),
                ),
              ],
            )
          : Column(
              children: [
                for (final m in movers.take(5))
                  HomeTapRow(
                    onTap: () => onTap(m),
                    semanticsLabel: [
                      m.symbol,
                      if (m.price != null) formatUsdPrice(m.price!, locale),
                      if (m.change24hPct != null)
                        formatSignedPct(m.change24hPct!, locale),
                    ].join(', '),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${m.symbol}${_marketSuffix(m.marketType)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (m.price != null)
                              Text(formatUsdPrice(m.price!, locale)),
                            if (m.change24hPct != null)
                              Text(
                                formatSignedPct(m.change24hPct!, locale),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: changeColor(context, m.change24hPct),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ----------------------------------------------------------------- Radar

class RadarCard extends StatelessWidget {
  final List<HomeRadarSignal> signals;
  final DateTime now;
  final void Function(HomeRadarSignal) onTap;

  const RadarCard({
    super.key,
    required this.signals,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return HomeCard(
      title: l10n.homeRadarTitle,
      icon: Icons.radar,
      child: signals.isEmpty
          ? _MutedText(l10n.homeRadarEmpty)
          : Column(
              children: [
                for (final s in signals.take(5))
                  Builder(
                    builder: (context) {
                      final dirText = s.isBuy
                          ? l10n.homeSignalBuy
                          : l10n.homeSignalSell;
                      final ago = s.at == null
                          ? null
                          : relativeAgo(l10n, s.at!, now);
                      final detail = [
                        s.timeframe,
                        l10n.homeSignalStrength(s.strength),
                        ?ago,
                      ].join(' · ');
                      return HomeTapRow(
                        onTap: () => onTap(s),
                        semanticsLabel: '${s.symbol}, $dirText, $detail',
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.symbol}${_marketSuffix(s.marketType)}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    detail,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _DirectionChip(isBuy: s.isBuy, text: dirText),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final bool isBuy;
  final String text;
  const _DirectionChip({required this.isBuy, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = changeColor(context, isBuy ? 1 : -1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBuy ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Analysis

class LastAnalysisCard extends StatelessWidget {
  final HomeLastAnalysis? analysis;
  final DateTime now;
  final VoidCallback onOpen;
  final VoidCallback onNew;

  const LastAnalysisCard({
    super.key,
    required this.analysis,
    required this.now,
    required this.onOpen,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final a = analysis;
    if (a == null) {
      return HomeCard(
        title: l10n.homeAnalysisTitle,
        icon: Icons.psychology_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MutedText(l10n.homeAnalysisEmpty),
            const SizedBox(height: 12),
            FilledButton(onPressed: onNew, child: Text(l10n.homeAnalysisNew)),
          ],
        ),
      );
    }

    final biasText = a.bias == 'bullish'
        ? l10n.structuredBiasBullish
        : a.bias == 'bearish'
        ? l10n.structuredBiasBearish
        : l10n.structuredBiasNeutral;
    final biasColor = a.bias == 'bullish'
        ? changeColor(context, 1)
        : a.bias == 'bearish'
        ? changeColor(context, -1)
        : theme.colorScheme.onSurfaceVariant;
    final biasIcon = a.bias == 'bullish'
        ? Icons.trending_up
        : a.bias == 'bearish'
        ? Icons.trending_down
        : Icons.trending_flat;
    final ago = a.generatedAt == null
        ? null
        : relativeAgo(l10n, a.generatedAt!, now);
    final title =
        '${a.symbol}${_marketSuffix(a.marketType)}'
        '${a.timeframe == null ? '' : ' · ${a.timeframe}'}';
    final confidence = a.confidence == null
        ? null
        : l10n.structuredConfidence(a.confidence!);

    return HomeCard(
      title: l10n.homeAnalysisTitle,
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeTapRow(
            onTap: onOpen,
            semanticsLabel: [
              title,
              biasText,
              ?confidence,
              ?a.kisaca,
              ?ago,
              if (a.cached) l10n.homeAnalysisCachedBadge,
            ].join(', '),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: biasColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: biasColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(biasIcon, size: 14, color: biasColor),
                          const SizedBox(width: 4),
                          Text(
                            biasText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: biasColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (confidence != null)
                      Text(confidence, style: theme.textTheme.bodySmall),
                  ],
                ),
                if (a.kisaca != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    a.kisaca!,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (ago != null)
                      Text(
                        ago,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (a.cached)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.homeAnalysisCachedBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onNew, child: Text(l10n.homeAnalysisNew)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Events

class EventsCard extends StatelessWidget {
  final List<HomeEvent> events;
  final DateTime now;

  const EventsCard({super.key, required this.events, required this.now});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final fmt = DateFormat.MMMd(locale).add_Hm();
    return HomeCard(
      title: l10n.homeEventsTitle,
      icon: Icons.event_outlined,
      child: Column(
        children: [
          for (final e in events.take(5))
            Builder(
              builder: (context) {
                final when = e.dateUtc == null
                    ? null
                    : fmt.format(e.dateUtc!.toLocal());
                final until = relativeUntil(l10n, e.dateUtc, e.hoursUntil, now);
                final importance = e.isHigh
                    ? l10n.homeEventHigh
                    : l10n.homeEventMedium;
                final dotColor = e.isHigh
                    ? changeColor(context, -1)
                    : theme.colorScheme.tertiary;
                final detail = [?when, ?until].join(' · ');
                return Semantics(
                  container: true,
                  label: '${e.name}, $detail, $importance',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (detail.isNotEmpty)
                                Text(
                                  detail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- Learn

class LearnCard extends StatelessWidget {
  final GlossaryTerm term;
  final VoidCallback onTap;

  const LearnCard({super.key, required this.term, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = glossaryLanguage(Localizations.localeOf(context).languageCode);
    final entry = term.entry(lang);
    return HomeCard(
      title: l10n.homeLearnTitle,
      icon: Icons.menu_book_outlined,
      child: HomeTapRow(
        onTap: onTap,
        semanticsLabel:
            '${l10n.homeTermOfDay}: ${entry.name}. ${l10n.homeOpenGlossary}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeTermOfDay,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              entry.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeOpenGlossary,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Promo

class ProPromoCard extends StatelessWidget {
  final VoidCallback onTap;
  const ProPromoCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.homeProPromoTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.homeProPromoBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onTap,
              child: Text(l10n.homeProPromoAction),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Footer

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.homeFooterDisclaimer, style: style),
          const SizedBox(height: 6),
          Text(l10n.homeFooterSources, style: style),
          const SizedBox(height: 6),
          Text(fredDisclaimer, style: style),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Skeleton

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget box(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Semantics(
      label: l10n.homeLoadingSemantics,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 28,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: box(28),
              ),
            ),
            const SizedBox(height: 16),
            box(64),
            const SizedBox(height: 12),
            box(220),
            const SizedBox(height: 12),
            box(150),
            const SizedBox(height: 12),
            box(150),
          ],
        ),
      ),
    );
  }
}
