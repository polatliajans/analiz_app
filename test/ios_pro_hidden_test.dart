import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/ad_analysis_provider.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/utils/pro_purchase.dart';
import 'package:kriptoanaliz/widgets/home/home_top_cards.dart';
import 'package:kriptoanaliz/widgets/insufficient_credit_dialog.dart';
import 'package:kriptoanaliz/widgets/pro_upsell_sheet.dart';

import 'helpers/home_fakes.dart';
import 'helpers/home_harness.dart';

const _free = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'user',
  creditBalance: 80,
);
const _plan = SubscriptionPlan(
  id: 1,
  name: 'CryptoAnaliz Pro Monthly',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  monthlyCredit: 300,
);

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

class _Config extends AppConfigNotifier {
  @override
  AppConfig build() => const AppConfig(adAnalysisEnabled: true);
}

Widget _app(Widget home, {required List<Override> overrides}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  final noPro = proPurchaseAvailableProvider.overrideWithValue(false);

  group('proPurchaseAvailableFor', () {
    test('false on iOS only', () {
      expect(proPurchaseAvailableFor(TargetPlatform.iOS), isFalse);
      expect(proPurchaseAvailableFor(TargetPlatform.android), isTrue);
    });

    test('provider follows the simulated platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final c = ProviderContainer();
      try {
        expect(c.read(proPurchaseAvailableProvider), isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        c.dispose();
      }
    });

    test('proUpgradeScreen routes to credit packs when Pro is not sold', () {
      expect(proUpgradeScreen(available: false), isA<CreditPackagesScreen>());
      expect(proUpgradeScreen(available: true), isA<SubscriptionScreen>());
    });
  });

  group('home top cards on iOS (Pro not sold)', () {
    testWidgets('free member: no Pro promo, credit card full width', (
      tester,
    ) async {
      await pumpHome(
        tester,
        member: _free,
        handler: okHome(fullHomeJson()),
        extraOverrides: [noPro],
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      final card = find.byKey(const ValueKey('home-credit-card'));
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, greaterThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('guest: no Pro promo either', (tester) async {
      await pumpHome(
        tester,
        member: null,
        handler: okHome(
          fullHomeJson()
            ..['movers'] = <dynamic>[]
            ..['last_analysis'] = null
            ..['credits'] = null,
        ),
        extraOverrides: [noPro],
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.byKey(const ValueKey('home-credit-card')), findsOneWidget);
    });

    testWidgets('Android keeps the promo card', (tester) async {
      await pumpHome(
        tester,
        member: _free,
        handler: okHome(fullHomeJson()),
        extraOverrides: [
          proPurchaseAvailableProvider.overrideWithValue(true),
          subscriptionPlanListProvider.overrideWith((ref) async => []),
          storePricesProvider.overrideWith((ref, ids) async => {}),
        ],
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsOneWidget);
    });

    testWidgets('HomeTopCards(showPro: false) renders only credits', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HomeTopCards(
              showPro: false,
              credits: 5,
              onPro: () {},
              onCredits: () {},
            ),
          ),
          overrides: const [],
        ),
      );
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.byKey(const ValueKey('home-credit-card')), findsOneWidget);
    });
  });

  group('upsell surfaces on iOS', () {
    testWidgets('showProUpsell shows a neutral note, no sheet, no CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showProUpsell(context, ProFeature.deepAnalysis),
                child: const Text('open'),
              ),
            ),
          ),
          overrides: [noPro],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final l10n = await _en();
      expect(find.text(l10n.featureNotAvailable), findsOneWidget);
      expect(find.text(l10n.upgradeToPro), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('showProUpsell still shows the sheet where Pro is sold', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showProUpsell(context, ProFeature.generic),
              child: const Text('open'),
            ),
          ),
          overrides: [
            proPurchaseAvailableProvider.overrideWithValue(true),
            authProvider.overrideWith(() => FakeAuth(_free)),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = await _en();
      expect(find.text(l10n.upgradeToPro), findsOneWidget);
    });

    testWidgets('ProBadge is hidden on iOS', (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: ProBadge()), overrides: [noPro]),
      );
      expect(find.text('Pro'), findsNothing);
    });

    testWidgets('insufficient-credit dialog: credits only, no Pro wording', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showInsufficientCreditDialog(
                context,
                kind: AnalysisKind.deep,
              ),
              child: const Text('open'),
            ),
          ),
          overrides: [
            noPro,
            authProvider.overrideWith(() => FakeAuth(_free)),
            adsControllerProvider.overrideWith(_NoAds.new),
            appConfigProvider.overrideWith(_Config.new),
            adAnalysisStatusProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goProButton')), findsNothing);
      expect(find.byKey(const Key('buyCreditsButton')), findsOneWidget);
      expect(find.textContaining('Pro'), findsNothing);
    });
  });

  group('SubscriptionScreen on iOS', () {
    List<Override> overrides({required bool pro}) => [
      noPro,
      isProProvider.overrideWithValue(pro),
      subscriptionPlanListProvider.overrideWith((ref) async => [_plan]),
      storePricesProvider.overrideWith(
        (ref, ids) async => {'pro_monthly': 'TRY 349,99'},
      ),
    ];

    for (final pro in [true, false]) {
      testWidgets('pro=$pro: no price, plan button or restore button', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(const SubscriptionScreen(), overrides: overrides(pro: pro)),
        );
        await tester.pumpAndSettle();
        final l10n = await _en();
        if (pro) expect(find.text(l10n.subAlreadyProTitle), findsOneWidget);
        expect(find.text('TRY 349,99'), findsNothing);
        expect(find.text(l10n.subscribe), findsNothing);
        expect(find.byKey(const Key('restore-purchases')), findsNothing);
      });
    }
  });
}
