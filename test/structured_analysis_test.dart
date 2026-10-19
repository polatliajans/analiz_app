import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/ai_analysis_result.dart';
import 'package:kriptoanaliz/models/analysis_record.dart';
import 'package:kriptoanaliz/models/structured_analysis.dart';
import 'package:kriptoanaliz/utils/structured_analysis_logic.dart';
import 'package:kriptoanaliz/widgets/structured_analysis_view.dart';

Map<String, dynamic> _full() => {
  'schema_version': 1,
  'symbol': 'BTCUSDT',
  'market_type': 'futures',
  'timeframe': '4h',
  'bias': 'bullish',
  'confidence': 72,
  'horizon_candles': 12,
  'horizon_label': '2 days',
  'summary': 'Uptrend intact.',
  'drivers': [
    {
      'title': 'Funding',
      'detail': 'Neutral funding',
      'direction': 'neutral',
      'evidence': ['funding 0.01%'],
    },
  ],
  'scenarios': {
    'bull': {
      'description': 'Breakout',
      'trigger_level': 70000,
      'target': 72500.5,
      'probability': 0.5,
    },
    'base': {
      'description': 'Range',
      'trigger_level': null,
      'target': null,
      'probability': 30,
    },
    'bear': {'description': 'Drop', 'probability': 0.2},
  },
  'levels': {
    'price_at_analysis': 68000,
    'supports': [67000, 66000.5],
    'resistances': [69000],
    'invalidation': 65000,
  },
  'risks': ['Macro event'],
  'watch': ['CPI'],
  'data_quality': {
    'missing_sources': ['coinglass'],
    'notes': 'x',
  },
  'sources': [
    {
      'name': 'Alternative.me Fear and Greed',
      'url': 'https://alternative.me/crypto/fear-and-greed-index/',
      'note': 'index',
    },
    {'name': 'Binance'},
  ],
  'disclaimer': 'Not advice',
};

void main() {
  group('StructuredAnalysis.fromJson', () {
    test('parses a full payload', () {
      final s = StructuredAnalysis.fromJson(_full());
      expect(s.bias, AnalysisBias.bullish);
      expect(s.confidence, 72);
      expect(s.horizonCandles, 12);
      expect(s.horizonLabel, '2 days');
      expect(s.drivers.single.direction, AnalysisBias.neutral);
      expect(s.drivers.single.evidence, ['funding 0.01%']);
      expect(s.bull!.triggerLevel, 70000.0);
      expect(s.bull!.target, 72500.5);
      expect(s.base!.triggerLevel, isNull);
      expect(s.base!.probability, 30.0);
      expect(s.levels.supports, [67000.0, 66000.5]);
      expect(s.levels.invalidation, 65000.0);
      expect(s.missingSources, ['coinglass']);
      expect(s.sources.length, 2);
      expect(s.sources.first.url, isNotNull);
      expect(s.disclaimer, 'Not advice');
      expect(s.hasContent, isTrue);
    });

    test('tolerates missing fields', () {
      final s = StructuredAnalysis.fromJson({'bias': 'bearish'});
      expect(s.bias, AnalysisBias.bearish);
      expect(s.confidence, isNull);
      expect(s.drivers, isEmpty);
      expect(s.bull, isNull);
      expect(s.levels.isEmpty, isTrue);
      expect(s.hasContent, isTrue);
    });

    test('tolerates wrong types', () {
      final s = StructuredAnalysis.fromJson({
        'bias': 5,
        'confidence': 'abc',
        'summary': 12,
        'drivers': 'oops',
        'scenarios': [],
        'levels': {
          'supports': 'x',
          'resistances': ['a', 3, null],
        },
        'risks': [1, 'ok'],
        'sources': [
          1,
          {'url': 7},
        ],
        'data_quality': 'bad',
      });
      expect(s.bias, isNull);
      expect(s.confidence, isNull);
      expect(s.summary, isNull);
      expect(s.drivers, isEmpty);
      expect(s.hasScenarios, isFalse);
      expect(s.levels.resistances, [3.0]);
      expect(s.risks, ['ok']);
      expect(s.sources, isEmpty);
    });

    test('numeric strings and doubles are accepted', () {
      final s = StructuredAnalysis.fromJson({
        'confidence': 71.6,
        'levels': {
          'supports': ['100.5'],
        },
      });
      expect(s.confidence, 72);
      expect(s.levels.supports, [100.5]);
    });

    test('empty and invalid input yields null from tryParse', () {
      expect(StructuredAnalysis.tryParse(<String, dynamic>{}), isNull);
      expect(StructuredAnalysis.tryParse(null), isNull);
      expect(StructuredAnalysis.tryParse('text'), isNull);
      expect(StructuredAnalysis.tryParse([1]), isNull);
      expect(StructuredAnalysis.tryParse({'schema_version': 1}), isNull);
      expect(StructuredAnalysis.tryParse(_full()), isNotNull);
    });
  });

  group('logic', () {
    test('clampConfidence', () {
      expect(clampConfidence(null), isNull);
      expect(clampConfidence(-5), 0);
      expect(clampConfidence(150), 100);
      expect(clampConfidence(55.5), 56);
      expect(clampConfidence(double.nan), isNull);
    });

    test('probability handles 0..1 and 0..100', () {
      expect(probabilityFraction(0.35), 0.35);
      expect(probabilityFraction(35), 0.35);
      expect(probabilityPercent(0.35), 35);
      expect(probabilityPercent(120), 100);
      expect(probabilityPercent(-1), isNull);
      expect(probabilityPercent(null), isNull);
    });

    test('formatLevel', () {
      expect(formatLevel(null), '-');
      expect(formatLevel(68000), '68000');
      expect(formatLevel(0.12345678), '0.123457');
      expect(formatLevel(0), '-');
    });

    test('sortedLevels is descending with all kinds', () {
      final l = StructuredAnalysis.fromJson(_full()).levels;
      final e = sortedLevels(l);
      expect(e.map((x) => x.price).toList(), [69000, 67000, 66000.5, 65000]);
      expect(e.first.kind, LevelKind.resistance);
      expect(e.last.kind, LevelKind.invalidation);
    });

    test('card decision: structured vs plain text', () {
      expect(shouldShowStructured(null), isFalse);
      expect(shouldShowStructured(const StructuredAnalysis()), isFalse);
      expect(
        shouldShowStructured(StructuredAnalysis.fromJson(_full())),
        isTrue,
      );
    });
  });

  group('models', () {
    Map<String, dynamic> record(Object? structured, {String type = 'deep'}) => {
      'id': 1,
      'type': type,
      'coin_id': 1,
      'symbol': 'BTCUSDT',
      'market_type': 'spot',
      'timeframe': '1h',
      'result': 'text',
      'credit_cost': 3,
      'created_at': '2026-10-04T10:30:00.000000Z',
      'structured': structured,
    };

    test('AnalysisRecord parses structured and old records', () {
      final r = AnalysisRecord.fromJson(record(_full()));
      expect(r.structured?.bias, AnalysisBias.bullish);
      expect(showsBiasBadge(r), isTrue);
      final old = AnalysisRecord.fromJson(record(null));
      expect(old.structured, isNull);
      expect(showsBiasBadge(old), isFalse);
      final quick = AnalysisRecord.fromJson(record(_full(), type: 'quick'));
      expect(showsBiasBadge(quick), isFalse);
      final bad = AnalysisRecord.fromJson(record('garbage'));
      expect(bad.structured, isNull);
    });

    test('AiAnalysisResult parses structured', () {
      final r = AiAnalysisResult.fromJson({
        'id': 1,
        'result': 't',
        'credit_cost': 2,
        'structured': _full(),
      });
      expect(r.structured, isNotNull);
      final r2 = AiAnalysisResult.fromJson({
        'id': 1,
        'result': 't',
        'credit_cost': 2,
      });
      expect(r2.structured, isNull);
    });
  });

  testWidgets('structured view renders without errors at large text', (
    tester,
  ) async {
    final data = StructuredAnalysis.fromJson(_full());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: StructuredAnalysisView(data: data, creditCost: 3),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Bullish'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
  });

  group('redesigned view', () {
    Widget host(
      Map<String, dynamic> json, {
      ThemeData? theme,
      double textScale = 1,
    }) {
      return MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StructuredAnalysisView(
                  data: StructuredAnalysis.fromJson(json),
                  creditCost: 3,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> narrow(WidgetTester t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
    }

    Map<String, dynamic> withNew() => {
      ..._full(),
      'conclusion': 'Stay long above support.',
      'key_metrics': [
        {'label': 'RSI', 'value': '61', 'tone': 'bullish', 'hint': 'Strong'},
        {'label': 'Funding', 'value': '0.01%', 'tone': 'neutral', 'hint': ''},
        {'label': 'OI', 'value': '-4%', 'tone': 'bearish', 'hint': 'Falling'},
        {'label': '', 'value': 'dropped'},
      ],
    };

    testWidgets('old format renders without new sections', (t) async {
      await narrow(t);
      await t.pumpWidget(host(_full()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('conclusion_card')), findsNothing);
      expect(find.byKey(const Key('key_metrics')), findsNothing);
      expect(find.byKey(const Key('confidence_gauge')), findsOneWidget);
      expect(find.byKey(const Key('price_ladder')), findsOneWidget);
      expect(find.text('Uptrend intact.'), findsOneWidget);
    });

    testWidgets('new format shows metric tiles and conclusion', (t) async {
      await narrow(t);
      await t.pumpWidget(host(withNew()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('key_metrics')), findsOneWidget);
      expect(find.text('RSI'), findsOneWidget);
      expect(find.text('0.01%'), findsOneWidget);
      expect(find.text('Falling'), findsOneWidget);
      expect(find.text('dropped'), findsNothing);
      expect(find.byKey(const Key('conclusion_card')), findsOneWidget);
      expect(find.text('Final take'), findsOneWidget);
      expect(find.text('Stay long above support.'), findsOneWidget);
      // Conclusion sits above the disclaimer.
      expect(
        t.getTopLeft(find.byKey(const Key('conclusion_card'))).dy,
        lessThan(t.getTopLeft(find.text('Not advice')).dy),
      );
    });

    testWidgets('stacked probability bar shows given probabilities', (t) async {
      await narrow(t);
      await t.pumpWidget(host(_full()));
      await t.pumpAndSettle();
      final bar = find.byKey(const Key('probability_bar'));
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: find.text('50%')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('30%')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('20%')),
        findsOneWidget,
      );
    });

    testWidgets('driver tile expands and collapses on tap', (t) async {
      await narrow(t);
      final json = {
        ..._full(),
        'drivers': [
          {'title': 'First', 'detail': 'First detail', 'direction': 'bullish'},
          {
            'title': 'Second',
            'detail': 'Second detail',
            'direction': 'bullish',
          },
          {'title': 'Third', 'detail': 'Third detail', 'direction': 'bearish'},
        ],
      };
      await t.pumpWidget(host(json));
      await t.pumpAndSettle();
      // First always open, aligned-with-bias collapsed, others open.
      expect(find.text('First detail'), findsOneWidget);
      expect(find.text('Second detail'), findsNothing);
      expect(find.text('Third detail'), findsOneWidget);
      await t.ensureVisible(find.text('Second'));
      await t.tap(find.text('Second'));
      await t.pumpAndSettle();
      expect(find.text('Second detail'), findsOneWidget);
      await t.tap(find.text('Second'));
      await t.pumpAndSettle();
      expect(find.text('Second detail'), findsNothing);
    });

    testWidgets('data notes are collapsed until tapped', (t) async {
      await narrow(t);
      await t.pumpWidget(host(_full()));
      await t.pumpAndSettle();
      expect(find.text('Data notes'), findsOneWidget);
      expect(find.text('x'), findsNothing);
      await t.ensureVisible(find.text('Data notes'));
      await t.tap(find.text('Data notes'));
      await t.pumpAndSettle();
      expect(find.text('x'), findsOneWidget);
    });

    testWidgets('no overflow at 360dp, large text, new format', (t) async {
      await narrow(t);
      await t.pumpWidget(host(withNew(), textScale: 1.6));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('dark theme smoke', (t) async {
      await narrow(t);
      await t.pumpWidget(host(withNew(), theme: ThemeData.dark()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('conclusion_card')), findsOneWidget);
    });
  });

  group('prepared-ago line', () {
    final now = DateTime.utc(2026, 1, 1, 12);

    Future<void> pump(WidgetTester t, DateTime? at, {Locale? locale}) async {
      await t.pumpWidget(
        MaterialApp(
          locale: locale ?? const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StructuredAnalysisView(
                data: StructuredAnalysis.fromJson(_full()),
                creditCost: 3,
                generatedAt: at,
                now: () => now,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows minutes ago', (t) async {
      await pump(t, now.subtract(const Duration(minutes: 12)));
      expect(find.text('Prepared 12 min ago'), findsOneWidget);
    });

    testWidgets('turkish hours', (t) async {
      await pump(
        t,
        now.subtract(const Duration(hours: 3, minutes: 5)),
        locale: const Locale('tr'),
      );
      expect(find.text('3 sa önce hazırlandı'), findsOneWidget);
    });

    testWidgets('hidden when under a minute old or unknown', (t) async {
      await pump(t, now.subtract(const Duration(seconds: 30)));
      expect(find.byKey(const Key('prepared_ago')), findsNothing);
      await pump(t, null);
      expect(find.byKey(const Key('prepared_ago')), findsNothing);
    });

    testWidgets('days and plural one', (t) async {
      await pump(t, now.subtract(const Duration(days: 2)));
      expect(find.text('Prepared 2 days ago'), findsOneWidget);
      await pump(t, now.subtract(const Duration(minutes: 1)));
      expect(find.text('Prepared 1 min ago'), findsOneWidget);
    });
  });
}
