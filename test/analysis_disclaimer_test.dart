import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/config/legal_links.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/structured_analysis.dart';
import 'package:kriptoanaliz/widgets/analysis_card.dart';

Widget _app(String locale, Widget home) => ProviderScope(
  child: MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  test('report mailto goes to support with an encoded subject and body', () {
    final u = LegalLinks.supportMailtoWith(
      subject: 'Analysis report - BTCUSDT 1h',
      body: 'line1\nline2',
    );
    expect(u.scheme, 'mailto');
    expect(u.path, 'support@cryptoanaliz.net');
    expect(u.queryParameters['subject'], 'Analysis report - BTCUSDT 1h');
    expect(u.queryParameters['body'], 'line1\nline2');
    expect(u.toString(), contains('subject=Analysis%20report'));
  });

  for (final lang in ['en', 'tr', 'es']) {
    testWidgets('plain analysis sheet: disclaimer + report ($lang)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          lang,
          Builder(
            builder: (c) => TextButton(
              onPressed: () =>
                  showAnalysisSheet(c, result: 'text', creditCost: 3),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      expect(find.text(l10n.analysisInfoDisclaimer), findsOneWidget);
      expect(find.text(l10n.reportAnalysis), findsOneWidget);
      expect(find.byKey(const Key('report-analysis')), findsOneWidget);
    });
  }

  testWidgets('structured analysis sheet has the report action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        'en',
        Builder(
          builder: (c) => TextButton(
            onPressed: () => showAnalysisSheet(
              c,
              result: 'text',
              creditCost: 3,
              structured: const StructuredAnalysis(
                symbol: 'BTCUSDT',
                timeframe: '1h',
                summary: 'Sideways.',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('report-analysis')),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -300),
    );
    expect(find.text('Not investment advice.'), findsOneWidget);
    expect(find.byKey(const Key('report-analysis')), findsOneWidget);
  });
}
