import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/home_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/guest_market_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_fakes.dart';

class HomeHarness {
  final ProviderContainer container;
  final FakeHomeApi api;
  HomeHarness(this.container, this.api);
}

Future<HomeResponse> Function() okHome(Map<String, dynamic> json) =>
    () => Future.value(homeResponse(json));

Map<String, Object> cachedHomePrefs(Map<String, dynamic> json) => {
  homeCacheBodyKey: jsonEncode(json),
  homeCacheAtKey: homeTestNow
      .subtract(const Duration(minutes: 3))
      .millisecondsSinceEpoch,
  homeCacheUserKey: 1,
};

/// Pumps [HomeScreen] with fakes, a simulated window size and optional
/// system insets ([padding] doubles as viewPadding, [viewInsets] is the
/// keyboard).
Future<HomeHarness> pumpHome(
  WidgetTester tester, {
  required Future<HomeResponse> Function() handler,
  Map<String, Object> prefs = const {},
  Member? member = testMember,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(360, 3600),
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final api = FakeHomeApi(handler);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      authProvider.overrideWith(() => FakeAuth(member)),
      homeApiProvider.overrideWithValue(api),
      guestMarketProvider.overrideWith((ref) async => null),
      homeClockProvider.overrideWithValue(() => homeTestNow),
      coinApiProvider.overrideWithValue(
        FakeCoinApi([testCoin(1, 'BTCUSDT'), testCoin(7, 'ETHUSDT')]),
      ),
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: padding,
            viewPadding: padding,
            viewInsets: viewInsets,
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return HomeHarness(container, api);
}
