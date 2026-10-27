import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

const _cardRadius = BorderRadius.all(Radius.circular(16));
const _cardMinHeight = 84.0;

/// The two compact cards at the very top of the home screen: the Pro upgrade
/// card (brand teal/blue) and the credit card (warm gold/orange, shows the
/// balance). Both have the same height. [showPro] false (Pro members) leaves
/// just the credit card, full width.
class HomeTopCards extends StatelessWidget {
  final bool showPro;

  /// Null for guests: the card then shows a short "Buy credits" text instead
  /// of a balance.
  final int? credits;
  final VoidCallback onPro;
  final VoidCallback onCredits;

  const HomeTopCards({
    super.key,
    required this.showPro,
    required this.credits,
    required this.onPro,
    required this.onCredits,
  });

  @override
  Widget build(BuildContext context) {
    final credit = HomeCreditCard(
      key: const ValueKey('home-credit-card'),
      credits: credits,
      onTap: onCredits,
    );
    if (!showPro) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _cardMinHeight),
        child: IntrinsicHeight(child: credit),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ProPromoCard(
              key: const ValueKey('home-pro-promo'),
              onTap: onPro,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: credit),
        ],
      ),
    );
  }
}

/// Small translucent capsule used as the call to action of both cards.
class _CardPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  const _CardPill({
    required this.text,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 2),
              Icon(icon, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact Pro upgrade card: crown, short title and a short CTA capsule.
class ProPromoCard extends StatelessWidget {
  final VoidCallback onTap;
  const ProPromoCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${l10n.homeProPromoTitle}. ${l10n.homeProPromoAction}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        borderRadius: _cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          // Same deepened brand gradient as the Pro page hero.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A8F70), Color(0xFF1B4FC9)],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 22,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            l10n.homeProPromoTitle,
                            maxLines: 1,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _CardPill(
                      text: l10n.homeProPromoAction,
                      color: Colors.white,
                      background: Colors.white.withValues(alpha: 0.2),
                      icon: Icons.arrow_forward_rounded,
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

/// Warm gold-to-orange credit card: the balance as a big number with a small
/// unit label and a "+ Buy credits" capsule, with a single gentle shine sweep
/// when it first appears (skipped when the system asks for reduced motion).
class HomeCreditCard extends StatefulWidget {
  final int? credits;
  final VoidCallback onTap;

  const HomeCreditCard({super.key, required this.credits, required this.onTap});

  @override
  State<HomeCreditCard> createState() => _HomeCreditCardState();
}

class _HomeCreditCardState extends State<HomeCreditCard>
    with SingleTickerProviderStateMixin {
  // Dark brown on gold/orange: strong contrast in light and dark themes.
  static const _ink = Color(0xFF3B1F00);

  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _shine.forward();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final credits = widget.credits;
    final label = credits == null
        ? l10n.homeBuyCredits
        : '${l10n.homeBuyCredits}, ${l10n.homeBuyCreditsBalance(credits)}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _cardRadius,
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: _cardRadius,
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: _cardRadius,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.toll_rounded,
                              size: 22,
                              color: _ink,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: credits == null
                                    ? Text(
                                        l10n.homeBuyCredits,
                                        maxLines: 1,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: _ink,
                                            ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$credits',
                                            key: const ValueKey(
                                              'home-credit-balance',
                                            ),
                                            maxLines: 1,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: _ink,
                                                  height: 1.1,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.homeCreditUnit,
                                            maxLines: 1,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: _ink,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _CardPill(
                            text: credits == null
                                ? l10n.homeBuyCreditsShort
                                : '+ ${l10n.homeBuyCredits}',
                            color: _ink,
                            background: Colors.white.withValues(alpha: 0.38),
                            icon: credits == null
                                ? Icons.arrow_forward_rounded
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) {
                            // Idle outside the sweep window (last 55% of the run).
                            final t = ((_shine.value - 0.45) / 0.55).clamp(
                              0.0,
                              1.0,
                            );
                            if (t <= 0 || t >= 1) return const SizedBox();
                            return Align(
                              alignment: AlignmentDirectional(
                                -1.6 + 3.2 * Curves.easeInOut.transform(t),
                                0,
                              ),
                              child: FractionallySizedBox(
                                widthFactor: 0.35,
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.45),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
