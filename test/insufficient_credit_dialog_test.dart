import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/data/ad_analysis_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/ad_analysis_provider.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/widgets/insufficient_credit_dialog.dart';

import 'helpers/home_fakes.dart';

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

class _Config extends AppConfigNotifier {
  final AppConfig config;
  _Config(this.config);
  @override
  AppConfig build() => config;
}

Member _member(String role, {bool verified = true}) => Member(
  id: 1,
  email: 'a@b.c',
  role: role,
  creditBalance: 0,
  emailVerified: verified,
);

const _eligible = AdAnalysisStatus(
  enabled: true,
  dailyCap: 5,
  usedToday: 2,
  remainingToday: 3,
  eligible: true,
);

Future<bool?> _open(
  WidgetTester tester, {
  required AnalysisKind kind,
  Member? member,
  bool configEnabled = true,
  AdAnalysisStatus? status = _eligible,
}) async {
  bool? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => FakeAuth(member ?? _member('free'))),
        adsControllerProvider.overrideWith(_NoAds.new),
        appConfigProvider.overrideWith(
          () => _Config(AppConfig(adAnalysisEnabled: configEnabled)),
        ),
        adAnalysisStatusProvider.overrideWith((ref) async => status),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showInsufficientCreditDialog(context, kind: kind),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('adOfferFor', () {
    AdOffer offer({
      AnalysisKind kind = AnalysisKind.quick,
      bool isPro = false,
      bool loggedIn = true,
      bool verified = true,
      bool enabled = true,
      AdAnalysisStatus? status = _eligible,
    }) => adOfferFor(
      kind: kind,
      isPro: isPro,
      isLoggedIn: loggedIn,
      emailVerified: verified,
      configEnabled: enabled,
      status: status,
    );

    test('quick + free + eligible', () => expect(offer(), AdOffer.available));
    test('deep never offers ads', () {
      expect(offer(kind: AnalysisKind.deep), AdOffer.none);
    });
    test('pro never sees ads', () => expect(offer(isPro: true), AdOffer.none));
    test('guest / disabled / unknown status', () {
      expect(offer(loggedIn: false), AdOffer.none);
      expect(offer(enabled: false), AdOffer.none);
      expect(offer(status: null), AdOffer.none);
    });
    test('unverified e-mail shows the reason', () {
      expect(offer(verified: false), AdOffer.emailUnverified);
      expect(
        offer(
          status: const AdAnalysisStatus(reason: 'email_unverified'),
        ),
        AdOffer.emailUnverified,
      );
    });
    test('cap reached', () {
      expect(
        offer(status: const AdAnalysisStatus(reason: 'cap_reached')),
        AdOffer.capReached,
      );
    });
    test('other reasons offer nothing', () {
      for (final r in ['pro', 'has_credit', 'disabled']) {
        expect(offer(status: AdAnalysisStatus(reason: r)), AdOffer.none);
      }
    });
  });

  group('dialog', () {
    testWidgets('quick, free, eligible: ad button, remaining, buy, pro', (
      tester,
    ) async {
      await _open(tester, kind: AnalysisKind.quick);
      expect(find.text('Watch an ad and analyze'), findsOneWidget);
      expect(find.text('Left today: 3'), findsOneWidget);
      expect(find.byKey(const Key('buyCreditsButton')), findsOneWidget);
      expect(find.byKey(const Key('goProButton')), findsOneWidget);
      expect(find.text('Deep analysis always uses credits.'), findsNothing);
    });

    testWidgets('tapping the ad button resolves true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeAuth(_member('free'))),
            adsControllerProvider.overrideWith(_NoAds.new),
            appConfigProvider.overrideWith(
              () => _Config(const AppConfig(adAnalysisEnabled: true)),
            ),
            adAnalysisStatusProvider.overrideWith((ref) async => _eligible),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (c) => TextButton(
                onPressed: () async =>
                    result = await showInsufficientCreditDialog(c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchAdButton')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('deep: no ad button, always-credits line, buy + pro', (
      tester,
    ) async {
      await _open(tester, kind: AnalysisKind.deep);
      expect(find.byKey(const Key('watchAdButton')), findsNothing);
      expect(find.text('Deep analysis always uses credits.'), findsOneWidget);
      expect(find.byKey(const Key('buyCreditsButton')), findsOneWidget);
      expect(find.byKey(const Key('goProButton')), findsOneWidget);
    });

    testWidgets('pro member: no ad, no pro button', (tester) async {
      await _open(tester, kind: AnalysisKind.quick, member: _member('pro'));
      expect(find.byKey(const Key('watchAdButton')), findsNothing);
      expect(find.byKey(const Key('goProButton')), findsNothing);
      expect(find.byKey(const Key('buyCreditsButton')), findsOneWidget);
    });

    testWidgets('server disabled: no ad button', (tester) async {
      await _open(tester, kind: AnalysisKind.quick, configEnabled: false);
      expect(find.byKey(const Key('watchAdButton')), findsNothing);
    });

    testWidgets('cap reached: reason text instead of the button', (
      tester,
    ) async {
      await _open(
        tester,
        kind: AnalysisKind.quick,
        status: const AdAnalysisStatus(enabled: true, reason: 'cap_reached'),
      );
      expect(find.byKey(const Key('watchAdButton')), findsNothing);
      expect(
        find.textContaining("used all of today's ad-funded analyses"),
        findsOneWidget,
      );
    });

    testWidgets('unverified e-mail: reason text instead of the button', (
      tester,
    ) async {
      await _open(
        tester,
        kind: AnalysisKind.quick,
        member: _member('free', verified: false),
      );
      expect(find.byKey(const Key('watchAdButton')), findsNothing);
      expect(find.textContaining('Verify your e-mail'), findsOneWidget);
    });
  });
}
