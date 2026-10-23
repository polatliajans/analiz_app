import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/glossary_screen.dart';
import '../../theme/app_theme.dart';

/// True when the user's text scale makes side-by-side layouts too tight.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;

/// Static placeholder blocks shown while a tab loads (no animation, so tests
/// can settle).
class TabSkeleton extends StatelessWidget {
  final int blocks;
  const TabSkeleton({super.key, this.blocks = 4});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      key: const Key('tab-skeleton'),
      padding: const EdgeInsets.all(16),
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < blocks; i++)
              Container(
                height: i.isEven ? 72 : 48,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-tab error state with a retry button.
class TabError extends StatelessWidget {
  final VoidCallback onRetry;
  const TabError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const Key('tab-error'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(l10n.tabLoadFailed, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Empty / informational state: icon, title, optional body and action.
class TabMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  const TabMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      key: const Key('tab-message'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: muted),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Padding wrapper used by every tab's content.
class TabPadding extends StatelessWidget {
  final List<Widget> children;
  const TabPadding({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Card with a title row (optionally a glossary "?") and content.
class SectionCard extends StatelessWidget {
  final String title;
  final String? termId;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.termId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (termId != null) GlossaryHelp(termId: termId!),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Small "?" that opens the glossary on [termId].
class GlossaryHelp extends StatelessWidget {
  final String termId;
  const GlossaryHelp({super.key, required this.termId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: Key('glossary-$termId'),
      tooltip: l10n.glossaryHelpTooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      iconSize: 20,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.help_outline),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GlossaryScreen(initialTermId: termId),
        ),
      ),
    );
  }
}

/// "Label ........ value" row that wraps instead of overflowing.
class LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final String? termId;
  final Color? valueColor;

  const LabelValueRow({
    super.key,
    required this.label,
    required this.value,
    this.termId,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
          if (termId != null) GlossaryHelp(termId: termId!),
        ],
      ),
    );
  }
}

/// Rounded tinted label.
class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const Pill({super.key, required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = color ?? theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: base.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: base),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green/red tinted chip for a signed percent value.
class ChangePill extends StatelessWidget {
  final String label;
  final String value;
  final double sign;

  const ChangePill({
    super.key,
    required this.label,
    required this.value,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    final color = trendColor(context, sign);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-tone horizontal bar: [fraction] of the width is [leftColor].
class RatioBar extends StatelessWidget {
  final double fraction;
  final Color leftColor;
  final Color rightColor;

  const RatioBar({
    super.key,
    required this.fraction,
    required this.leftColor,
    required this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.5;
    final left = (f * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (left > 0)
              Expanded(
                flex: left,
                child: ColoredBox(color: leftColor),
              ),
            if (left < 1000)
              Expanded(
                flex: 1000 - left,
                child: ColoredBox(color: rightColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays children out in one or two columns depending on width and text scale.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AdaptiveGrid({super.key, required this.children, this.spacing = 8});

  @override
  Widget build(BuildContext context) {
    final large = isLargeText(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoUp = !large && constraints.maxWidth >= 280;
        final width = twoUp
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: width, child: c),
          ],
        );
      },
    );
  }
}

/// Muted explanatory text under a metric.
class HintText extends StatelessWidget {
  final String text;
  const HintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
