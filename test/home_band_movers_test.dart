import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/widgets/home/market_pulse_row.dart';

import 'helpers/home_fakes.dart';
import 'helpers/home_harness.dart';

Finder _pulseCards() => find.descendant(
  of: find.byType(MarketPulseRow),
  matching: find.byType(Card),
);

void main() {
  group('top band', () {
    testWidgets('shows name, credits and plan chips; no greeting or title', (
      tester,
    ) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()));
      expect(find.text('Ayse'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-credits-chip')), findsOneWidget);
      expect(find.text('80 credits'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.textContaining('Hello'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      final chip = tester.getRect(
        find.byKey(const ValueKey('home-credits-chip')),
      );
      expect(chip.height, lessThanOrEqualTo(40));
      final nameRect = tester.getRect(find.text('Ayse'));
      expect(chip.center.dy, closeTo(nameRect.center.dy, 8));
      expect(nameRect.left, lessThan(chip.left));
    });

    testWidgets('pro member gets a Pro plan chip', (tester) async {
      final json = fullHomeJson()
        ..['credits'] = {'balance': 300, 'is_pro': true};
      await pumpHome(tester, handler: okHome(json));
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Free'), findsNothing);
    });

    testWidgets('keeps clear of the status bar', (tester) async {
      await pumpHome(
        tester,
        handler: okHome(fullHomeJson()),
        padding: const EdgeInsets.only(top: 48, bottom: 34),
      );
      expect(tester.getRect(find.text('Ayse')).top, greaterThanOrEqualTo(48));
    });

    testWidgets('long name does not overflow at 1.6 text scale', (
      tester,
    ) async {
      await pumpHome(
        tester,
        handler: okHome(fullHomeJson()),
        member: const Member(
          id: 1,
          name: 'Alexandria Bartholomew Montgomery-Fitzgerald',
          email: 'a@b.c',
          role: 'user',
          creditBalance: 123456,
        ),
        textScale: 1.6,
        size: const Size(320, 3600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('market pulse row', () {
    testWidgets('two equal-height half-width cards with a 12dp gap', (
      tester,
    ) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()));
      expect(_pulseCards(), findsNWidgets(2));
      final left = tester.getRect(_pulseCards().at(0));
      final right = tester.getRect(_pulseCards().at(1));
      expect(left.width, closeTo(right.width, 0.5));
      expect(left.height, closeTo(right.height, 0.5));
      expect(left.top, closeTo(right.top, 0.5));
      expect(right.left - left.right, closeTo(12, 0.5));
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('60.2%'), findsOneWidget);
      expect(find.text('+0.77%'), findsOneWidget);
      expect(find.text('Bull'), findsOneWidget);
    });

    testWidgets('stacks below 340dp', (tester) async {
      await pumpHome(
        tester,
        handler: okHome(fullHomeJson()),
        size: const Size(330, 3600),
      );
      expect(_pulseCards(), findsNWidgets(2));
      final top = tester.getRect(_pulseCards().at(0));
      final bottom = tester.getRect(_pulseCards().at(1));
      expect(bottom.top, greaterThan(top.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('only BTC data renders a single full-width card', (
      tester,
    ) async {
      final json = fullHomeJson();
      json['market'] = {
        ...(json['market'] as Map<String, dynamic>),
        'fear_greed': null,
      };
      await pumpHome(tester, handler: okHome(json));
      expect(_pulseCards(), findsOneWidget);
      expect(tester.getRect(_pulseCards()).width, greaterThan(300));
    });
  });

  group('market movers', () {
    testWidgets('shows 5 gainers by default, all 7 with show more', (
      tester,
    ) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()));
      expect(find.text('Gainers'), findsOneWidget);
      expect(find.text('Losers'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.textContaining('GAIN0'), findsOneWidget);
      expect(find.textContaining('GAIN4'), findsOneWidget);
      expect(find.textContaining('GAIN5'), findsNothing);
      expect(find.text('+20.00%'), findsOneWidget);
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();
      expect(find.textContaining('GAIN6'), findsOneWidget);
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.textContaining('GAIN5'), findsNothing);
    });

    testWidgets('losers tab shows negative changes', (tester) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()));
      await tester.tap(find.text('Losers'));
      await tester.pumpAndSettle();
      expect(find.textContaining('LOSE0'), findsOneWidget);
      expect(find.textContaining('GAIN0'), findsNothing);
      expect(find.text('-10.00%'), findsOneWidget);
    });

    testWidgets('volume tab shows abbreviated quote volume', (tester) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()));
      await tester.tap(find.text('Volume'));
      await tester.pumpAndSettle();
      expect(find.text('Vol 1.2B'), findsOneWidget);
      expect(find.text('Vol 345M'), findsOneWidget);
      expect(find.text('Vol 12.3M'), findsOneWidget);
    });

    testWidgets('tapping a row opens the chart for that coin', (tester) async {
      final h = await pumpHome(tester, handler: okHome(fullHomeJson()));
      await tester.tap(find.textContaining('GAIN1'));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), chartTabIndex);
      final coin = h.container.read(selectedCoinProvider).value!;
      expect(coin.symbol, 'GAIN1USDT');
      expect(coin.id, 101);
    });

    testWidgets('hidden when market_movers is missing', (tester) async {
      final json = fullHomeJson()..remove('market_movers');
      await pumpHome(tester, handler: okHome(json));
      expect(find.text('Gainers'), findsNothing);
      expect(find.text('My watchlist'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hidden when market_movers is garbage', (tester) async {
      final json = fullHomeJson()..['market_movers'] = 'nope';
      await pumpHome(tester, handler: okHome(json));
      expect(find.text('Gainers'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cached response without market_movers renders', (
      tester,
    ) async {
      final body = fullHomeJson()..remove('market_movers');
      await pumpHome(
        tester,
        prefs: cachedHomePrefs(body),
        handler: () => Future.error(HomeException('offline')),
      );
      expect(find.text('Gainers'), findsNothing);
      expect(find.text('Fear & Greed'), findsOneWidget);
    });

    testWidgets('cached response with market_movers renders', (tester) async {
      await pumpHome(
        tester,
        prefs: cachedHomePrefs(fullHomeJson()),
        handler: () => Future.error(HomeException('offline')),
      );
      expect(find.text('Gainers'), findsOneWidget);
      expect(find.textContaining('GAIN0'), findsOneWidget);
    });

    testWidgets('segmented control survives 1.6 text scale in Turkish', (
      tester,
    ) async {
      await pumpHome(
        tester,
        handler: okHome(fullHomeJson()),
        locale: 'tr',
        textScale: 1.6,
        size: const Size(320, 8000),
      );
      expect(find.text('Yükselenler'), findsOneWidget);
      expect(find.text('Düşenler'), findsOneWidget);
      expect(find.text('Hacim'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('quick actions', () {
    testWidgets('radar shortcut opens the radar tab', (tester) async {
      final h = await pumpHome(tester, handler: okHome(fullHomeJson()));
      await tester.tap(find.byKey(const ValueKey('quick-radar')));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), radarTabIndex);
    });

    testWidgets('deep analysis shortcut opens the chart tab', (tester) async {
      final h = await pumpHome(tester, handler: okHome(fullHomeJson()));
      await tester.tap(find.byKey(const ValueKey('quick-deep')));
      await tester.pumpAndSettle();
      expect(h.container.read(homeTabProvider), chartTabIndex);
    });

    testWidgets('guests get them too, account-only ones locked', (
      tester,
    ) async {
      await pumpHome(tester, handler: okHome(fullHomeJson()), member: null);
      expect(find.byKey(const ValueKey('quick-radar')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-glossary')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quick-deep')),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quick-radar')),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
    });
  });

  group('home screen under system insets', () {
    testWidgets('keyboard + bars: no overflow, last content reachable', (
      tester,
    ) async {
      await pumpHome(
        tester,
        handler: okHome(fullHomeJson()),
        size: const Size(360, 700),
        padding: const EdgeInsets.only(top: 48, bottom: 34),
        viewInsets: const EdgeInsets.only(bottom: 300),
      );
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.textContaining('not endorsed'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
