import 'dart:ui';

/// Pure geometry helpers for buy/sell signal markers so the price range can
/// reserve room for them (no clipping at the extreme high/low) and the
/// painter and tests share the same measurements.
/// A visible marker reduced to its candle extreme price and strength.
class MarkerPoint {
  final double price;
  final int strength;
  const MarkerPoint(this.price, this.strength);
}

/// A (min, max) price pair.
class PriceRange {
  final double min;
  final double max;
  const PriceRange(this.min, this.max);
}

/// Pixel room needed below / above the plotted price range.
class MarkerPadding {
  final double below;
  final double above;
  const MarkerPadding(this.below, this.above);
}

class MarkerGeometry {
  MarkerGeometry._();

  /// Distance between the wick end and the arrow tip.
  static const double gap = 6.0;

  /// Vertical gap between the arrow base and the strength badge.
  static const double badgeGap = 2.0;

  /// Strength badge (pill) height.
  static const double badgeHeight = 14.0;

  /// Extra breathing room beyond the badge.
  static const double margin = 3.0;

  static int clampLevel(int strength) =>
      strength < 1 ? 1 : (strength > 3 ? 3 : strength);

  static double sizeFactor(int strength) =>
      const [0.85, 1.0, 1.3][clampLevel(strength) - 1];

  static double arrowLength(int strength) => 8.0 * sizeFactor(strength);

  static double arrowHalfWidth(int strength) => 4.5 * sizeFactor(strength);

  /// Total vertical pixels a marker occupies beyond the candle extreme
  /// (arrow + badge + margin).
  static double extent(int strength) =>
      gap + arrowLength(strength) + badgeGap + badgeHeight + margin;

  /// Expands [min]/[max] so that markers needing [belowPx] pixels under the
  /// price [min] and [abovePx] pixels over [max] fit inside a plot area of
  /// [heightPx] pixels. Pass 0 for a side without markers. Returns the
  /// input unchanged when nothing is needed or the geometry is degenerate.
  static PriceRange expandRange({
    required double min,
    required double max,
    required double heightPx,
    double belowPx = 0,
    double abovePx = 0,
  }) {
    if (belowPx <= 0 && abovePx <= 0) return PriceRange(min, max);
    if (!(heightPx > 0) || !(max > min)) return PriceRange(min, max);
    final reserved = belowPx + abovePx;
    // Never reserve more than 60% of the plot, keeping candles readable.
    final usable = reserved > heightPx * 0.6 ? heightPx * 0.6 : reserved;
    final scale = usable / reserved;
    final below = belowPx * scale;
    final above = abovePx * scale;
    final range = max - min;
    final newRange = range / (1 - (below + above) / heightPx);
    final perPx = newRange / heightPx;
    return PriceRange(min - below * perPx, max + above * perPx);
  }

  /// Computes the pixel room needed on each side. [lows]/[highs] hold the
  /// extreme candle price and strength of every visible buy/sell marker.
  /// A marker needs room only when it sits within its own extent of the
  /// current edge.
  static MarkerPadding neededPadding({
    required double min,
    required double max,
    required double heightPx,
    required Iterable<MarkerPoint> buys,
    required Iterable<MarkerPoint> sells,
  }) {
    if (!(heightPx > 0) || !(max > min)) return const MarkerPadding(0, 0);
    final perPx = (max - min) / heightPx;
    double below = 0, above = 0;
    for (final b in buys) {
      final ext = extent(b.strength);
      final room = (b.price - min) / perPx;
      if (room < ext && ext > below) below = ext;
    }
    for (final s in sells) {
      final ext = extent(s.strength);
      final room = (max - s.price) / perPx;
      if (room < ext && ext > above) above = ext;
    }
    return MarkerPadding(below, above);
  }

  /// Where the badge sits relative to the candle extreme. Buy markers hang
  /// below the low, sell markers sit above the high.
  static Rect badgeRect({
    required bool isBuy,
    required int strength,
    required double textWidth,
  }) {
    final w = textWidth + 8 < badgeHeight ? badgeHeight : textWidth + 8;
    final offset = gap + arrowLength(strength) + badgeGap;
    final top = isBuy ? offset : -offset - badgeHeight;
    return Rect.fromLTWH(-w / 2, top, w, badgeHeight);
  }
}
