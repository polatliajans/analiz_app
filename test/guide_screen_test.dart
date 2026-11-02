import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/screens/guide_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String lang,
  Brightness brightness = Brightness.light,
  double scale = 1,
  double width = 360,
}) async {
  // Tall window so the lazy ListView builds every section.
  tester.view.physicalSize = Size(width, 40000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: brightness,
      ),
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const GuideScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final lang in ['en', 'tr', 'es']) {
    testWidgets('guide renders all sections in $lang', (tester) async {
      await _pump(tester, lang: lang);
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      for (final text in [
        l10n.guideTitle,
        l10n.guideAboutTitle,
        l10n.guideLevelsTitle,
        l10n.guideLevel1Name,
        l10n.guideLevel2Name,
        l10n.guideLevel3Name,
        l10n.guideExampleLabel,
        l10n.guideDirTitle,
        l10n.guideBuyTitle,
        l10n.guideSellTitle,
        l10n.guideFlowTitle,
        l10n.guideTipsTitle,
        l10n.guideTip1Title,
        l10n.guideTip7Title,
        l10n.guideCreditsTitle,
        l10n.guideDisclaimerTitle,
        l10n.guideDisclaimerBody,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (var i = 1; i <= 3; i++) {
        expect(find.byKey(ValueKey('guide-level-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('guide-disclaimer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final b in [Brightness.light, Brightness.dark]) {
      for (final w in [320.0, 360.0]) {
        testWidgets('guide no overflow $lang $b ${w}dp x1.6', (tester) async {
          await _pump(tester, lang: lang, brightness: b, scale: 1.6, width: w);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('guide-disclaimer')),
            findsOneWidget,
          );
        });
      }
    }
  }

  test('guide copy never promises profit', () async {
    final banned = RegExp(
      r'guarantee(d)? (profit|gain|return)|risk.free|sure profit|'
      r'garantili (kazan|kâr)|kesin (kazan|kâr)|risksiz|'
      r'ganancia(s)? (garantizada|segura)|sin riesgo',
      caseSensitive: false,
    );
    for (final lang in ['en', 'tr', 'es']) {
      final l = await AppLocalizations.delegate.load(Locale(lang));
      final all = [
        l.guideAboutBody,
        l.guideLevelsIntro,
        l.guideLevel1Desc,
        l.guideLevel2Desc,
        l.guideLevel3Desc,
        l.guideLevelsExample,
        l.guideBuyBody,
        l.guideSellBody,
        l.guideFlow1,
        l.guideFlow2,
        l.guideFlow3,
        l.guideFlow4,
        l.guideTip1Body,
        l.guideTip2Body,
        l.guideTip3Body,
        l.guideTip4Body,
        l.guideTip5Body,
        l.guideTip6Body,
        l.guideTip7Body,
        l.guideHomeCardSubtitle,
      ].join('\n');
      expect(banned.hasMatch(all), isFalse, reason: lang);
    }
  });
}
