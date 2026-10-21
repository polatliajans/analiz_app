import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/startup_tab_provider.dart';
import 'package:kriptoanaliz/screens/chart_screen.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:kriptoanaliz/screens/home_shell.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/home_fakes.dart';

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    retry: (_, _) => null, // no retry timers from failing network providers
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      authProvider.overrideWith(() => FakeAuth(null)),
      adsControllerProvider.overrideWith(_NoAds.new),
      homeApiProvider.overrideWithValue(
        FakeHomeApi(() => Future.value(homeResponse(emptyHomeJson()))),
      ),
      coinApiProvider.overrideWithValue(FakeCoinApi([testCoin(1, 'BTCUSDT')])),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _pumpShell(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  test('tab index constants: Home, Chart, Radar, Watchlist, Profile', () {
    expect(homeTabIndex, 0);
    expect(chartTabIndex, 1);
    expect(radarTabIndex, 2);
    expect(watchlistTabIndex, 3);
    expect(profileTabIndex, 4);
  });

  testWidgets('shell has five tabs in order and Home is first', (tester) async {
    final c = await _container({});
    await _pumpShell(tester, c);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 5);
    expect(
      bar.destinations.map((d) => (d as NavigationDestination).label).toList(),
      ['Home', 'Chart', 'Radar', 'Watchlist', 'Profile'],
    );
    expect(bar.selectedIndex, homeTabIndex);

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.index, homeTabIndex);
    expect(stack.children[0], isA<HomeScreen>());
    expect(stack.children[1], isA<ChartScreen>());
  });

  testWidgets('existing users without a saved setting open on Home', (
    tester,
  ) async {
    final c = await _container({});
    expect(c.read(startupTabProvider), StartupTab.home);
    expect(c.read(homeTabProvider), homeTabIndex);
  });

  testWidgets('saved "chart" start page opens the Chart tab', (tester) async {
    final c = await _container({startupTabKey: 'chart'});
    await _pumpShell(tester, c);
    expect(c.read(homeTabProvider), chartTabIndex);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, chartTabIndex);
  });

  testWidgets('unknown saved value falls back to Home', (tester) async {
    final c = await _container({startupTabKey: 'something-else'});
    expect(c.read(homeTabProvider), homeTabIndex);
  });

  testWidgets('settings screen persists the start page', (tester) async {
    final c = await _container({});
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Start page'), findsOneWidget);

    // "Chart" radio under "Start page" (second of the two radio rows).
    await tester.tap(find.widgetWithText(RadioListTile<StartupTab>, 'Chart'));
    await tester.pump();
    expect(c.read(startupTabProvider), StartupTab.chart);
    expect(c.read(sharedPreferencesProvider).getString(startupTabKey), 'chart');

    await tester.tap(find.widgetWithText(RadioListTile<StartupTab>, 'Home'));
    await tester.pump();
    expect(c.read(startupTabProvider), StartupTab.home);
  });
}
