import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_config_provider.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/plan_comparison_table.dart';

/// Where a guide entry point lives; reported as the `source` of
/// `guide_card_tapped`.
enum GuideSource { home, settings }

/// Opens the "How it works" guide and reports the tap.
Future<void> openGuide(
  BuildContext context,
  WidgetRef ref, {
  required GuideSource source,
}) {
  ref.read(analyticsProvider).logGuideCardTapped(source.name);
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const GuideScreen()));
}

/// "How it works": what the app is for, what the 1-3 signal levels mean, buy
/// vs. sell signals, usage tips, credits, the Free vs Pro table and the risk
/// disclaimer. Texts are static; only the level access note and the table
/// follow the server's plan config.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AboutSection(),
                gap,
                _LevelsSection(),
                gap,
                _DirectionSection(),
                gap,
                _TipsSection(),
                gap,
                _CreditsSection(),
                gap,
                const PlanComparison(),
                gap,
                _DisclaimerBlock(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ frame

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
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
                  Icon(icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
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
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}

/// Tinted box used for the worked examples; always labelled as hypothetical.
class _ExampleBox extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _ExampleBox({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ about

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      icon: Icons.insights_rounded,
      title: l10n.guideAboutTitle,
      children: [_Body(l10n.guideAboutBody)],
    );
  }
}

// ----------------------------------------------------------------- levels

class _LevelsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // The server decides how high Free accounts see (default 2); Pro always
    // sees level 3, guests get no chart signals at all.
    final freeMax = ref.watch(
      appConfigProvider.select((c) => c.plan.freeMaxSignalStrength),
    );
    final levels = [
      (l10n.guideLevel1Name, l10n.guideLevel1Desc),
      (l10n.guideLevel2Name, l10n.guideLevel2Desc),
      (l10n.guideLevel3Name, l10n.guideLevel3Desc),
    ];
    return _Section(
      icon: Icons.signal_cellular_alt_rounded,
      title: l10n.guideLevelsTitle,
      children: [
        _Body(l10n.guideLevelsIntro),
        const SizedBox(height: 12),
        for (var i = 0; i < levels.length; i++) ...[
          _LevelRow(level: i + 1, name: levels[i].$1, desc: levels[i].$2),
          const SizedBox(height: 12),
        ],
        _AccessNote(
          text: freeMax < 3
              ? l10n.guideLevelsProOnly(freeMax)
              : l10n.guideLevelsAllFree,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.guideLevelsUpgrade,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _ExampleBox(
          label: l10n.guideExampleLabel,
          children: [_Body(l10n.guideLevelsExample)],
        ),
      ],
    );
  }
}

/// Highlighted note on who sees which levels.
class _AccessNote extends StatelessWidget {
  final String text;
  const _AccessNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('guide-level-access-note'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 22,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One level: digit badge and 3-segment strength bar in the chart's own
/// signal colour and opacity steps (0.7 / 0.85 / 1.0), then name and meaning.
class _LevelRow extends StatelessWidget {
  final int level;
  final String name;
  final String desc;
  const _LevelRow({
    required this.level,
    required this.name,
    required this.desc,
  });

  static const _opacity = [0.7, 0.85, 1.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ChartPalette.of(Theme.of(context).brightness).up;
    return Semantics(
      container: true,
      label: '$name. $desc',
      excludeSemantics: true,
      child: Column(
        key: ValueKey('guide-level-$level'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DigitBadge(text: '$level', color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var s = 0; s < 3; s++) ...[
                if (s > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: s < level
                          ? color.withValues(alpha: _opacity[level - 1])
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DigitBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _DigitBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- direction

class _DirectionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = ChartPalette.of(Theme.of(context).brightness);
    final flow = [
      l10n.guideFlow1,
      l10n.guideFlow2,
      l10n.guideFlow3,
      l10n.guideFlow4,
    ];
    return _Section(
      icon: Icons.swap_vert_rounded,
      title: l10n.guideDirTitle,
      children: [
        _DirectionRow(
          key: const ValueKey('guide-buy'),
          icon: Icons.arrow_upward_rounded,
          color: palette.up,
          title: l10n.guideBuyTitle,
          body: l10n.guideBuyBody,
        ),
        const SizedBox(height: 12),
        _DirectionRow(
          key: const ValueKey('guide-sell'),
          icon: Icons.arrow_downward_rounded,
          color: palette.down,
          title: l10n.guideSellTitle,
          body: l10n.guideSellBody,
        ),
        const SizedBox(height: 12),
        _ExampleBox(
          label: l10n.guideFlowTitle,
          children: [
            for (var i = 0; i < flow.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DigitBadge(
                      text: '${i + 1}',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _Body(flow[i])),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DirectionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _DirectionRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- tips

class _TipsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tips = [
      (Icons.savings_outlined, l10n.guideTip1Title, l10n.guideTip1Body),
      (Icons.touch_app_outlined, l10n.guideTip2Title, l10n.guideTip2Body),
      (Icons.schedule_rounded, l10n.guideTip3Title, l10n.guideTip3Body),
      (Icons.verified_outlined, l10n.guideTip4Title, l10n.guideTip4Body),
      (Icons.flag_outlined, l10n.guideTip5Title, l10n.guideTip5Body),
      (Icons.directions_run_rounded, l10n.guideTip6Title, l10n.guideTip6Body),
      (
        Icons.notifications_active_outlined,
        l10n.guideTip7Title,
        l10n.guideTip7Body,
      ),
    ];
    return _Section(
      icon: Icons.tips_and_updates_outlined,
      title: l10n.guideTipsTitle,
      children: [
        for (var i = 0; i < tips.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tips[i].$1, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tips[i].$2,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(tips[i].$3, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- credits

class _CreditsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      icon: Icons.toll_outlined,
      title: l10n.guideCreditsTitle,
      children: [_Body(l10n.guideCreditsBody)],
    );
  }
}

// ------------------------------------------------------------- disclaimer

class _DisclaimerBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('guide-disclaimer'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.error.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 24,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.guideDisclaimerTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.guideDisclaimerBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
