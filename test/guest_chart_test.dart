import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/screens/guest_benefits_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/widgets/candlestick_chart.dart';

import 'helpers/chart_harness.dart';

Finder get _canvas => find.byKey(const Key('chart-area'));

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('chart-tab-bar')),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoSignalChromeOnCanvas() {
  // Nothing but the chart itself: no lock, no note, no strength badge.
  expect(
    find.descendant(of: _canvas, matching: find.byIcon(Icons.lock_outline)),
    findsNothing,
  );
  expect(
    find.descendant(of: _canvas, matching: find.byIcon(Icons.info_outline)),
    findsNothing,
  );
  expect(
    find.descendant(of: _canvas, matching: find.textContaining('Pro')),
    findsNothing,
  );
  expect(
    find.descendant(of: _canvas, matching: find.textContaining('signal')),
    findsNothing,
  );
}

void main() {
  group('guest', () {
    testWidgets('never requests signals and draws none on the canvas', (
      tester,
    ) async {
      final h = await pumpChartScreen(tester, member: null);
      expect(h.signals.calls, 0, reason: 'no chart-signals call without token');
      final chart = tester.widget<CandlestickChart>(
        find.byType(CandlestickChart),
      );
      expect(chart.signals, isEmpty);
      _expectNoSignalChromeOnCanvas();
      await disposeChartScreen(tester);
    });

    testWidgets('info row under the chart opens the benefits page', (
      tester,
    ) async {
      await pumpChartScreen(tester, member: null);
      final row = find.byKey(const Key('signals-info-row'));
      expect(row, findsOneWidget);
      expect(find.text('Sign in to see signals'), findsOneWidget);
      // Outside the canvas: below it.
      expect(
        tester.getTopLeft(row).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(_canvas).dy),
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(GuestBenefitsScreen), findsOneWidget);
      await disposeChartScreen(tester);
    });

    testWidgets('locked 1m chip opens the benefits page', (tester) async {
      await pumpChartScreen(tester, member: null);
      await tester.tap(find.widgetWithText(ChoiceChip, '1m'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestBenefitsScreen), findsOneWidget);
      await disposeChartScreen(tester);
    });

    for (final key in ['quick-analysis-button', 'deep-analysis-button']) {
      testWidgets('$key opens the benefits page, no raw error', (tester) async {
        await pumpChartScreen(tester, member: null);
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.byType(GuestBenefitsScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        await disposeChartScreen(tester);
      });
    }

    testWidgets('star and bell open the benefits page', (tester) async {
      await pumpChartScreen(tester, member: null);
      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();
      expect(find.byType(GuestBenefitsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.notifications_none).first);
      await tester.pumpAndSettle();
      expect(find.byType(GuestBenefitsScreen), findsOneWidget);
      await disposeChartScreen(tester);
    });

    for (final tab in [
      'Summary',
      'My analyses',
      'Market',
      'Signals',
      'Alerts',
    ]) {
      testWidgets('$tab tab is a clean locked state without requests', (
        tester,
      ) async {
        final h = await pumpChartScreen(tester, member: null);
        await _openTab(tester, tab);
        expect(find.byKey(const Key('guest-locked-tab')), findsOneWidget);
        expect(find.byKey(const Key('tab-error')), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(h.overview.calls, 0, reason: 'overview is auth-only');
        expect(h.history.calls, 0);
        expect(h.alerts.calls, 0);
        expect(h.signals.calls, 0);
        // The button leads to the benefits page.
        final button = find.descendant(
          of: find.byKey(const Key('guest-locked-tab')),
          matching: find.byType(FilledButton),
        );
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(GuestBenefitsScreen), findsOneWidget);
        await disposeChartScreen(tester);
      });
    }
  });

  group('free member', () {
    testWidgets('keeps the server signals; teaser sits below the canvas', (
      tester,
    ) async {
      final h = await pumpChartScreen(tester);
      expect(h.signals.calls, greaterThan(0));
      final chart = tester.widget<CandlestickChart>(
        find.byType(CandlestickChart),
      );
      // Levels 1-2 only (the level-3 one is capped away).
      expect(chart.signals.map((s) => s.strength), everyElement(lessThan(3)));
      expect(chart.signals, isNotEmpty);
      _expectNoSignalChromeOnCanvas();

      final row = find.byKey(const Key('signals-info-row'));
      expect(row, findsOneWidget);
      expect(
        find.text('Pro adds the strongest (level 3) signals, 1m/5m and alerts'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(row).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(_canvas).dy),
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      await disposeChartScreen(tester);
    });
  });

  group('Pro member', () {
    testWidgets('sees no teaser and all signal levels', (tester) async {
      await pumpChartScreen(tester, member: proMemberForChart);
      expect(find.byKey(const Key('signals-info-row')), findsNothing);
      final chart = tester.widget<CandlestickChart>(
        find.byType(CandlestickChart),
      );
      expect(chart.signals.map((s) => s.strength), contains(3));
      _expectNoSignalChromeOnCanvas();
      await disposeChartScreen(tester);
    });
  });

  for (final locale in ['en', 'tr', 'es']) {
    testWidgets('guest chart fits at 360dp / 1.6x ($locale)', (tester) async {
      await pumpChartScreen(
        tester,
        member: null,
        locale: locale,
        textScale: 1.6,
        size: const Size(360, 780),
      );
      expect(tester.takeException(), isNull);
      await disposeChartScreen(tester);
    });
  }
}
