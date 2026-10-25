import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/ticker_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/auth_prompt_provider.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/guest_market_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/screens/account_screen.dart';
import 'package:kriptoanaliz/screens/auth_screen.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:kriptoanaliz/widgets/home/home_sections.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

class _LogoutAuth extends FakeAuth {
  _LogoutAuth() : super(testMember);

  @override
  Future<void> logout() async => state = const AuthState();
}

FakeHomeApi _oldServer() =>
    FakeHomeApi(() => Future.error(Exception('HTTP 401')));

Map<String, TickerQuote> _quotes() => {
  'BTCUSDT': const TickerQuote(
    lastPrice: 82000,
    changePercent: 1.2,
    quoteVolume: 9e9,
  ),
  'ETHUSDT': const TickerQuote(
    lastPrice: 3000,
    changePercent: 4.5,
    quoteVolume: 5e9,
  ),
  'DOGEUSDT': const TickerQuote(
    lastPrice: 0.2,
    changePercent: -6.1,
    quoteVolume: 7e8,
  ),
  'USDCUSDT': const TickerQuote(
    lastPrice: 1,
    changePercent: 0,
    quoteVolume: 9e9,
  ),
  'TINYUSDT': const TickerQuote(
    lastPrice: 1,
    changePercent: 90,
    quoteVolume: 100,
  ),
  'BTCUPUSDT': const TickerQuote(
    lastPrice: 1,
    changePercent: 50,
    quoteVolume: 9e8,
  ),
};

Future<ProviderContainer> _container({
  required Map<String, Object> prefs,
  required List<Override> extra,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(p), ...extra],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _app(
  ProviderContainer c,
  Widget home, {
  String? locale,
  double scale = 1,
}) {
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: locale == null ? null : Locale(locale),
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
  );
}

void main() {
  test('buildGuestMarket: BTC pulse, filtered and sorted movers', () {
    final data = buildGuestMarket(_quotes())!;
    expect(data.market!.btc!.price, 82000);
    final mm = data.marketMovers!;
    expect(mm.gainers.first.symbol, 'ETHUSDT');
    expect(mm.losers.first.symbol, 'DOGEUSDT');
    final all = [...mm.gainers, ...mm.losers, ...mm.volume];
    expect(all.any((m) => m.symbol == 'USDCUSDT'), isFalse);
    expect(all.any((m) => m.symbol == 'BTCUPUSDT'), isFalse);
    expect(mm.gainers.any((m) => m.symbol == 'TINYUSDT'), isFalse);
    expect(buildGuestMarket(const {}), isNull);
  });

  for (final locale in ['en', 'tr', 'es']) {
    testWidgets('guest home renders cleanly at 360dp / 1.6x ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = await _container(
        prefs: {},
        extra: [
          authProvider.overrideWith(() => FakeAuth(null)),
          homeAutoRefreshProvider.overrideWithValue(null),
          // Old server: the public /home answers 401 -> ticker fallback.
          homeApiProvider.overrideWithValue(_oldServer()),
          guestMarketProvider.overrideWith(
            (ref) async => buildGuestMarket(_quotes()),
          ),
        ],
      );
      await tester.pumpWidget(
        _app(container, const HomeScreen(), locale: locale, scale: 1.6),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      expect(find.text(l10n.homeGuestUnlock), findsOneWidget);
      expect(find.text(l10n.logInOrSignUp), findsOneWidget);
      expect(find.text(l10n.homeMktTitle), findsOneWidget);
      expect(
        find.textContaining('ETH'),
        findsWidgets,
        reason: 'movers visible',
      );
      // Account-only parts are locked placeholders, not real content.
      expect(find.byKey(const ValueKey('quick-deep')), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('guest home offers a retry when the market is unreachable', (
    tester,
  ) async {
    final container = await _container(
      prefs: {},
      extra: [
        authProvider.overrideWith(() => FakeAuth(null)),
        homeAutoRefreshProvider.overrideWithValue(null),
        homeApiProvider.overrideWithValue(_oldServer()),
        guestMarketProvider.overrideWith((ref) async => throw Exception('x')),
      ],
    );
    await tester.pumpWidget(_app(container, const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeErrorCard), findsOneWidget);
    expect(
      find.text('Sign in to unlock analysis, watchlist and alerts'),
      findsOneWidget,
    );
  });

  testWidgets('AuthScreen: guest button only with showGuest, copy matches', (
    tester,
  ) async {
    final container = await _container(
      prefs: {},
      extra: [authProvider.overrideWith(() => FakeAuth(null))],
    );
    await tester.pumpWidget(_app(container, const AuthScreen(showGuest: true)));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.textContaining('browse as a guest'), findsOneWidget);

    await tester.pumpWidget(
      _app(container, const AuthScreen(showGuest: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsNothing);
    expect(find.textContaining('guest'), findsNothing);
  });

  testWidgets('logout resets the prompt flag and shows AuthScreen with the '
      'guest button on a clean stack', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = await _container(
      prefs: {authPromptDoneKey: true},
      extra: [authProvider.overrideWith(_LogoutAuth.new)],
    );
    container.read(homeTabProvider.notifier).select(profileTabIndex);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Mirrors the root switch in main.dart.
          home: Consumer(
            builder: (context, ref, _) => ref.watch(authPromptDoneProvider)
                ? const AccountScreen()
                : const AuthScreen(showGuest: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    final prefs = container.read(sharedPreferencesProvider);
    expect(container.read(authPromptDoneProvider), isFalse);
    expect(prefs.getBool(authPromptDoneKey), isFalse);
    expect(container.read(authProvider).isLoggedIn, isFalse);
    expect(container.read(homeTabProvider), homeTabIndex);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.byType(AccountScreen), findsNothing);
    expect(navKey.currentState!.canPop(), isFalse);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(container.read(authPromptDoneProvider), isTrue);
  });
}
