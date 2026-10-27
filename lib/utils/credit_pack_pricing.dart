import '../models/credit_package.dart';

/// Pulls the numeric amount out of a store-formatted price ("$4.99",
/// "₺49,99", "1.299,00 TL", "4,99 €"). Returns null when no amount can be
/// read, so callers can fall back instead of showing a wrong number.
({double value, String prefix, String suffix, String decimalSep})?
parseStorePrice(String raw) {
  final m = RegExp(r'\d[\d.,\s  ]*\d|\d').firstMatch(raw);
  if (m == null) return null;
  final amount = m.group(0)!.replaceAll(RegExp(r'[\s  ]'), '');
  final lastDot = amount.lastIndexOf('.');
  final lastComma = amount.lastIndexOf(',');
  String decimalSep = '.';
  String intPart = amount;
  String frac = '';
  if (lastDot >= 0 && lastComma >= 0) {
    // Both present: the later one is the decimal mark.
    decimalSep = lastDot > lastComma ? '.' : ',';
  } else if (lastDot >= 0 || lastComma >= 0) {
    final sep = lastDot >= 0 ? '.' : ',';
    final count = sep.allMatches(amount).length;
    final digitsAfter = amount.length - amount.lastIndexOf(sep) - 1;
    // A single mark followed by 1-2 digits is a decimal mark; three digits
    // (or repeated marks) read as thousands grouping.
    if (count == 1 && digitsAfter != 3) {
      decimalSep = sep;
    } else {
      decimalSep = sep == '.' ? ',' : '.';
    }
  }
  final idx = amount.lastIndexOf(decimalSep);
  if (idx >= 0 && amount.contains(decimalSep)) {
    intPart = amount.substring(0, idx);
    frac = amount.substring(idx + 1);
  }
  intPart = intPart.replaceAll(RegExp(r'[.,]'), '');
  final value = double.tryParse(frac.isEmpty ? intPart : '$intPart.$frac');
  if (value == null || !value.isFinite || value <= 0) return null;
  return (
    value: value,
    prefix: raw.substring(0, m.start),
    suffix: raw.substring(m.end),
    decimalSep: decimalSep,
  );
}

/// "₺0,49" style price per credit built from the store [price], keeping the
/// store's currency symbol, its position and its decimal mark. Null when the
/// price can't be parsed or [credits] is not positive.
String? formatPricePerCredit(String price, int credits) {
  if (credits <= 0) return null;
  final p = parseStorePrice(price);
  if (p == null) return null;
  final per = p.value / credits;
  final digits = per >= 0.095 ? 2 : 3;
  final text = per.toStringAsFixed(digits).replaceAll('.', p.decimalSep);
  return '${p.prefix}$text${p.suffix}';
}

/// One row of the pack list with everything the card needs.
class CreditPackOffer {
  final CreditPackage package;

  /// Store price when known, else the backend's USD fallback.
  final String priceLabel;

  /// Price per credit, null when the price can't be parsed.
  final String? perCredit;
  final bool bestValue;
  final bool popular;

  const CreditPackOffer({
    required this.package,
    required this.priceLabel,
    required this.perCredit,
    this.bestValue = false,
    this.popular = false,
  });
}

/// Builds the offers in the given order. The best-value badge goes to the pack
/// with the lowest price per credit (only when at least two packs are
/// comparable and it is strictly cheaper than the priciest one); "popular" to
/// the middle pack by size when there are three or more. Both are derived from
/// the data, never from pack ids.
List<CreditPackOffer> buildCreditPackOffers(
  List<CreditPackage> packages,
  Map<String, String> storePrices,
) {
  String labelOf(CreditPackage p) =>
      storePrices[p.storeProductId] ?? '\$${p.price}';

  // Rank on one consistent source: store prices only if every pack has a
  // parseable one, otherwise the backend's prices for all of them.
  final allStore =
      packages.isNotEmpty &&
      packages.every((p) {
        final s = storePrices[p.storeProductId];
        return s != null && parseStorePrice(s) != null;
      });
  double? unit(CreditPackage p) {
    final src = allStore ? storePrices[p.storeProductId]! : p.price;
    final v = parseStorePrice(src)?.value;
    if (v == null || p.creditAmount <= 0) return null;
    return v / p.creditAmount;
  }

  final units = [for (final p in packages) unit(p)];
  final known = [
    for (var i = 0; i < units.length; i++)
      if (units[i] != null) i,
  ];
  int? best;
  if (known.length >= 2) {
    var lo = known.first, hi = known.first;
    for (final i in known) {
      if (units[i]! < units[lo]!) lo = i;
      if (units[i]! > units[hi]!) hi = i;
    }
    if (units[lo]! < units[hi]!) best = lo;
  }

  int? popular;
  if (packages.length >= 3) {
    final bySize = [for (var i = 0; i < packages.length; i++) i]
      ..sort(
        (a, b) => packages[a].creditAmount.compareTo(packages[b].creditAmount),
      );
    final mid = bySize[(bySize.length - 1) ~/ 2];
    if (mid != best) popular = mid;
  }

  return [
    for (var i = 0; i < packages.length; i++)
      CreditPackOffer(
        package: packages[i],
        priceLabel: labelOf(packages[i]),
        perCredit: formatPricePerCredit(
          labelOf(packages[i]),
          packages[i].creditAmount,
        ),
        bestValue: i == best,
        popular: i == popular,
      ),
  ];
}
