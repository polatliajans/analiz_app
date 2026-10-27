import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/widgets/home/home_sections.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection dir = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => Directionality(textDirection: dir, child: c!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    ),
  );
}

HomeHeader _header(String? name, {bool isPro = false}) =>
    HomeHeader(name: name, isPro: isPro, staleNote: null, onPro: () {});

void main() {
  const chipKey = ValueKey('home-plan-chip');

  testWidgets('plan chip is flush with the trailing content edge', (
    tester,
  ) async {
    await _pump(tester, _header('Ali ÇEVİK'));
    final chip = tester.getRect(find.byKey(chipKey));
    expect(chip.right, closeTo(360 - 16, 0.5));
    expect(tester.getRect(find.text('Ali ÇEVİK')).left, closeTo(16, 0.5));
    expect(find.text('Ücretsiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pro chip is flush right too', (tester) async {
    await _pump(tester, _header('Ali ÇEVİK', isPro: true));
    expect(tester.getRect(find.byKey(chipKey)).right, closeTo(360 - 16, 0.5));
  });

  testWidgets('long name ellipsizes without overflow; chip stays at end', (
    tester,
  ) async {
    await _pump(tester, _header('Muhammed Abdurrahman Çelebi-Karadeniz ' * 3));
    expect(tester.takeException(), isNull);
    final chip = tester.getRect(find.byKey(chipKey));
    expect(chip.right, closeTo(360 - 16, 0.5));
    final name = tester.getRect(find.byType(Text).first);
    expect(name.right, lessThanOrEqualTo(chip.left));
  });

  testWidgets('empty (guest-like) name still puts chip at the end', (
    tester,
  ) async {
    await _pump(tester, _header(null));
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byKey(chipKey)).right, closeTo(360 - 16, 0.5));
  });

  testWidgets('RTL: chip at the left (trailing) edge', (tester) async {
    await _pump(tester, _header('Ali'), dir: TextDirection.rtl);
    expect(tester.getRect(find.byKey(chipKey)).left, closeTo(16, 0.5));
  });
}
