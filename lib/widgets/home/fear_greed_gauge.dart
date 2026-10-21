import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colors of the five Fear & Greed bands, from extreme fear to extreme greed.
const fearGreedBandColors = <Color>[
  Color(0xFFD32F2F),
  Color(0xFFEF6C00),
  Color(0xFFF9A825),
  Color(0xFF7CB342),
  Color(0xFF2E7D32),
];

/// Half-circle gauge for a 0-100 Fear & Greed value (no dependencies, drawn
/// with a [CustomPainter]). The value itself is shown by the caller.
class FearGreedGauge extends StatelessWidget {
  final int value;
  final double width;

  const FearGreedGauge({super.key, required this.value, this.width = 200});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width / 2 + 8,
        child: CustomPaint(
          painter: _GaugePainter(
            value: value.clamp(0, 100),
            needleColor: scheme.onSurface,
            trackGap: scheme.surface,
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int value;
  final Color needleColor;
  final Color trackGap;

  _GaugePainter({
    required this.value,
    required this.needleColor,
    required this.trackGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final radius = size.width / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.width / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const gap = 0.025; // radians between bands
    const bandSweep = math.pi / 5;
    for (var i = 0; i < 5; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = fearGreedBandColors[i]
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        math.pi + i * bandSweep + gap / 2,
        bandSweep - gap,
        false,
        paint,
      );
    }

    // Needle.
    final angle = math.pi + (value / 100) * math.pi;
    final tip = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    final inner =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.45);
    canvas.drawLine(
      inner,
      tip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.needleColor != needleColor ||
      old.trackGap != trackGap;
}
