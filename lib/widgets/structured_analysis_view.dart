import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/structured_analysis.dart';
import '../screens/glossary_screen.dart';
import '../utils/structured_analysis_logic.dart';

const _bullColor = Color(0xFF2E9E5B);
const _bearColor = Color(0xFFD64545);

Color biasColor(AnalysisBias? bias, ColorScheme scheme) {
  switch (bias) {
    case AnalysisBias.bullish:
      return _bullColor;
    case AnalysisBias.bearish:
      return _bearColor;
    case AnalysisBias.neutral:
    case null:
      return scheme.outline;
  }
}

IconData biasIcon(AnalysisBias? bias) {
  switch (bias) {
    case AnalysisBias.bullish:
      return Icons.trending_up;
    case AnalysisBias.bearish:
      return Icons.trending_down;
    case AnalysisBias.neutral:
    case null:
      return Icons.trending_flat;
  }
}

String biasLabel(AppLocalizations l10n, AnalysisBias bias) {
  switch (bias) {
    case AnalysisBias.bullish:
      return l10n.structuredBiasBullish;
    case AnalysisBias.bearish:
      return l10n.structuredBiasBearish;
    case AnalysisBias.neutral:
      return l10n.structuredBiasNeutral;
  }
}

/// Small direction badge (icon + label), used in the result sheet and in the
/// history cards.
class BiasBadge extends StatelessWidget {
  final AnalysisBias bias;
  final int? confidence;
  final bool compact;

  const BiasBadge({
    super.key,
    required this.bias,
    this.confidence,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = biasColor(bias, Theme.of(context).colorScheme);
    final conf = clampConfidence(confidence);
    final label = compact && conf != null
        ? '${biasLabel(l10n, bias)} $conf%'
        : biasLabel(l10n, bias);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 6 : 20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(biasIcon(bias), size: compact ? 14 : 20, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style:
                  (compact
                          ? Theme.of(context).textTheme.labelSmall
                          : Theme.of(context).textTheme.titleSmall)
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich rendering of a [StructuredAnalysis]. Lays out as a plain Column so it
/// can live inside any scroll view.
class StructuredAnalysisView extends StatelessWidget {
  final StructuredAnalysis data;
  final int creditCost;

  const StructuredAnalysisView({
    super.key,
    required this.data,
    required this.creditCost,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(data: data),
        if (data.summary != null) ...[
          _SectionTitle(l10n.structuredSectionSummary),
          Text(data.summary!, style: textTheme.bodyMedium),
        ],
        if (data.drivers.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionDrivers),
          for (final d in data.drivers) _DriverCard(driver: d),
        ],
        if (data.hasScenarios) ...[
          _SectionTitle(l10n.structuredSectionScenarios),
          if (data.bull != null)
            _ScenarioCard(
              label: l10n.structuredScenarioBull,
              scenario: data.bull!,
              color: _bullColor,
            ),
          if (data.base != null)
            _ScenarioCard(
              label: l10n.structuredScenarioBase,
              scenario: data.base!,
              color: scheme.outline,
            ),
          if (data.bear != null)
            _ScenarioCard(
              label: l10n.structuredScenarioBear,
              scenario: data.bear!,
              color: _bearColor,
            ),
        ],
        if (!data.levels.isEmpty) ...[
          _SectionTitle(l10n.structuredSectionLevels),
          _LevelsList(levels: data.levels),
        ],
        if (data.risks.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionRisks),
          _Bullets(items: data.risks),
        ],
        if (data.watch.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionWatch),
          _Bullets(items: data.watch),
        ],
        if (data.missingSources.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.structuredDataMissing(data.missingSources.join(', ')),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (data.sources.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionSources),
          for (final s in data.sources) _SourceTile(source: s),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openGlossary(context),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text(l10n.glossaryLearnTerms),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.disclaimer ?? l10n.structuredDisclaimer,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (data.disclaimer != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.structuredDisclaimer,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(l10n.creditsSpent(creditCost), style: textTheme.bodySmall),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _Header extends StatelessWidget {
  final StructuredAnalysis data;
  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final conf = clampConfidence(data.confidence);
    final color = biasColor(data.bias, scheme);
    final horizon =
        data.horizonLabel ??
        (data.horizonCandles != null
            ? l10n.structuredHorizonCandles(data.horizonCandles!)
            : null);

    return Row(
      children: [
        if (conf != null) ...[
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: conf / 100,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                Text(
                  '$conf',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.bias != null) BiasBadge(bias: data.bias!),
              if (conf != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.structuredConfidence(conf),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (horizon != null)
                Text(
                  l10n.structuredHorizon(horizon),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  final AnalysisDriver driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = biasColor(driver.direction, scheme);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(biasIcon(driver.direction), size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driver.title ?? driver.detail ?? '',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (driver.title != null && driver.detail != null) ...[
              const SizedBox(height: 4),
              Text(driver.detail!, style: textTheme.bodyMedium),
            ],
            if (driver.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final e in driver.evidence)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        e,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String label;
  final AnalysisScenario scenario;
  final Color color;

  const _ScenarioCard({
    required this.label,
    required this.scenario,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fraction = probabilityFraction(scenario.probability);
    final percent = probabilityPercent(scenario.probability);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (percent != null)
                  Text('$percent%', style: textTheme.titleSmall),
              ],
            ),
            if (fraction != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ],
            if (scenario.description != null) ...[
              const SizedBox(height: 8),
              Text(scenario.description!, style: textTheme.bodyMedium),
            ],
            if (scenario.triggerLevel != null || scenario.target != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 2,
                children: [
                  if (scenario.triggerLevel != null)
                    Text(
                      l10n.structuredScenarioTrigger(
                        formatLevel(scenario.triggerLevel),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (scenario.target != null)
                    Text(
                      l10n.structuredScenarioTarget(
                        formatLevel(scenario.target),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelsList extends StatelessWidget {
  final AnalysisLevels levels;
  const _LevelsList({required this.levels});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entries = sortedLevels(levels);
    final current = levels.priceAtAnalysis;
    var currentInserted = current == null;

    Widget row(String label, double price, Color color, {bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Text(
                formatLevel(price),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );

    final rows = <Widget>[];
    for (final e in entries) {
      if (!currentInserted && current! >= e.price) {
        rows.add(
          row(l10n.structuredLevelPrice, current, scheme.primary, bold: true),
        );
        currentInserted = true;
      }
      switch (e.kind) {
        case LevelKind.resistance:
          rows.add(row(l10n.structuredLevelResistance, e.price, _bearColor));
        case LevelKind.support:
          rows.add(row(l10n.structuredLevelSupport, e.price, _bullColor));
        case LevelKind.invalidation:
          rows.add(
            row(l10n.structuredLevelInvalidation, e.price, scheme.error),
          );
      }
    }
    if (!currentInserted) {
      rows.add(
        row(l10n.structuredLevelPrice, current!, scheme.primary, bold: true),
      );
    }
    return Column(children: rows);
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets({required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: textTheme.bodyMedium),
                Expanded(child: Text(item, style: textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final AnalysisSource source;
  const _SourceTile({required this.source});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(source.url ?? '');
    var ok = false;
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.structuredSourceOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasUrl = source.url != null;
    final title = source.name ?? source.url ?? '';
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              hasUrl ? Icons.open_in_new : Icons.info_outline,
              size: 16,
              color: hasUrl ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: hasUrl ? scheme.primary : null,
                    decoration: hasUrl ? TextDecoration.underline : null,
                  ),
                ),
                if (source.note != null)
                  Text(
                    source.note!,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!hasUrl) return content;
    return InkWell(onTap: () => _open(context), child: content);
  }
}
