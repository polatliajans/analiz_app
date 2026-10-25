import 'package:flutter/material.dart';

/// Radar score tiers. Calibrated to real server data: short term ~30-59,
/// medium 33-70, long 30-65, so scores above 70 are rare.
const int radarStrongMin = 60;
const int radarGoodMin = 45;
const int radarWatchMin = 35;

enum RadarTier { strong, good, watch, weak }

RadarTier radarTierFor(int score) {
  if (score >= radarStrongMin) return RadarTier.strong;
  if (score >= radarGoodMin) return RadarTier.good;
  if (score >= radarWatchMin) return RadarTier.watch;
  return RadarTier.weak;
}

/// Brand colours.
const radarTeal = Color(0xFF12D6A0);
const radarGold = Color(0xFFF5B83D);

/// Colours of one tier for one brightness.
class RadarTierStyle {
  /// Ring / border colour.
  final Color accent;

  /// Second gradient colour (equals [accent] for flat tiers).
  final Color accentEnd;

  /// Text colour with enough contrast on [tint] and on the surface.
  final Color text;

  /// Soft translucent background for pills.
  final Color tint;

  const RadarTierStyle({
    required this.accent,
    required this.accentEnd,
    required this.text,
    required this.tint,
  });

  bool get hasGradient => accent != accentEnd;
}

RadarTierStyle radarTierStyle(RadarTier tier, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  switch (tier) {
    case RadarTier.strong:
      return RadarTierStyle(
        accent: radarTeal,
        accentEnd: radarGold,
        text: dark ? const Color(0xFFFFD376) : const Color(0xFF7A4E00),
        tint: radarGold.withValues(alpha: dark ? 0.16 : 0.20),
      );
    case RadarTier.good:
      const a = Color(0xFF0FB586);
      return RadarTierStyle(
        accent: dark ? radarTeal : a,
        accentEnd: dark ? radarTeal : a,
        text: dark ? const Color(0xFF4DE3BE) : const Color(0xFF05674D),
        tint: radarTeal.withValues(alpha: dark ? 0.14 : 0.16),
      );
    case RadarTier.watch:
      final a = dark ? const Color(0xFF5B9BFF) : const Color(0xFF2F6FDE);
      return RadarTierStyle(
        accent: a,
        accentEnd: a,
        text: dark ? const Color(0xFF9CC2FF) : const Color(0xFF1B4AA6),
        tint: a.withValues(alpha: dark ? 0.16 : 0.12),
      );
    case RadarTier.weak:
      const a = Color(0xFF8A929C);
      return RadarTierStyle(
        accent: a,
        accentEnd: a,
        text: dark ? const Color(0xFFB7BDC6) : const Color(0xFF5B636D),
        tint: a.withValues(alpha: dark ? 0.16 : 0.14),
      );
  }
}
