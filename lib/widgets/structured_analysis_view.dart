import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/structured_analysis.dart';
import '../screens/glossary_screen.dart';
import '../utils/analysis_age.dart';
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

  /// Original generation time; shows a "prepared N min ago" line when older
  /// than a minute.
  final DateTime? generatedAt;

  /// True when the result is a shared-cache hit: under a minute old it then
  /// shows "just prepared" (a fresh analysis shows nothing).
  final bool cached;

  /// Clock override for tests.
  final DateTime Function()? now;

  const StructuredAnalysisView({
    super.key,
    required this.data,
    required this.creditCost,
    this.generatedAt,
    this.cached = false,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasNotes =
        data.missingSources.isNotEmpty || data.dataQualityNotes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(data: data),
        if (preparedAgoText(
              l10n,
              generatedAt,
              (now ?? DateTime.now)(),
              cached: cached,
            )
            case final ago?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              ago,
              key: const Key('prepared_ago'),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (data.keyMetrics.isNotEmpty) ...[
          const SizedBox(height: 14),
          _MetricGrid(metrics: data.keyMetrics),
        ],
        if (data.summary != null) ...[
          _SectionTitle(l10n.structuredSectionSummary),
          Text(data.summary!, style: textTheme.bodyMedium),
        ],
        if (data.drivers.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionDrivers),
          _BalanceBar(drivers: data.drivers),
          const SizedBox(height: 8),
          for (var i = 0; i < data.drivers.length; i++)
            _DriverTile(
              driver: data.drivers[i],
              initiallyExpanded: driverStartsExpanded(
                i,
                data.drivers[i],
                data.bias,
              ),
            ),
        ],
        if (data.hasScenarios) ...[
          _SectionTitle(l10n.structuredSectionScenarios),
          _ProbabilityBar(bull: data.bull, base: data.base, bear: data.bear),
          const SizedBox(height: 8),
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
          _SectionTitle(l10n.structuredSectionLadder),
          _PriceLadder(levels: data.levels),
        ],
        if (data.risks.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionRisks),
          _Bullets(
            items: data.risks,
            icon: Icons.warning_amber_rounded,
            color: _bearColor,
          ),
        ],
        if (data.watch.isNotEmpty) ...[
          _SectionTitle(l10n.structuredSectionWatch),
          _Bullets(
            items: data.watch,
            icon: Icons.visibility_outlined,
            color: scheme.primary,
          ),
        ],
        if (hasNotes) ...[
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const Key('data_notes'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              dense: true,
              leading: Icon(
                Icons.info_outline,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              title: Text(
                l10n.structuredSectionDataNotes,
                style: textTheme.titleSmall,
              ),
              children: [
                if (data.missingSources.isNotEmpty)
                  Text(
                    l10n.structuredDataMissing(data.missingSources.join(', ')),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (data.dataQualityNotes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.dataQualityNotes!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (data.conclusion != null) ...[
          const SizedBox(height: 18),
          _ConclusionCard(text: data.conclusion!, bias: data.bias),
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

/// Semi-circle confidence gauge with the score in the middle.
class _ConfidenceGauge extends StatelessWidget {
  final int value;
  final Color color;
  const _ConfidenceGauge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      key: const Key('confidence_gauge'),
      width: 108,
      height: 62,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GaugePainter(value / 100, color)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '$value',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  _GaugePainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.width - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, math.pi, math.pi * f, false, fill);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.color != color;
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
          _ConfidenceGauge(value: conf, color: color),
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

class _MetricGrid extends StatelessWidget {
  final List<KeyMetric> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final w = c.maxWidth.isFinite ? (c.maxWidth - gap) / 2 : 150.0;
        return Wrap(
          key: const Key('key_metrics'),
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in metrics)
              SizedBox(
                width: w,
                child: _MetricTile(metric: m),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final KeyMetric metric;
  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = biasColor(metric.tone, scheme);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(biasIcon(metric.tone), size: 14, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            metric.value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (metric.hint != null)
            Text(
              metric.hint!,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(Color, String)> items;
  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: [
        for (final (color, text) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(text, style: textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

/// Segmented horizontal bar; zero-weight segments are skipped.
class _SegmentBar extends StatelessWidget {
  final List<(Color, double, String?)> segments;
  const _SegmentBar({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visible = [
      for (final s in segments)
        if (s.$2 > 0) s,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            for (final s in visible)
              Expanded(
                flex: math.max(1, (s.$2 * 1000).round()),
                child: Container(
                  color: s.$1,
                  alignment: Alignment.center,
                  child: s.$3 == null
                      ? null
                      : Text(
                          s.$3!,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  final List<AnalysisDriver> drivers;
  const _BalanceBar({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final b = driverBalance(drivers);
    return Column(
      key: const Key('balance_bar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.structuredSectionBalance,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        _SegmentBar(
          segments: [
            (_bullColor, b.bull.toDouble(), null),
            (scheme.outline, b.neutral.toDouble(), null),
            (_bearColor, b.bear.toDouble(), null),
          ],
        ),
        const SizedBox(height: 4),
        _Legend(
          items: [
            (
              _bullColor,
              l10n.structuredBalanceItem(
                biasLabel(l10n, AnalysisBias.bullish),
                b.bull,
              ),
            ),
            (
              scheme.outline,
              l10n.structuredBalanceItem(
                biasLabel(l10n, AnalysisBias.neutral),
                b.neutral,
              ),
            ),
            (
              _bearColor,
              l10n.structuredBalanceItem(
                biasLabel(l10n, AnalysisBias.bearish),
                b.bear,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  final AnalysisScenario? bull;
  final AnalysisScenario? base;
  final AnalysisScenario? bear;
  const _ProbabilityBar({this.bull, this.base, this.bear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final entries = <(Color, String, int?)>[
      (
        _bullColor,
        l10n.structuredScenarioBull,
        probabilityPercent(bull?.probability),
      ),
      (
        scheme.outline,
        l10n.structuredScenarioBase,
        probabilityPercent(base?.probability),
      ),
      (
        _bearColor,
        l10n.structuredScenarioBear,
        probabilityPercent(bear?.probability),
      ),
    ];
    final known = [
      for (final e in entries)
        if (e.$3 != null) e,
    ];
    if (known.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentBar(
          key: const Key('probability_bar'),
          segments: [
            for (final e in known) (e.$1, e.$3!.toDouble(), '${e.$3}%'),
          ],
        ),
        const SizedBox(height: 4),
        _Legend(items: [for (final e in known) (e.$1, '${e.$2} ${e.$3}%')]),
      ],
    );
  }
}

class _DriverTile extends StatefulWidget {
  final AnalysisDriver driver;
  final bool initiallyExpanded;
  const _DriverTile({required this.driver, required this.initiallyExpanded});

  @override
  State<_DriverTile> createState() => _DriverTileState();
}

class _DriverTileState extends State<_DriverTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.driver;
    final color = biasColor(d.direction, scheme);
    final expandable = d.title != null && d.detail != null;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(biasIcon(d.direction), size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            d.title ?? d.detail ?? '',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (expandable)
          Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
      ],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: expandable ? () => setState(() => _expanded = !_expanded) : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (expandable && _expanded) ...[
                const SizedBox(height: 6),
                Text(d.detail!, style: textTheme.bodyMedium),
              ],
            ],
          ),
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
    final percent = probabilityPercent(scenario.probability);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
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
            if (scenario.description != null) ...[
              const SizedBox(height: 6),
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

/// Vertical level ladder: resistances on top, supports and invalidation below,
/// current price highlighted, each with its distance from the current price
/// and a bar scaled to the farthest level.
class _PriceLadder extends StatelessWidget {
  final AnalysisLevels levels;
  const _PriceLadder({required this.levels});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entries = sortedLevels(levels);
    final current = levels.priceAtAnalysis;

    double maxDist = 0;
    for (final e in entries) {
      final d = distancePercent(e.price, current);
      if (d != null && d.abs() > maxDist) maxDist = d.abs();
    }

    Widget row({
      required String label,
      required double price,
      required Color color,
      bool isCurrent = false,
    }) {
      final dist = isCurrent ? null : distancePercent(price, current);
      final distText = formatDistance(dist);
      final barFraction = (dist == null || maxDist <= 0)
          ? 0.0
          : (dist.abs() / maxDist).clamp(0.04, 1.0);
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? scheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent
              ? Border.all(color: scheme.primary.withValues(alpha: 0.6))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatLevel(price),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (distText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      distText,
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (barFraction > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: barFraction,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final rows = <Widget>[];
    var currentInserted = current == null;
    void addCurrent() => rows.add(
      row(
        label: l10n.structuredLevelPrice,
        price: current!,
        color: scheme.primary,
        isCurrent: true,
      ),
    );
    for (final e in entries) {
      if (!currentInserted && current! >= e.price) {
        addCurrent();
        currentInserted = true;
      }
      switch (e.kind) {
        case LevelKind.resistance:
          rows.add(
            row(
              label: l10n.structuredLevelResistance,
              price: e.price,
              color: _bearColor,
            ),
          );
        case LevelKind.support:
          rows.add(
            row(
              label: l10n.structuredLevelSupport,
              price: e.price,
              color: _bullColor,
            ),
          );
        case LevelKind.invalidation:
          rows.add(
            row(
              label: l10n.structuredLevelInvalidation,
              price: e.price,
              color: scheme.error,
            ),
          );
      }
    }
    if (!currentInserted) addCurrent();
    return Column(key: const Key('price_ladder'), children: rows);
  }
}

class _ConclusionCard extends StatelessWidget {
  final String text;
  final AnalysisBias? bias;
  const _ConclusionCard({required this.text, required this.bias});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final color = biasColor(bias, Theme.of(context).colorScheme);
    return Container(
      key: const Key('conclusion_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(biasIcon(bias), size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.structuredConclusionTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  final Color color;
  const _Bullets({
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
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
