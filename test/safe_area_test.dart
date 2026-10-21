import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/screens/auth_screen.dart';
import 'package:kriptoanaliz/screens/coin_picker_sheet.dart';
import 'package:kriptoanaliz/screens/email_auth_screen.dart';
import 'package:kriptoanaliz/screens/glossary_screen.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:kriptoanaliz/screens/home_shell.dart';
import 'package:kriptoanaliz/screens/language_selection_screen.dart';
import 'package:kriptoanaliz/screens/onboarding_screen.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:kriptoanaliz/widgets/analysis_card.dart';
import 'package:kriptoanaliz/widgets/pro_upsell_sheet.dart';

import 'helpers/insets_harness.dart';

/// Button that opens a sheet/dialog from within a Scaffold.
class _Opener extends StatelessWidget {
  final Future<void> Function(BuildContext) open;
  const _Opener(this.open);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    ),
  );
}

void main() {
  final area = usableArea();

  group('first-run and auth screens keep content out of the bars', () {
    testWidgets('onboarding', (tester) async {
      await pumpWithInsets(tester, const OnboardingScreen());
      expectInside(tester, find.byType(TextButton), area, reason: 'skip');
      expectInside(tester, find.byType(FilledButton), area, reason: 'next');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'onboarding on a small window with 2x text scrolls, no overflow',
      (tester) async {
        await pumpWithInsets(
          tester,
          const OnboardingScreen(),
          window: const Size(320, 480),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expectInside(
          tester,
          find.byType(FilledButton),
          usableArea(window: const Size(320, 480)),
          reason: 'next button',
        );
      },
    );

    testWidgets('language selection', (tester) async {
      await pumpWithInsets(tester, const LanguageSelectionScreen());
      expectInside(tester, find.text('Choose your language'), area);
      expectInside(tester, find.byType(ElevatedButton), area);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign in (guest variant)', (tester) async {
      await pumpWithInsets(tester, const AuthScreen(showGuest: true));
      expectInside(tester, find.byType(OutlinedButton).first, area);
      expectInside(tester, find.byType(TextButton), area, reason: 'guest');
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign in with the keyboard open stays scrollable', (
      tester,
    ) async {
      await pumpWithInsets(
        tester,
        const AuthScreen(showGuest: true),
        keyboard: insetsKeyboard,
        window: const Size(400, 560),
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(TextButton));
      await tester.pump();
      expectInside(
        tester,
        find.byType(TextButton),
        usableArea(window: const Size(400, 560), keyboard: insetsKeyboard),
      );
    });

    testWidgets('email sign in: submit button reachable above the keyboard', (
      tester,
    ) async {
      const window = Size(400, 600);
      await pumpWithInsets(
        tester,
        const EmailAuthScreen(),
        window: window,
        keyboard: insetsKeyboard,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.pump();
      expectInside(
        tester,
        find.byType(ElevatedButton),
        usableArea(window: window, keyboard: insetsKeyboard),
        reason: 'submit',
      );
    });
  });

  group('scrolling screens end above the gesture bar', () {
    testWidgets('settings: last row is reachable', (tester) async {
      await pumpWithInsets(tester, const SettingsScreen());
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 12; i++) {
        final pos = tester.state<ScrollableState>(scrollable).position;
        if (pos.pixels >= pos.maxScrollExtent - 0.5) break;
        await tester.drag(scrollable, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expectInside(
        tester,
        find.byType(ListTile).last,
        area,
        reason: 'last row',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('glossary: bottom spacer includes the inset', (tester) async {
      await pumpWithInsets(tester, const GlossaryScreen());
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200000),
      );
      await tester.pumpAndSettle();
      final spacer = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(SizedBox),
      );
      expect(
        tester.getSize(spacer.last).height,
        greaterThanOrEqualTo(24 + insetsBottom),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('home on its own: footer scrolls clear of the bottom inset', (
      tester,
    ) async {
      await pumpWithInsets(tester, const HomeScreen());
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expectInside(tester, find.textContaining('not endorsed'), area);
      expect(tester.takeException(), isNull);
    });
  });

  group('home shell', () {
    testWidgets('navigation bar content is above the gesture area', (
      tester,
    ) async {
      await pumpWithInsets(tester, const HomeShell(), settle: false);
      await tester.pump(const Duration(milliseconds: 200));
      expectInside(tester, find.text('Home').last, area, reason: 'home label');
      expectInside(tester, find.text('Profile'), area, reason: 'profile label');
      final bar = tester.getRect(find.byType(NavigationBar));
      // The bar's background extends under the (transparent) system bar.
      expect(bar.bottom, closeTo(insetsWindow.height, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('every tab renders under the insets without overflow', (
      tester,
    ) async {
      final c = await pumpWithInsets(tester, const HomeShell(), settle: false);
      await tester.pump(const Duration(milliseconds: 200));
      for (final i in [
        chartTabIndex,
        radarTabIndex,
        watchlistTabIndex,
        profileTabIndex,
        homeTabIndex,
      ]) {
        c.read(homeTabProvider.notifier).select(i);
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'tab $i');
      }
    });
  });

  group('sheets', () {
    testWidgets('pro upsell sheet: button above the gesture bar', (
      tester,
    ) async {
      await pumpWithInsets(
        tester,
        _Opener((c) => showProUpsell(c, ProFeature.deepAnalysis)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsWidgets);
      expectInside(tester, find.byType(FilledButton).last, area);
      expect(tester.takeException(), isNull);
    });

    testWidgets('analysis sheet: text stays inside the safe area', (
      tester,
    ) async {
      await pumpWithInsets(
        tester,
        _Opener(
          (c) =>
              showAnalysisSheet(c, result: 'ANALYSIS BODY ' * 5, creditCost: 2),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expectInside(tester, find.textContaining('ANALYSIS BODY'), area);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coin picker: search field sits above the keyboard', (
      tester,
    ) async {
      await pumpWithInsets(
        tester,
        _Opener((c) => showCoinPicker(c)),
        keyboard: insetsKeyboard,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expectInside(
        tester,
        find.byType(TextField),
        usableArea(keyboard: insetsKeyboard),
        reason: 'search field',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dialogs are laid out inside the safe area', (tester) async {
      await pumpWithInsets(
        tester,
        _Opener(
          (c) => showDialog<void>(
            context: c,
            builder: (_) => const AlertDialog(
              title: Text('Dialog title'),
              content: Text('Dialog body'),
            ),
          ),
        ),
        keyboard: insetsKeyboard,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expectInside(
        tester,
        find.text('Dialog title'),
        usableArea(keyboard: insetsKeyboard),
      );
    });
  });

  group('both themes', () {
    for (final b in [Brightness.dark, Brightness.light]) {
      testWidgets('shell renders in $b', (tester) async {
        await pumpWithInsets(
          tester,
          const HomeShell(),
          brightness: b,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      });

      testWidgets('onboarding renders in $b', (tester) async {
        await pumpWithInsets(tester, const OnboardingScreen(), brightness: b);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
