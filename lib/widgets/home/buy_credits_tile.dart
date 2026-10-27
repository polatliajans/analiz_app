import 'package:flutter/material.dart';

import '../brand_page.dart';

/// The accent "buy credits" shortcut of the home quick-action row: a brand
/// gradient tile (coin + plus badge, label, optional balance line) with a
/// single gentle shine sweep when it first appears. The sweep is skipped when
/// the system asks for reduced motion.
class BuyCreditsTile extends StatefulWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const BuyCreditsTile({
    super.key,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  State<BuyCreditsTile> createState() => _BuyCreditsTileState();
}

class _BuyCreditsTileState extends State<BuyCreditsTile>
    with SingleTickerProviderStateMixin {
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
    // One pass, after a short pause so it is noticed rather than missed.
    if (!MediaQuery.disableAnimationsOf(context)) _shine.forward();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(18));
    final sub = widget.subtitle;
    return Semantics(
      button: true,
      label: sub == null ? widget.label : '${widget.label}, $sub',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFF0A8F70), Color(0xFF1B4FC9)],
          ),
          boxShadow: [
            BoxShadow(
              color: brandBlue.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                              child: const Icon(
                                Icons.toll_rounded,
                                size: 26,
                                color: Color(0xFFFFD54F),
                              ),
                            ),
                            PositionedDirectional(
                              end: -3,
                              top: -3,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: Color(0xFF1B4FC9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
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
                                        Colors.white.withValues(alpha: 0.35),
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
