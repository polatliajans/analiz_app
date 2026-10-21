import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/coin_list_provider.dart';
import 'package:kriptoanaliz/providers/home_provider.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/onboarding_provider.dart';
import 'package:kriptoanaliz/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_fakes.dart';

/// A typical gesture-navigation phone window: 400x800 logical px, status bar /
/// cutout of 48 at the top and a 34 gesture area at the bottom.
const insetsWindow = Size(400, 800);
const insetsTop = 48.0;
const insetsBottom = 34.0;
const insetsKeyboard = 300.0;

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

/// Rect of the usable area (not covered by bars) for [window] with [keyboard].
Rect usableArea({
  Size window = insetsWindow,
  double top = insetsTop,
  double bottom = insetsBottom,
  double keyboard = 0,
}) => Rect.fromLTRB(
  0,
  top,
  window.width,
  window.height - math.max(bottom, keyboard),
);

/// Pumps [home] in a window with simulated system insets, the way Android
/// reports them: `viewPadding` is the raw bar size, `padding` shrinks when the
/// keyboard covers the bottom bar, `viewInsets` is the keyboard.
Future<ProviderContainer> pumpWithInsets(
  WidgetTester tester,
  Widget home, {
  Size window = insetsWindow,
  double top = insetsTop,
  double bottom = insetsBottom,
  double keyboard = 0,
  double textScale = 1,
  String locale = 'en',
  Brightness brightness = Brightness.dark,
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authProvider.overrideWith(() => FakeAuth(null)),
      adsControllerProvider.overrideWith(_NoAds.new),
      homeApiProvider.overrideWithValue(
        FakeHomeApi(() => Future.value(homeResponse(emptyHomeJson()))),
      ),
      coinApiProvider.overrideWithValue(
        FakeCoinApi([testCoin(1, 'BTCUSDT'), testCoin(2, 'ETHUSDT')]),
      ),
      onboardingSlidesProvider.overrideWith((ref) async => null),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(brightness),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(
              top: top,
              bottom: math.max(0, bottom - keyboard),
            ),
            viewPadding: EdgeInsets.only(top: top, bottom: bottom),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

/// Asserts that [finder]'s widget lies fully inside [area] (+ tolerance).
void expectInside(
  WidgetTester tester,
  Finder finder,
  Rect area, {
  String? reason,
}) {
  final r = tester.getRect(finder.first);
  expect(
    r.top >= area.top - 0.5 &&
        r.bottom <= area.bottom + 0.5 &&
        r.left >= area.left - 0.5 &&
        r.right <= area.right + 0.5,
    isTrue,
    reason:
        '${reason ?? finder.describeMatch(Plurality.one)} at $r is outside '
        'the usable area $area',
  );
}
