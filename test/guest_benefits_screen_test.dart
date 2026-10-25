import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/app_config_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/app_config.dart';
import 'package:kriptoanaliz/providers/app_config_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/screens/email_auth_screen.dart';
import 'package:kriptoanaliz/screens/guest_benefits_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

class _Api extends AppConfigApi {
  final AppConfig config;
  _Api(this.config);

  @override
  Future<AppConfig> fetch({String? token}) async => config;
}

Future<void> _pump(
  WidgetTester tester, {
  AppConfig config = AppConfig.safeDefaults,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith(() => FakeAuth(null)),
      appConfigApiProvider.overrideWithValue(_Api(config)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          brightness: brightness,
        ),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openGuestBenefits(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'free monthly credits are read from plan or top level, else unknown',
    () {
      expect(
        AppConfig.fromJson({
          'plan': {'role': 'guest', 'free_monthly_credits': 10},
        }).plan.freeMonthlyCredits,
        10,
      );
      expect(
        AppConfig.fromJson({
          'plan': {'role': 'guest'},
          'free_monthly_credits': 15,
        }).plan.freeMonthlyCredits,
        15,
      );
      expect(
        AppConfig.fromJson({
          'plan': {'role': 'guest'},
        }).plan.freeMonthlyCredits,
        isNull,
      );
      final round = PlanConfig.fromJson(
        const PlanConfig(freeMonthlyCredits: 9).toJson(),
      );
      expect(round.freeMonthlyCredits, 9);
    },
  );

  testWidgets('lists what a free account gets, with the amounts from config', (
    tester,
  ) async {
    await _pump(
      tester,
      config: const AppConfig(
        plan: PlanConfig(
          freeMonthlyCredits: 12,
          freeMaxSignalStrength: 2,
          freeWatchlistMax: 7,
          quickAnalysisCost: 3,
        ),
      ),
    );
    // The config arrives asynchronously after the first frame.
    await tester.pumpAndSettle();
    expect(find.text('What you can do after signing in'), findsOneWidget);
    expect(find.text('12 free credits every month'), findsOneWidget);
    expect(find.text('A quick analysis costs 3 credits.'), findsOneWidget);
    expect(find.text('Chart signals up to level 2'), findsOneWidget);
    expect(
      find.text(
        'Follow up to 7 coins and keep an eye on them from the home page.',
      ),
      findsOneWidget,
    );
    expect(find.text('Analysis history'), findsOneWidget);
    // Pro-only today: not promised to free members.
    expect(find.text('Deep analysis'), findsNothing);
    expect(find.text('Price alerts and notifications'), findsNothing);
    // One short Pro tease and the two sign-in buttons.
    await tester.scrollUntilVisible(
      find.byKey(const Key('guest-pro-tease')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('guest-pro-tease')), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets('no free credit number is invented when the server omits it', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Free credits every month'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ free credits')), findsNothing);
  });

  testWidgets('deep analysis / alerts appear only when the plan allows', (
    tester,
  ) async {
    await _pump(
      tester,
      config: const AppConfig(
        plan: PlanConfig(
          deepAnalysisRequiresPro: false,
          alertsRequirePro: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deep analysis'), findsOneWidget);
    expect(find.text('Price alerts and notifications'), findsOneWidget);
  });

  testWidgets('unlimited watchlist copy when there is no limit', (
    tester,
  ) async {
    await _pump(
      tester,
      config: const AppConfig(plan: PlanConfig(freeWatchlistMax: null)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Follow your coins and keep an eye on them from the home page.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('email button opens the existing e-mail sign-in flow', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('guest-email')));
    await tester.pumpAndSettle();
    expect(find.byType(EmailAuthScreen), findsOneWidget);
  });

  for (final locale in ['en', 'tr', 'es']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('no overflow at 360dp / 1.6x ($locale, $brightness)', (
        tester,
      ) async {
        await _pump(
          tester,
          locale: locale,
          brightness: brightness,
          scale: 1.6,
          config: const AppConfig(
            plan: PlanConfig(
              freeMonthlyCredits: 10,
              deepAnalysisRequiresPro: false,
              alertsRequirePro: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l10n = await AppLocalizations.delegate.load(Locale(locale));
        expect(find.text(l10n.continueWithGoogle), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('guest-pro-tease')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('guest-pro-tease')), findsOneWidget);
      });
    }
  }
}
