import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/glossary_data.dart';
import 'package:kriptoanaliz/utils/home_logic.dart';

void main() {
  test('term of the day is deterministic per date and rotates daily', () {
    final a = termOfTheDay(DateTime(2026, 10, 21, 3));
    final b = termOfTheDay(DateTime(2026, 10, 21, 23, 59));
    expect(a.id, b.id);
    final next = termOfTheDay(DateTime(2026, 10, 22));
    expect(next.id, isNot(a.id));
    // Cycles through the whole glossary.
    final seen = <String>{
      for (var i = 0; i < glossaryTerms.length; i++)
        termOfTheDay(DateTime(2026, 1, 1).add(Duration(days: i))).id,
    };
    expect(seen.length, glossaryTerms.length);
  });

  test('fear & greed level: label first, value band as fallback', () {
    expect(fearGreedLevel('Extreme Fear', 90), FearGreedLevel.extremeFear);
    expect(fearGreedLevel('extreme_greed', 5), FearGreedLevel.extremeGreed);
    expect(fearGreedLevel('Neutral', 10), FearGreedLevel.neutral);
    expect(fearGreedLevel(null, 10), FearGreedLevel.extremeFear);
    expect(fearGreedLevel('???', 30), FearGreedLevel.fear);
    expect(fearGreedLevel(null, 50), FearGreedLevel.neutral);
    expect(fearGreedLevel(null, 60), FearGreedLevel.greed);
    expect(fearGreedLevel(null, 90), FearGreedLevel.extremeGreed);
  });

  test('price and percent formatting', () {
    expect(formatUsdPrice(82000, 'en'), '\$82,000');
    expect(formatUsdPrice(0.1534, 'en'), '\$0.1534');
    expect(formatUsdPrice(0.00001234, 'en'), '\$0.00001234');
    expect(formatSignedPct(1.024, 'en'), '+1.02%');
    expect(formatSignedPct(-4.5, 'en'), '-4.50%');
    expect(formatSignedPct(0, 'en'), '0.00%');
    expect(formatPlainPct(60.24, 'en'), '60.2%');
  });
}
