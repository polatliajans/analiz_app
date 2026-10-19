import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/glossary_data.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/screens/glossary_screen.dart';
import 'package:kriptoanaliz/utils/glossary_logic.dart';

Widget _app(String lang, {String? termId}) => MaterialApp(
  locale: Locale(lang),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: GlossaryScreen(initialTermId: termId),
);

void main() {
  group('glossary data', () {
    test('ids are unique', () {
      final ids = glossaryTerms.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every term has a non-empty name and text in all locales', () {
      for (final t in glossaryTerms) {
        for (final l in glossaryLocales) {
          final e = t.entries[l];
          expect(e, isNotNull, reason: '${t.id} missing $l');
          expect(e!.name.trim(), isNotEmpty, reason: '${t.id}/$l name');
          expect(e.text.trim(), isNotEmpty, reason: '${t.id}/$l text');
        }
      }
    });

    test('every category has terms and titles in all locales', () {
      for (final c in GlossaryCategory.values) {
        expect(glossaryTerms.any((t) => t.category == c), isTrue, reason: '$c');
        for (final l in glossaryLocales) {
          expect(glossaryCategoryTitles[c]![l]!.trim(), isNotEmpty);
        }
      }
    });

    test('descriptions are short (max 3 sentences)', () {
      for (final t in glossaryTerms) {
        for (final l in glossaryLocales) {
          final text = t
              .entry(l)
              .text
              .replaceAll(
                RegExp(r'(p\. ej\.|e.g.|i.e.|ör\.|maks\.|máx\.)'),
                '',
              );
          final n = RegExp(r'[.!?](\s|$)').allMatches(text).length;
          expect(n, lessThanOrEqualTo(3), reason: '${t.id}/$l');
        }
      }
    });
  });

  group('glossary search', () {
    test('matches aliases and long forms', () {
      expect(
        glossaryTermMatches(glossaryTermById('rsi')!, 'relative', 'tr'),
        isTrue,
      );
      expect(
        glossaryTermMatches(glossaryTermById('macd')!, 'histogram', 'en'),
        isTrue,
      );
      expect(glossaryTermMatches(glossaryTermById('di')!, '+DI', 'es'), isTrue);
    });

    test('folds Turkish and Spanish characters', () {
      expect(
        glossaryTermMatches(glossaryTermById('relvolume')!, 'GORELI', 'tr'),
        isTrue,
      );
      expect(
        glossaryTermMatches(glossaryTermById('funding')!, 'FONLAMA', 'tr'),
        isTrue,
      );
      expect(
        glossaryTermMatches(glossaryTermById('overbought')!, 'asiri', 'tr'),
        isTrue,
      );
      expect(
        glossaryTermMatches(glossaryTermById('regime')!, 'regimen', 'es'),
        isTrue,
      );
    });

    test('filters and groups; empty result for nonsense', () {
      final all = groupGlossary('', 'tr');
      expect(all.length, GlossaryCategory.values.length);
      final some = groupGlossary('atr', 'en');
      expect(some[GlossaryCategory.volatility], isNotEmpty);
      expect(some.length, lessThan(all.length));
      expect(groupGlossary('zzzqqq', 'en'), isEmpty);
    });
  });

  group('glossary screen', () {
    testWidgets('renders category headings', (tester) async {
      await tester.pumpWidget(_app('tr'));
      await tester.pumpAndSettle();
      expect(find.text('Teknik Terimler Sözlüğü'), findsOneWidget);
      expect(find.text('Trend & ortalamalar'), findsOneWidget);
      expect(find.text('Momentum'), findsOneWidget);
      expect(find.text('Oynaklık'), findsOneWidget);
      expect(find.text('Seviyeler'), findsOneWidget);
      expect(find.text('Hacim & akış'), findsOneWidget);
      expect(find.text('Türev piyasa'), findsOneWidget);
      expect(find.text('Piyasa & temel'), findsOneWidget);
      expect(find.text('Analiz kavramları'), findsOneWidget);
    });

    testWidgets('search filters terms and shows empty state', (tester) async {
      await tester.pumpWidget(_app('en'));
      await tester.pumpAndSettle();
      expect(find.text('Funding rate'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Relative Strength');
      await tester.pumpAndSettle();
      expect(find.text('RSI (Relative Strength Index)'), findsOneWidget);
      expect(find.text('Funding rate'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzqqq');
      await tester.pumpAndSettle();
      expect(find.text('No matching terms.'), findsOneWidget);
    });

    testWidgets('tapping a term expands its description', (tester) async {
      await tester.pumpWidget(_app('en'));
      await tester.pumpAndSettle();
      final text = glossaryTermById('trend')!.entry('en').text;
      expect(find.text(text), findsNothing);
      await tester.tap(find.text('Trend').first);
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
    });

    testWidgets('deep link expands and reveals the term', (tester) async {
      await tester.pumpWidget(_app('es', termId: 'baserate'));
      await tester.pumpAndSettle();
      final text = glossaryTermById('baserate')!.entry('es').text;
      expect(find.text(text), findsOneWidget);
    });
  });
}
