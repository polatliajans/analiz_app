import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seed of the Material 3 color scheme in both themes.
const appSeedColor = Colors.deepPurple;

/// System bars: transparent (the app draws edge-to-edge) with icons that
/// contrast with the theme's surface.
SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    // iOS naming is the opposite: the brightness of the bar's background.
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

ThemeData buildAppTheme(Brightness brightness) {
  final base = ThemeData(
    colorSchemeSeed: appSeedColor,
    useMaterial3: true,
    brightness: brightness,
  );
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      systemOverlayStyle: overlayStyleFor(brightness),
    ),
  );
}

/// `MaterialApp.builder`: paints the system bars to match the active theme
/// (so it follows the in-app setting, not the phone's).
Widget appThemeBuilder(BuildContext context, Widget? child) {
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: overlayStyleFor(Theme.of(context).brightness),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Green / red used for price moves, readable on the current theme's surface.
Color trendColor(BuildContext context, double? value) {
  final theme = Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  if (value == null || value == 0) return theme.colorScheme.onSurfaceVariant;
  if (value > 0) {
    return dark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);
  }
  return dark ? const Color(0xFFE57373) : const Color(0xFFB71C1C);
}

/// Colors of the candlestick chart: a dark board in the dark theme and a
/// light one in the light theme (candle colors stay exchange-like).
class ChartPalette {
  final Color background;
  final Color text;
  final Color grid;
  final Color selectFill;
  final Color selectBorder;
  final Color crossLine;
  final Color crossText;
  final Color infoText;
  final Color nowPriceText;
  final Color up;
  final Color down;

  const ChartPalette({
    required this.background,
    required this.text,
    required this.grid,
    required this.selectFill,
    required this.selectBorder,
    required this.crossLine,
    required this.crossText,
    required this.infoText,
    required this.nowPriceText,
    required this.up,
    required this.down,
  });

  static const dark = ChartPalette(
    background: Color(0xFF161A1E),
    text: Color(0xFFB7BDC6),
    grid: Color(0xFF2B3139),
    selectFill: Color(0xFF0D1722),
    selectBorder: Color(0xFF6C7A86),
    crossLine: Color(0xFFFFFFFF),
    crossText: Color(0xFFFFFFFF),
    infoText: Color(0xFFFFFFFF),
    nowPriceText: Color(0xFFFFFFFF),
    up: Color(0xFF0ECB81),
    down: Color(0xFFF6465D),
  );

  static const light = ChartPalette(
    background: Color(0xFFFFFFFF),
    text: Color(0xFF5E6673),
    grid: Color(0xFFE6E8EA),
    selectFill: Color(0xFFF0F2F5),
    selectBorder: Color(0xFF9AA4B2),
    crossLine: Color(0xFF1E2329),
    crossText: Color(0xFF1E2329),
    infoText: Color(0xFF1E2329),
    nowPriceText: Color(0xFFFFFFFF),
    up: Color(0xFF0B9E68),
    down: Color(0xFFD9304A),
  );

  static ChartPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
