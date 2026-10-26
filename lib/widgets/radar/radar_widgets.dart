import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/radar_item.dart';
import '../../utils/radar_tiers.dart';
import '../../utils/radar_time.dart';

String radarTierLabel(AppLocalizations l10n, RadarTier tier) {
  switch (tier) {
    case RadarTier.strong:
      return l10n.radarTierStrong;
    case RadarTier.good:
      return l10n.radarTierGood;
    case RadarTier.watch:
      return l10n.radarTierWatch;
    case RadarTier.weak:
      return l10n.radarTierWeak;
  }
}

String radarTermLabel(AppLocalizations l10n, String term) {
  switch (term) {
    case 'short':
      return l10n.termShortLabel;
    case 'medium':
      return l10n.termMediumLabel;
    case 'long':
      return l10n.termLongLabel;
    default:
      return term;
  }
}

String radarAgoText(AppLocalizations l10n, RadarAgo ago) {
  switch (ago.kind) {
    case RadarAgoKind.now:
      return l10n.agoNow;
    case RadarAgoKind.minutes:
      return l10n.agoMinutes(ago.n);
    case RadarAgoKind.hours:
      return l10n.agoHours(ago.n);
    case RadarAgoKind.yesterday:
      return l10n.agoYesterday;
    case RadarAgoKind.days:
      return l10n.agoDays(ago.n);
  }
}

/// Small clock + relative time ("12 min ago"); the exact local date-time is
/// the tooltip and semantics label. Renders nothing when [detectedAt] is null.
class RadarDetectedLabel extends StatelessWidget {
  final DateTime? detectedAt;
  final Color color;
  final double fontSize;

  /// Injectable clock for tests.
  final DateTime? now;

  const RadarDetectedLabel({
    super.key,
    required this.detectedAt,
    required this.color,
    this.fontSize = 11.5,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final ago = radarAgoOf(detectedAt, now ?? DateTime.now());
    if (ago == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final exact = l10n.radarDetectedAt(
      DateFormat.yMMMd(locale).add_Hm().format(detectedAt!.toLocal()),
    );
    final text = radarAgoText(l10n, ago);
    return Tooltip(
      message: exact,
      child: Semantics(
        label: '$exact ($text)',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: fontSize + 1.5, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colour of a term (null = all terms) for the selector chips.
Color radarTermColor(String? term, Brightness b) {
  final dark = b == Brightness.dark;
  switch (term) {
    case 'short':
      return dark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED);
    case 'medium':
      return dark ? const Color(0xFF5B9BFF) : const Color(0xFF2F6FDE);
    case 'long':
      return dark ? const Color(0xFFFFA94D) : const Color(0xFFC25E00);
    default:
      return dark ? radarTeal : const Color(0xFF0A8F6A);
  }
}

/// Circular score gauge. Cheap: one CustomPaint, no animation.
class RadarScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final RadarTier tier;
  final Brightness brightness;

  /// Overrides the track and number colours (used on the dark hero card).
  final Color? trackColor;
  final Color? textColor;

  RadarScoreRing({
    super.key,
    required this.score,
    required this.size,
    this.trackColor,
    this.textColor,
    required this.brightness,
  }) : tier = radarTierFor(score);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = radarTierStyle(tier, brightness);
    final dark = brightness == Brightness.dark;
    final track =
        trackColor ??
        (dark ? Colors.white.withValues(alpha: 0.12) : Colors.black12);
    return Semantics(
      label: l10n.radarScoreSemantics(score, radarTierLabel(l10n, tier)),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: score.clamp(0, 100) / 100,
            track: track,
            start: style.accent,
            end: style.accentEnd,
            stroke: size * 0.11,
          ),
          child: Center(
            child: Text(
              '$score',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                height: 1,
                color: textColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color start;
  final Color end;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint..color = track);
    if (progress <= 0) return;
    final sweep = math.pi * 2 * progress;
    paint.shader = SweepGradient(
      startAngle: 0,
      endAngle: math.max(sweep, 0.01),
      colors: [start, end],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.start != start ||
      old.end != end ||
      old.stroke != stroke;
}

class RadarTierPill extends StatelessWidget {
  final RadarTier tier;
  final Brightness? brightness;
  const RadarTierPill({super.key, required this.tier, this.brightness});

  @override
  Widget build(BuildContext context) {
    final style = radarTierStyle(
      tier,
      brightness ?? Theme.of(context).brightness,
    );
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        radarTierLabel(l10n, tier),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.text,
        ),
      ),
    );
  }
}

String _marketLabel(RadarItem item) =>
    item.coin.marketType == 'futures' ? 'Futures' : 'Spot';

String _signedPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';

/// Regular list card; Strong cards get a gradient border, glow and a bigger
/// ring.
class RadarTile extends StatefulWidget {
  final RadarItem item;
  final VoidCallback onTap;

  /// Pro members get trend / volume chips and an expandable detail block.
  final bool pro;

  const RadarTile({
    super.key,
    required this.item,
    required this.onTap,
    this.pro = false,
  });

  @override
  State<RadarTile> createState() => _RadarTileState();
}

class _RadarTileState extends State<RadarTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onTap = widget.onTap;
    final showDetails = widget.pro && item.hasProDetails;
    final theme = Theme.of(context);
    final b = theme.brightness;
    final l10n = AppLocalizations.of(context)!;
    final tier = radarTierFor(item.technicalScore);
    final style = radarTierStyle(tier, b);
    final strong = tier == RadarTier.strong;
    final muted = theme.colorScheme.onSurfaceVariant;

    final inner = Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(strong ? 15 : 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(strong ? 15 : 14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: strong ? 14 : 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.coin.symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _marketLabel(item),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        RadarTierPill(tier: tier),
                        if (widget.pro)
                          ...radarSignalChips(context, item, dark: false),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${radarTermLabel(l10n, item.term)} (${item.timeframe})  ·  '
                      '${l10n.radarRsi(item.rsi?.toStringAsFixed(1) ?? '-')}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    if (item.detectedAt != null) ...[
                      const SizedBox(height: 3),
                      RadarDetectedLabel(
                        detectedAt: item.detectedAt,
                        color: muted.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RadarScoreRing(
                score: item.technicalScore,
                size: strong ? 58 : 46,
                brightness: b,
              ),
            ],
          ),
        ),
      ),
    );

    final Widget card = showDetails
        ? Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(strong ? 15 : 14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                inner,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    key: const Key('radar_expand'),
                    visualDensity: VisualDensity.compact,
                    iconSize: 22,
                    tooltip: _expanded
                        ? l10n.radarHideDetailsTooltip
                        : l10n.radarDetailsTooltip,
                    icon: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: RadarProDetails(item: item, dark: false),
                  ),
              ],
            ),
          )
        : inner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(strong ? 16 : 14),
        gradient: strong
            ? LinearGradient(colors: [style.accent, style.accentEnd])
            : null,
        border: strong
            ? null
            : Border.all(color: style.accent.withValues(alpha: 0.35)),
        boxShadow: strong
            ? [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      padding: strong ? const EdgeInsets.all(1.5) : null,
      child: card,
    );
  }
}

/// Hero card for the highest scoring coin.
class RadarTopPickCard extends StatelessWidget {
  final RadarItem item;
  final VoidCallback onTap;

  /// Pro members also see trend / volume chips, the AI note and the factors.
  final bool pro;

  const RadarTopPickCard({
    super.key,
    required this.item,
    required this.onTap,
    this.pro = false,
  });

  static const _bgA = Color(0xFF062A24);
  static const _bgB = Color(0xFF0D3B33);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The card is always dark so white text keeps its contrast in both themes.
    const b = Brightness.dark;
    final tier = radarTierFor(item.technicalScore);
    final style = radarTierStyle(tier, b);
    final change = item.coin.priceChangePercent24h;
    final up = (change ?? 0) >= 0;
    final soft = Colors.white.withValues(alpha: 0.82);

    Widget chip(String text, {Color? color}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? soft,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_bgA, style.accent, 0.12)!,
            Color.lerp(_bgB, style.accentEnd, 0.18)!,
          ],
        ),
        border: Border.all(color: style.accent.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.30),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: radarGold,
                          ),
                          Text(
                            l10n.radarTopPick.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                              color: radarGold,
                            ),
                          ),
                          RadarTierPill(tier: tier, brightness: b),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.coin.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (item.detectedAt != null) ...[
                        const SizedBox(height: 4),
                        RadarDetectedLabel(
                          detectedAt: item.detectedAt,
                          color: soft,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          chip(
                            '${radarTermLabel(l10n, item.term)} (${item.timeframe})',
                          ),
                          chip(
                            l10n.radarRsi(item.rsi?.toStringAsFixed(1) ?? '-'),
                          ),
                          if (change != null)
                            chip(
                              _signedPct(change),
                              color: up
                                  ? const Color(0xFF4DE3A0)
                                  : const Color(0xFFFF8A98),
                            ),
                          if (pro)
                            ...radarSignalChips(context, item, dark: true),
                        ],
                      ),
                      if (pro && item.hasProDetails) ...[
                        const SizedBox(height: 12),
                        RadarProDetails(item: item, dark: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                RadarScoreRing(
                  score: item.technicalScore,
                  size: 84,
                  brightness: b,
                  trackColor: Colors.white.withValues(alpha: 0.14),
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Term selector: colourful segmented chips with timeframe hint and count.
class RadarTermSelector extends StatelessWidget {
  final String? selected;

  /// Count per term key (null key = all). Missing = not known yet.
  final Map<String?, int> counts;

  /// Timeframe hint per term key, e.g. "15m · 1h".
  final Map<String?, String> hints;
  final ValueChanged<String?> onSelected;

  /// Hide the "All" chip (non-Pro members only ever see the short term).
  final bool showAll;

  /// Terms shown with a lock; tapping one calls [onLocked] instead.
  final Set<String> locked;
  final ValueChanged<String>? onLocked;

  const RadarTermSelector({
    super.key,
    required this.selected,
    required this.counts,
    required this.hints,
    required this.onSelected,
    this.showAll = true,
    this.locked = const {},
    this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final terms = <(String?, String)>[
      if (showAll) (null, l10n.termAll),
      ('short', l10n.termShort),
      ('medium', l10n.termMedium),
      ('long', l10n.termLong),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in terms)
          _chip(context, theme, t.$1, t.$2, selected == t.$1),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    ThemeData theme,
    String? key,
    String label,
    bool sel,
  ) {
    final isLocked = key != null && locked.contains(key);
    final color = isLocked
        ? theme.colorScheme.onSurfaceVariant
        : radarTermColor(key, theme.brightness);
    final count = isLocked ? null : counts[key];
    final hint = isLocked ? null : hints[key];
    return Semantics(
      button: true,
      selected: sel,
      label: isLocked
          ? AppLocalizations.of(context)!.radarTermLocked(label)
          : null,
      excludeSemantics: isLocked,
      child: Material(
        color: sel ? color.withValues(alpha: 0.16) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: sel ? color : theme.colorScheme.outlineVariant,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            if (isLocked) {
              onLocked?.call(key);
            } else {
              onSelected(key);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLocked) ...[
                      Icon(Icons.lock_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? color : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: sel ? 0.25 : 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hint != null && hint.isNotEmpty)
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
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

class RadarEmptyState extends StatelessWidget {
  const RadarEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  radarTeal.withValues(alpha: 0.22),
                  radarTeal.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(color: radarTeal.withValues(alpha: 0.35)),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.radar_rounded, size: 56, color: radarTeal),
                Positioned(
                  right: 22,
                  bottom: 24,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 24,
                    color: radarGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.radarEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.radarEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

void showRadarInfoSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      Widget para(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: radarTermColor(null, theme.brightness)),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.radarHowTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              para(Icons.trending_down_rounded, l10n.radarHowOversold),
              para(
                Icons.speed_rounded,
                l10n.radarHowScore(
                  radarStrongMin,
                  radarGoodMin,
                  radarStrongMin - 1,
                  radarWatchMin,
                  radarGoodMin - 1,
                ),
              ),
              para(Icons.tune_rounded, l10n.radarHowFactors),
              para(Icons.schedule_rounded, l10n.radarHowTerms),
              para(Icons.info_outline_rounded, l10n.radarHowDisclaimer),
            ],
          ),
        ),
      );
    },
  );
}

const _factorOrder = [
  'oversold',
  'bollinger',
  'trend',
  'volume',
  'reversal',
  'support',
];

String? _factorLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'oversold':
      return l10n.radarFactorOversold;
    case 'bollinger':
      return l10n.radarFactorBollinger;
    case 'trend':
      return l10n.radarFactorTrend;
    case 'volume':
      return l10n.radarFactorVolume;
    case 'reversal':
      return l10n.radarFactorReversal;
    case 'support':
      return l10n.radarFactorSupport;
  }
  return null;
}

/// Trend arrow and volume ratio chips (empty when the server sent neither).
List<Widget> radarSignalChips(
  BuildContext context,
  RadarItem item, {
  required bool dark,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  Widget chip(Key key, IconData? icon, String text, Color color) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: 0.10)
          : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
  final muted = dark
      ? Colors.white.withValues(alpha: 0.82)
      : theme.colorScheme.onSurfaceVariant;
  final upColor = dark ? const Color(0xFF4DE3A0) : const Color(0xFF05674D);
  final downColor = dark ? const Color(0xFFFF8A98) : const Color(0xFFB3261E);
  return [
    if (item.trend == 'up')
      chip(
        const Key('radar_trend_chip'),
        Icons.trending_up_rounded,
        l10n.radarTrendUp,
        upColor,
      ),
    if (item.trend == 'down')
      chip(
        const Key('radar_trend_chip'),
        Icons.trending_down_rounded,
        l10n.radarTrendDown,
        downColor,
      ),
    if (item.volumeRatio != null)
      chip(
        const Key('radar_volume_chip'),
        null,
        l10n.radarVolumeRatio(item.volumeRatio!.toStringAsFixed(1)),
        muted,
      ),
  ];
}

/// Known factors of [item]'s breakdown, in display order (missing ones hidden).
List<(String, double)> radarVisibleFactors(RadarItem item) => [
  for (final k in _factorOrder)
    if (item.scoreBreakdown?[k] != null) (k, item.scoreBreakdown![k]!),
];

/// Pro-only block: the AI note and the compact score-factor bars. Renders
/// nothing for parts the server did not send.
class RadarProDetails extends StatelessWidget {
  final RadarItem item;
  final bool dark;

  const RadarProDetails({super.key, required this.item, required this.dark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fg = dark ? Colors.white : theme.colorScheme.onSurface;
    final soft = dark
        ? Colors.white.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant;
    final panel = dark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.05);
    final accent = dark
        ? radarTeal
        : radarTierStyle(
            radarTierFor(item.technicalScore),
            theme.brightness,
          ).accent;

    final factors = radarVisibleFactors(item);
    final maxAbs = factors.fold<double>(
      1,
      (m, f) => f.$2.abs() > m ? f.$2.abs() : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.aiComment != null)
          Container(
            key: const Key('radar_ai_note'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.radarAiNote,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.aiComment!,
                  style: TextStyle(fontSize: 13, color: fg),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.radarAiNoteHint,
                  style: TextStyle(fontSize: 11, color: soft),
                ),
              ],
            ),
          ),
        if (item.aiComment != null && factors.isNotEmpty)
          const SizedBox(height: 10),
        if (factors.isNotEmpty)
          Column(
            key: const Key('radar_breakdown'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.radarFactorsTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: soft,
                ),
              ),
              const SizedBox(height: 6),
              for (final f in factors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          _factorLabel(l10n, f.$1)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: fg),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (f.$2.abs() / maxAbs).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: panel,
                            color: f.$2 < 0 ? const Color(0xFFE5677A) : accent,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          f.$2.toStringAsFixed(0),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// One compact row under the short list that points guests / free members to
/// what the next level unlocks. Pro never sees it.
class RadarUpsellRow extends StatelessWidget {
  final RadarAccess access;
  final VoidCallback onTap;

  const RadarUpsellRow({super.key, required this.access, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final guest = access == RadarAccess.guest;
    final color = guest
        ? radarTermColor('medium', theme.brightness)
        : radarGold;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('radar_upsell'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  guest ? Icons.login_rounded : Icons.workspace_premium_rounded,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    guest ? l10n.radarUpsellGuest : l10n.radarUpsellFree,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
