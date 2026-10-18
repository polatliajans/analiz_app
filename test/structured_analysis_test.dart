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
}
