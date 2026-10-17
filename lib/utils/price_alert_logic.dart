/// Direction of a price alert relative to the price at creation time.
enum AlertDirection {
  above,
  below;

  String get apiValue => name;

  static AlertDirection? fromApi(String? value) {
    for (final d in AlertDirection.values) {
      if (d.name == value) return d;
    }
    return null;
  }
}

/// Quick-adjust percentages shown in the alert sheet.
const alertQuickPercents = <int>[-10, -5, -2, -1, 1, 2, 5, 10];

/// Direction implied by [target] versus the [current] price; null when they
/// are equal or either value is unusable.
AlertDirection? directionForTarget(double? target, double? current) {
  if (target == null || current == null) return null;
  if (!target.isFinite || !current.isFinite) return null;
  if (target > current) return AlertDirection.above;
  if (target < current) return AlertDirection.below;
  return null;
}

/// [current] moved by [percent] percent, rounded to the display precision of
/// the result so the text field never shows floating point noise.
double applyPercent(double current, num percent) {
  final raw = current * (1 + percent / 100);
  return double.parse(formatAlertPrice(raw));
}

/// Parses user input as a positive price. Accepts a comma as the decimal
/// separator. Returns null for empty, malformed or non-positive input.
double? parsePriceInput(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

/// Plain decimal text sized to the coin's price scale: 2 decimals for big
/// prices, up to 8 for tiny ones, without trailing zeros and without
/// exponent notation.
String formatAlertPrice(double price) {
  if (!price.isFinite || price <= 0) return '0';
  final int decimals;
  if (price >= 1000) {
    decimals = 2;
  } else if (price >= 1) {
    decimals = 4;
  } else if (price >= 0.01) {
    decimals = 6;
  } else {
    decimals = 8;
  }
  var text = price.toStringAsFixed(decimals);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
