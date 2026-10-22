import '../theme/app_theme.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Shows the blocking progress overlay; call the returned function to remove
/// it (safe to call more than once).
void Function() startAnalysisOverlay(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => const AnalysisProgressOverlay(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  navigator.push(route);
  return () {
    if (route.isActive) navigator.removeRoute(route);
  };
}

/// Runs [task] while a full-screen, non-dismissible progress overlay is shown.
/// The overlay is removed when the task completes or throws.
Future<T> runWithAnalysisOverlay<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  final close = startAnalysisOverlay(context);
  try {
    return await task();
  } finally {
    close();
  }
}

/// Full-screen blocking overlay with an animated candlestick-style loader.
class AnalysisProgressOverlay extends StatefulWidget {
  const AnalysisProgressOverlay({super.key});

  @override
  State<AnalysisProgressOverlay> createState() =>
      _AnalysisProgressOverlayState();
}

class _AnalysisProgressOverlayState extends State<AnalysisProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 90,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) => CustomPaint(
                          painter: _CandlesPainter(
                            progress: _controller.value,
                            up: trendColor(context, 1),
                            down: trendColor(context, -1),
                            line: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.analysisInProgress,
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.analysisMayTakeTime,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandlesPainter extends CustomPainter {
  final double progress;
  final Color up;
  final Color down;
  final Color line;

  _CandlesPainter({
    required this.progress,
    required this.up,
    required this.down,
    required this.line,
  });

  static const _count = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / _count;
    final bodyW = slot * 0.5;
    final path = Path();

    for (var i = 0; i < _count; i++) {
      final phase = progress * 2 * math.pi - i * 0.9;
      final wave = (math.sin(phase) + 1) / 2; // 0..1
      final isUp = math.cos(phase) >= 0;
      final color = isUp ? up : down;
      final cx = slot * i + slot / 2;

      final mid = size.height * (0.55 - 0.2 * math.sin(phase * 0.5 + i));
      final bodyH = size.height * (0.18 + 0.2 * wave);
      final wick = bodyH / 2 + size.height * 0.12;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx, mid - wick), Offset(cx, mid + wick), paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, mid), width: bodyW, height: bodyH),
          const Radius.circular(2),
        ),
        paint,
      );

      if (i == 0) {
        path.moveTo(cx, mid);
      } else {
        path.lineTo(cx, mid);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = line.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CandlesPainter old) => old.progress != progress;
}
