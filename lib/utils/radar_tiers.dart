import 'package:flutter/material.dart';

/// Radar score tiers, calibrated to the multi-factor score distribution
/// (oversold depth, Bollinger stretch, trend, volume, reversal, support):
/// Strong >= 65, Good 50-64, Watch 38-49, Low < 38.
const int radarStrongMin = 65;
const int radarGoodMin = 50;
const int radarWatchMin = 38;

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

/// Who is looking at the radar; decides which terms may be requested.
enum RadarAccess { guest, free, pro }

/// Terms the server serves to [access]: Pro gets all, everyone else short.
List<String> radarAllowedTerms(RadarAccess access) => access == RadarAccess.pro
    ? const ['short', 'medium', 'long']
    : const ['short'];

bool radarTermAllowed(RadarAccess access, String? term) => term == null
    ? access == RadarAccess.pro
    : radarAllowedTerms(access).contains(term);
