import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/data/radar_api.dart';
import 'package:kriptoanaliz/models/coin.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/screens/guest_benefits_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/radar_item.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/radar_provider.dart';
import 'package:kriptoanaliz/providers/selected_coin_provider.dart';
import 'package:kriptoanaliz/screens/radar_screen.dart';
import 'package:kriptoanaliz/utils/radar_tiers.dart';
import 'package:kriptoanaliz/widgets/radar/radar_widgets.dart';

import 'helpers/home_fakes.dart';

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

class _FakeSelected extends SelectedCoinNotifier {
  @override
  Future<Coin?> build() async => null;

  @override
  Future<void> select(Coin coin) async {
    state = AsyncData(coin);
  }
}

RadarItem _item(
  int id,
  String symbol,
  int score, {
  String term = 'short',
  String tf = '15m',
  double? change = -3.2,
  String? trend,
  double? volumeRatio,
  String? aiComment,
  Map<String, double>? breakdown,
  bool detected = true,
}) => RadarItem(
  id: id,
  term: term,
  timeframe: tf,
  technicalScore: score,
  rsi: 24.5,
  lastClose: 1,
  detectedAt: detected
      ? DateTime.now().subtract(const Duration(minutes: 5))
      : null,
  trend: trend,
  volumeRatio: volumeRatio,
  aiComment: aiComment,
  scoreBreakdown: breakdown,
  coin: Coin(
    id: id,
    symbol: symbol,
    name: symbol,
    marketType: 'spot',
    lastPrice: 1,
    priceChangePercent24h: change,
    volume24h: 1,
  ),
);

const _proMember = Member(id: 2, email: 'p@b.c', role: 'pro', creditBalance: 1);

/// Terms the screen asked the provider for, per pump.
final _requested = <String?>[];

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<RadarItem> all, {
  Member? member = _proMember,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      adsControllerProvider.overrideWith(_NoAds.new),
      selectedCoinProvider.overrideWith(_FakeSelected.new),
      authProvider.overrideWith(() => FakeAuth(member)),
      radarProvider.overrideWith((ref, term) {
        _requested.add(term);
        return term == null ? all : all.where((i) => i.term == term).toList();
      }),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: locale,
        theme: ThemeData(brightness: brightness, useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const RadarScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return c;
}

void main() {
  test('tier thresholds', () {
    expect(radarStrongMin, 65);
    expect(radarGoodMin, 50);
    expect(radarWatchMin, 38);
    expect(radarTierFor(100), RadarTier.strong);
    expect(radarTierFor(65), RadarTier.strong);
    expect(radarTierFor(64), RadarTier.good);
    expect(radarTierFor(50), RadarTier.good);
    expect(radarTierFor(49), RadarTier.watch);
    expect(radarTierFor(38), RadarTier.watch);
    expect(radarTierFor(37), RadarTier.weak);
    expect(radarTierFor(0), RadarTier.weak);
  });

  test('tier styles differ per tier, strong has a gradient', () {
    for (final b in Brightness.values) {
      final styles = RadarTier.values.map((t) => radarTierStyle(t, b)).toList();
      expect(styles.map((s) => '${s.accent}/${s.accentEnd}').toSet().length, 4);
      expect(radarTierStyle(RadarTier.strong, b).hasGradient, isTrue);
      expect(radarTierStyle(RadarTier.good, b).hasGradient, isFalse);
    }
  });

  testWidgets('hero shows the highest score and opens the chart', (
    tester,
  ) async {
    final c = await _pump(tester, [
      _item(1, 'AAAUSDT', 41),
      _item(2, 'TOPUSDT', 66, term: 'medium', tf: '1h'),
      _item(3, 'BBBUSDT', 52, term: 'long', tf: '4h'),
    ]);
    c.listen(selectedCoinProvider, (_, _) {});
    expect(find.byType(RadarTopPickCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RadarTopPickCard),
        matching: find.text('TOPUSDT'),
      ),
      findsOneWidget,
    );
    expect(find.text('Top pick'.toUpperCase()), findsOneWidget);
    expect(find.text('-3.20%'), findsOneWidget);
    // Hero coin is not repeated in the list.
    expect(find.text('TOPUSDT'), findsOneWidget);
    expect(find.byType(RadarTile), findsNWidgets(2));
    expect(find.text('Strong'), findsOneWidget);

    await tester.tap(find.byType(RadarTopPickCard));
    await tester.pump();
    expect(c.read(selectedCoinProvider).value?.symbol, 'TOPUSDT');
    expect(c.read(homeTabProvider), chartTabIndex);
  });

  testWidgets('term chips show counts and filter', (tester) async {
    await _pump(tester, [
      _item(1, 'AAAUSDT', 41),
      _item(2, 'BBBUSDT', 52, term: 'medium', tf: '1h'),
      _item(3, 'CCCUSDT', 38, term: 'medium', tf: '1h'),
    ]);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('15m'), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('AAAUSDT'), findsNothing);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, []);
    expect(find.byType(RadarEmptyState), findsOneWidget);
    expect(find.text('No oversold coins right now'), findsOneWidget);
    expect(find.byType(RadarTopPickCard), findsNothing);
  });

  testWidgets('info icon opens the explainer sheet', (tester) async {
    await _pump(tester, [_item(1, 'AAAUSDT', 41)]);
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('How radar works'), findsWidgets);
    expect(find.textContaining('not financial advice'), findsOneWidget);
    expect(find.textContaining('65+ Strong'), findsOneWidget);
    expect(find.textContaining('Bollinger stretch'), findsOneWidget);
    expect(find.textContaining('liquidity guard'), findsOneWidget);
  });

  test('allowed terms per access level', () {
    expect(radarAllowedTerms(RadarAccess.guest), ['short']);
    expect(radarAllowedTerms(RadarAccess.free), ['short']);
    expect(radarAllowedTerms(RadarAccess.pro), ['short', 'medium', 'long']);
    expect(radarTermAllowed(RadarAccess.free, null), isFalse);
    expect(radarTermAllowed(RadarAccess.pro, null), isTrue);
  });

  group('RadarItem.fromJson', () {
    Map<String, dynamic> base() => {
      'id': 1,
      'term': 'short',
      'timeframe': '15m',
      'technical_score': 55,
      'rsi': 24.0,
      'last_close': 1.5,
      'detected_at': '2026-01-01T00:00:00Z',
      'coin': {
        'id': 1,
        'symbol': 'AUSDT',
        'name': 'A',
        'market_type': 'spot',
        'last_price': 1,
        'price_change_percent_24h': 1,
        'volume_24h': 1,
      },
    };

    test('old server payload has no extras', () {
      final i = RadarItem.fromJson(base());
      expect(i.trend, isNull);
      expect(i.volumeRatio, isNull);
      expect(i.aiComment, isNull);
      expect(i.scoreBreakdown, isNull);
      expect(i.hasProDetails, isFalse);
    });

    test('new fields are parsed', () {
      final i = RadarItem.fromJson({
        ...base(),
        'trend': 'up',
        'volume_ratio': 2,
        'ai_comment': ' Looks stretched. ',
        'score_breakdown': {
          'oversold': 20,
          'bollinger': 12.5,
          'multiplier': 1.1,
          'future_key': 'x',
        },
      });
      expect(i.trend, 'up');
      expect(i.volumeRatio, 2.0);
      expect(i.aiComment, 'Looks stretched.');
      expect(i.scoreBreakdown, {
        'oversold': 20.0,
        'bollinger': 12.5,
        'multiplier': 1.1,
      });
      expect(i.hasProDetails, isTrue);
    });

    test('garbage values are ignored, not thrown', () {
      final i = RadarItem.fromJson({
        ...base(),
        'trend': 'sideways',
        'volume_ratio': 'high',
        'ai_comment': 5,
        'score_breakdown': [1, 2],
      });
      expect(i.trend, isNull);
      expect(i.volumeRatio, isNull);
      expect(i.aiComment, isNull);
      expect(i.scoreBreakdown, isNull);
      final j = RadarItem.fromJson({
        ...base(),
        'ai_comment': '  ',
        'score_breakdown': {'multiplier': 1.2},
      });
      expect(j.aiComment, isNull);
      expect(j.hasProDetails, isFalse);
    });
  });

  group('radarProvider access rules (no network)', () {
    ProviderContainer make(Member? member, _FakeRadarApi api) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authProvider.overrideWith(() => FakeAuth(member)),
          radarApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('guest and free only request short, never medium/long', () async {
      for (final m in [null, testMember]) {
        final api = _FakeRadarApi();
        final c = make(m, api);
        await c.read(radarProvider(null).future);
        await c.read(radarProvider('short').future);
        expect(await c.read(radarProvider('medium').future), isEmpty);
        expect(await c.read(radarProvider('long').future), isEmpty);
        expect(api.terms.toSet(), {'short'});
        expect(api.tokens.toSet(), {m == null ? null : 'tok'});
      }
    });

    test('pro requests every term with the token', () async {
      final api = _FakeRadarApi();
      final c = make(_proMember, api);
      await c.read(radarProvider(null).future);
      await c.read(radarProvider('medium').future);
      await c.read(radarProvider('long').future);
      expect(api.terms, [null, 'medium', 'long']);
      expect(api.tokens.toSet(), {'tok'});
    });
  });

  testWidgets('guest: locked medium/long, upsell, short only', (tester) async {
    _requested.clear();
    await _pump(tester, [
      _item(1, 'AAAUSDT', 55),
      _item(2, 'BBBUSDT', 45),
    ], member: null);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    expect(find.text('All'), findsNothing);
    expect(find.text('Short'), findsOneWidget);
    expect(find.text('Sign in to see more'), findsOneWidget);
    expect(find.byType(RadarUpsellRow), findsOneWidget);
    // Count badge only on the unlocked chip, none on the locked ones.
    expect(find.text('2'), findsOneWidget);
    // No Pro extras.
    expect(find.byKey(const Key('radar_expand')), findsNothing);
    expect(_requested.toSet(), {'short'});

    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestBenefitsScreen), findsOneWidget);
    expect(_requested.toSet(), {'short'});
  });

  testWidgets('guest upsell row opens guest benefits', (tester) async {
    await _pump(tester, [_item(1, 'AAAUSDT', 55)], member: null);
    await tester.tap(find.byKey(const Key('radar_upsell')));
    await tester.pumpAndSettle();
    expect(find.byType(GuestBenefitsScreen), findsOneWidget);
  });

  testWidgets('free member: locked chips open the subscription screen', (
    tester,
  ) async {
    _requested.clear();
    await _pump(tester, [_item(1, 'AAAUSDT', 55)], member: testMember);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    expect(
      find.text(
        'Pro unlocks all terms, up to 20 opportunities, AI notes and radar alerts',
      ),
      findsOneWidget,
    );
    expect(_requested.toSet(), {'short'});
    await tester.tap(find.text('Long'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(_requested.toSet(), {'short'});
  });

  testWidgets('free member never sees Pro extras even if sent', (tester) async {
    await _pump(tester, [
      _item(
        1,
        'AAAUSDT',
        70,
        aiComment: 'Secret note',
        trend: 'up',
        volumeRatio: 2,
        breakdown: {'oversold': 20},
      ),
      _item(2, 'BBBUSDT', 55, aiComment: 'x', breakdown: {'trend': 5}),
    ], member: testMember);
    expect(find.text('Secret note'), findsNothing);
    expect(find.byKey(const Key('radar_trend_chip')), findsNothing);
    expect(find.byKey(const Key('radar_volume_chip')), findsNothing);
    expect(find.byKey(const Key('radar_expand')), findsNothing);
    expect(find.byKey(const Key('radar_breakdown')), findsNothing);
  });

  testWidgets('pro: no locks, no upsell, all terms requested', (tester) async {
    _requested.clear();
    await _pump(tester, [
      _item(1, 'AAAUSDT', 55),
      _item(2, 'BBBUSDT', 45, term: 'medium', tf: '1h'),
    ]);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byType(RadarUpsellRow), findsNothing);
    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pump();
    expect(_requested, contains('medium'));
  });

  testWidgets('pro: AI note, breakdown and chips on top pick and tile', (
    tester,
  ) async {
    await _pump(tester, [
      _item(
        1,
        'TOPUSDT',
        70,
        trend: 'up',
        volumeRatio: 2.34,
        aiComment: 'Stretched below the band.',
        breakdown: {
          'oversold': 22,
          'bollinger': 15,
          'support': 4,
          'multiplier': 1.1,
          'mystery': 3,
        },
      ),
      _item(2, 'TILEUSDT', 52, trend: 'down', aiComment: 'Tile note here.'),
    ]);
    // Top pick: shown directly.
    expect(find.text('Stretched below the band.'), findsOneWidget);
    expect(find.text('AI note'), findsOneWidget);
    expect(find.textContaining('not financial advice'), findsOneWidget);
    expect(find.byKey(const Key('radar_breakdown')), findsOneWidget);
    expect(find.text('Oversold'), findsOneWidget);
    expect(find.text('Bollinger'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    // Missing / unknown factors are hidden.
    expect(find.text('Trend'), findsNothing);
    expect(find.text('Volume'), findsNothing);
    expect(find.text('Reversal'), findsNothing);
    expect(find.text('Vol x2.3'), findsOneWidget);
    expect(find.text('Uptrend'), findsOneWidget);
    // Tile (scrolled into view): collapsed until the affordance is tapped.
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Downtrend'), findsOneWidget);
    expect(find.text('Tile note here.'), findsNothing);
    await tester.tap(find.byKey(const Key('radar_expand')));
    await tester.pump();
    expect(find.text('Tile note here.'), findsOneWidget);
  });

  testWidgets('detected-time label on hero and tiles, tooltip has exact time', (
    tester,
  ) async {
    await _pump(tester, [_item(1, 'TOPUSDT', 80), _item(2, 'TILEUSDT', 52)]);
    expect(find.text('5 min ago'), findsNWidgets(2));
    expect(find.byIcon(Icons.schedule_rounded), findsNWidgets(2));
    final tips = tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .map((t) => t.message ?? '')
        .where((m) => m.startsWith('Detected '));
    expect(tips.length, 2);
  });

  testWidgets('detected-time label hidden when detectedAt is null', (
    tester,
  ) async {
    await _pump(tester, [
      _item(1, 'TOPUSDT', 80, detected: false),
      _item(2, 'TILEUSDT', 52, detected: false),
    ]);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    expect(find.textContaining('min ago'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detected-time label localizes (tr)', (tester) async {
    await _pump(tester, [_item(1, 'TOPUSDT', 80)], locale: const Locale('tr'));
    expect(find.text('5 dk önce'), findsOneWidget);
  });

  testWidgets('pro: old-server payload (no new fields) renders plainly', (
    tester,
  ) async {
    await _pump(tester, [_item(1, 'AAAUSDT', 70), _item(2, 'BBBUSDT', 50)]);
    expect(find.byKey(const Key('radar_expand')), findsNothing);
    expect(find.byKey(const Key('radar_ai_note')), findsNothing);
    expect(find.byKey(const Key('radar_breakdown')), findsNothing);
    expect(find.byKey(const Key('radar_trend_chip')), findsNothing);
    expect(find.byKey(const Key('radar_volume_chip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pro: tapping a tile body still opens the chart', (tester) async {
    final c = await _pump(tester, [
      _item(1, 'TOPUSDT', 70),
      _item(2, 'TILEUSDT', 52, aiComment: 'n'),
    ]);
    c.listen(selectedCoinProvider, (_, _) {});
    await tester.tap(find.text('TILEUSDT'));
    await tester.pump();
    expect(c.read(selectedCoinProvider).value?.symbol, 'TILEUSDT');
    expect(c.read(homeTabProvider), chartTabIndex);
  });

  for (final locale in ['en', 'tr', 'es']) {
    for (final access in ['guest', 'free', 'pro-rich']) {
      for (final b in Brightness.values) {
        testWidgets('no overflow 360dp x1.6 $access ($locale, ${b.name})', (
          tester,
        ) async {
          final rich = access == 'pro-rich';
          final items = [
            for (var i = 0; i < 4; i++)
              _item(
                i + 1,
                i == 0 ? 'VERYLONGSYMBOLNAMEUSDT' : 'COIN${i}USDT',
                72 - i * 10,
                trend: rich ? (i.isEven ? 'up' : 'down') : null,
                volumeRatio: rich ? 12.34 : null,
                aiComment: rich
                    ? 'A fairly long automated comment that must wrap across several lines without overflowing the card at large text scales.'
                    : null,
                breakdown: rich
                    ? {
                        'oversold': 22,
                        'bollinger': 15,
                        'trend': -4,
                        'volume': 8,
                        'reversal': 6,
                        'support': 5,
                      }
                    : null,
              ),
          ];
          await _pump(
            tester,
            items,
            member: access == 'guest'
                ? null
                : access == 'free'
                ? testMember
                : _proMember,
            locale: Locale(locale),
            brightness: b,
            textScale: 1.6,
          );
          expect(tester.takeException(), isNull);
          if (rich) {
            for (final k in tester.widgetList<IconButton>(
              find.byKey(const Key('radar_expand')),
            )) {
              k.onPressed!();
            }
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
          await tester.drag(find.byType(ListView), const Offset(0, -900));
          await tester.pump();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final locale in ['en', 'tr', 'es']) {
    for (final b in Brightness.values) {
      testWidgets('no overflow at 360dp x1.6 ($locale, ${b.name})', (
        tester,
      ) async {
        final items = [
          _item(1, 'VERYLONGSYMBOLNAMEUSDT', 71, term: 'medium', tf: '1h'),
          _item(2, 'BTCUSDT', 62),
          _item(3, 'ETHUSDT', 50, term: 'long', tf: '4h'),
          _item(4, 'SOLUSDT', 40),
          _item(5, 'XRPUSDT', 31, change: null),
        ];
        await _pump(
          tester,
          items,
          locale: Locale(locale),
          brightness: b,
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty no overflow ($locale, ${b.name})', (tester) async {
        await _pump(
          tester,
          [],
          locale: Locale(locale),
          brightness: b,
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _FakeRadarApi extends RadarApi {
  final terms = <String?>[];
  final tokens = <String?>[];

  @override
  Future<List<RadarItem>> fetch({String? term, String? token}) async {
    terms.add(term);
    tokens.add(token);
    return [];
  }
}
