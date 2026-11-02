import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/app_config_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/utils/pro_purchase.dart';
import 'package:kriptoanaliz/widgets/plan_comparison_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ConfigApi extends AppConfigApi {
  final PlanConfig plan;
  _ConfigApi(this.plan);

  @override
  Future<AppConfig> fetch({String? token}) async => AppConfig(plan: plan);
}

const _proPlan = SubscriptionPlan(
  id: 1,
  name: 'CryptoAnaliz Pro Monthly',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  monthlyCredit: 450,
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  String lang = 'en',
  double width = 360,
  double height = 6000,
  double scale = 1,
  Brightness brightness = Brightness.light,
  PlanConfig plan = const PlanConfig(),
  List<SubscriptionPlan> plans = const [],
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appConfigApiProvider.overrideWithValue(_ConfigApi(plan)),
        subscriptionPlanListProvider.overrideWith((ref) async => plans),
        storePricesProvider.overrideWith(
          (ref, ids) async => {'pro_monthly': 'USD 9.99'},
        ),
        ...extra,
      ],
      child: MaterialApp(
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
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _table() =>
    const Scaffold(body: SingleChildScrollView(child: PlanComparison()));

Finder _row(int i) => find.byKey(ValueKey('plan-row-$i'));

String _cellTexts(WidgetTester tester, int row) => find
    .descendant(of: _row(row), matching: find.byType(Text))
    .evaluate()
    .map((e) => (e.widget as Text).data)
    .join('|');

void main() {
  group('rows (pure, from the plan config)', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    PlanRow find0(List<PlanRow> rows, String label) =>
        rows.firstWhere((r) => r.label == label);

    test('default server rules', () {
      final rows = planComparisonRows(
        l,
        const PlanConfig(),
        freeCredits: 10,
        proCredits: 300,
      );
      final credits = find0(rows, l.planCmpRowCredits);
      expect((credits.free.text, credits.pro.text), ('10', '300'));

      final levels = find0(rows, l.planCmpRowSignalLevels);
      expect((levels.free.text, levels.pro.text), ('1–2', '1–3'));

      final tf = find0(rows, l.planCmpRowTimeframes('1m, 5m'));
      expect((tf.free.included, tf.pro.included), (false, true));

      final deep = find0(rows, l.planCmpRowDeep);
      expect((deep.free.included, deep.pro.included), (false, true));

      final watch = find0(rows, l.planCmpRowWatchlist);
      expect((watch.free.text, watch.pro.text), ('10', l.planCmpUnlimited));

      expect(find0(rows, l.planCmpRowAlerts).free.included, isFalse);
      expect(find0(rows, l.planCmpRowSignalPush).free.included, isFalse);
      expect(find0(rows, l.planCmpRowNoAds).free.included, isFalse);
      expect(find0(rows, l.planCmpRowQuick).free.included, isTrue);
      expect(find0(rows, l.planCmpRowRadar).free.text, l.planCmpLimited);
      expect(rows.every((r) => r.pro.text != null || r.pro.included), isTrue);
    });

    test('follows the server config', () {
      final rows = planComparisonRows(
        l,
        const PlanConfig(
          freeMaxSignalStrength: 3,
          freeWatchlistMax: 25,
          deepAnalysisRequiresPro: false,
          alertsRequirePro: false,
          proOnlyTimeframes: ['1m'],
        ),
        freeCredits: 15,
        proCredits: 500,
      );
      expect(find0(rows, l.planCmpRowSignalLevels).free.text, '1–3');
      expect(find0(rows, l.planCmpRowWatchlist).free.text, '25');
      expect(find0(rows, l.planCmpRowDeep).free.included, isTrue);
      expect(find0(rows, l.planCmpRowAlerts).free.included, isTrue);
      expect(rows.any((r) => r.label == l.planCmpRowTimeframes('1m')), isTrue);
      expect(find0(rows, l.planCmpRowCredits).pro.text, '500');
    });

    test('drops the timeframe row when nothing is Pro-only; level 1 cap', () {
      final rows = planComparisonRows(
        l,
        const PlanConfig(proOnlyTimeframes: [], freeMaxSignalStrength: 1),
        freeCredits: 10,
        proCredits: 300,
      );
      expect(rows.any((r) => r.label.contains('timeframes')), isFalse);
      expect(find0(rows, l.planCmpRowSignalLevels).free.text, '1');
    });

    test('unlimited free watchlist when the server says null', () {
      final rows = planComparisonRows(
        l,
        const PlanConfig(freeWatchlistMax: null),
        freeCredits: 10,
        proCredits: 300,
      );
      expect(find0(rows, l.planCmpRowWatchlist).free.text, l.planCmpUnlimited);
    });
  });

  group('widget', () {
    testWidgets('credits come from the server config and plans', (
      tester,
    ) async {
      await _pump(
        tester,
        _table(),
        plan: const PlanConfig(freeMonthlyCredits: 12),
        plans: [_proPlan],
      );
      expect(_cellTexts(tester, 0), contains('12'));
      expect(_cellTexts(tester, 0), contains('450'));
    });

    testWidgets('falls back to the documented 10 / 300 when unknown', (
      tester,
    ) async {
      await _pump(tester, _table());
      expect(_cellTexts(tester, 0), contains('$fallbackFreeMonthlyCredits'));
      expect(_cellTexts(tester, 0), contains('$fallbackProMonthlyCredits'));
      expect(
        (fallbackFreeMonthlyCredits, fallbackProMonthlyCredits),
        (10, 300),
      );
    });

    for (final lang in ['en', 'tr', 'es']) {
      testWidgets('is fully localized in $lang', (tester) async {
        await _pump(tester, _table(), lang: lang);
        final l = await AppLocalizations.delegate.load(Locale(lang));
        for (final text in [
          l.planCmpTitle,
          l.planCmpFeature,
          l.roleFree,
          l.rolePro,
          l.planCmpRowCredits,
          l.planCmpRowSignalLevels,
          l.planCmpRowTimeframes('1m, 5m'),
          l.planCmpRowQuick,
          l.planCmpRowDeep,
          l.planCmpRowWatchlist,
          l.planCmpRowAlerts,
          l.planCmpRowSignalPush,
          l.planCmpRowRadar,
          l.planCmpRowNoAds,
          l.planCmpFootnote,
          l.planCmpLimited,
          l.planCmpUnlimited,
        ]) {
          expect(find.text(text), findsWidgets, reason: '$lang: $text');
        }
        expect(find.textContaining('{'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      for (final b in [Brightness.light, Brightness.dark]) {
        for (final w in [320.0, 360.0]) {
          testWidgets('no overflow $lang $b ${w}dp x1.6', (tester) async {
            await _pump(
              tester,
              _table(),
              lang: lang,
              brightness: b,
              width: w,
              scale: 1.6,
            );
            expect(find.byKey(const Key('plan-comparison')), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }

      testWidgets('rows are announced as one sentence in $lang', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, _table(), lang: lang);
        final l = await AppLocalizations.delegate.load(Locale(lang));
        expect(
          find.bySemanticsLabel(
            l.planCmpRowSemantics(
              l.planCmpRowAlerts,
              l.planCmpNotIncluded,
              l.planCmpIncluded,
            ),
          ),
          findsOneWidget,
        );
        handle.dispose();
      });
    }

    testWidgets('shows no price', (tester) async {
      await _pump(tester, _table(), plans: [_proPlan]);
      final texts = find
          .descendant(
            of: find.byKey(const Key('plan-comparison')),
            matching: find.byType(Text),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .join(' ');
      expect(texts.contains(r'$'), isFalse);
      expect(texts.contains('9.99'), isFalse);
    });
  });

  group('placement', () {
    List<Override> proOverrides(bool pro, {bool canBuy = true}) => [
      isProProvider.overrideWithValue(pro),
      proPurchaseAvailableProvider.overrideWithValue(canBuy),
    ];

    for (final lang in ['en', 'tr', 'es']) {
      testWidgets('Pro screen shows it above the plans for Free ($lang)', (
        tester,
      ) async {
        await _pump(
          tester,
          const SubscriptionScreen(),
          lang: lang,
          plans: [_proPlan],
          extra: proOverrides(false),
        );
        final l = await AppLocalizations.delegate.load(Locale(lang));
        expect(find.byKey(const Key('plan-comparison')), findsOneWidget);
        final table = tester.getTopLeft(
          find.byKey(const Key('plan-comparison')),
        );
        final plansHeading = tester.getTopLeft(find.text(l.subPlansHeading));
        expect(table.dy, lessThan(plansHeading.dy));
        expect(find.text('450'), findsWidgets);
      });
    }

    testWidgets('Pro screen hides it for Pro members', (tester) async {
      await _pump(
        tester,
        const SubscriptionScreen(),
        plans: [_proPlan],
        extra: proOverrides(true),
      );
      expect(find.byKey(const Key('plan-comparison')), findsNothing);
    });

    testWidgets('Pro screen hides it where Pro cannot be bought', (
      tester,
    ) async {
      await _pump(
        tester,
        const SubscriptionScreen(),
        extra: proOverrides(false, canBuy: false),
      );
      expect(find.byKey(const Key('plan-comparison')), findsNothing);
    });

    for (final w in [320.0, 360.0]) {
      testWidgets('Pro screen for Free: no overflow at ${w}dp x1.6', (
        tester,
      ) async {
        await _pump(
          tester,
          const SubscriptionScreen(),
          plans: [_proPlan],
          width: w,
          scale: 1.6,
          extra: proOverrides(false),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('plan-comparison')), findsOneWidget);
      });
    }
  });
}
