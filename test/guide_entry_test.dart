import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/screens/guide_screen.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:kriptoanaliz/services/analytics_screens.dart';
import 'package:kriptoanaliz/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/analytics_fakes.dart';
import 'helpers/home_fakes.dart';
import 'helpers/home_harness.dart';

const _free = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'user',
  creditBalance: 80,
);
const _pro = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'pro',
  creditBalance: 80,
);

Map<String, dynamic> _guestJson() => fullHomeJson()
  ..['movers'] = <dynamic>[]
  ..['last_analysis'] = null
  ..['credits'] = null;

void main() {
  const cardKey = ValueKey('home-guide-card');

  final cases = <String, Member?>{'guest': null, 'free': _free, 'pro': _pro};
  for (final entry in cases.entries) {
    testWidgets('${entry.key}: guide card sits between radar and analysis', (
      tester,
    ) async {
      final rec = RecordingAnalyticsService();
      await pumpHome(
        tester,
        member: entry.value,
        handler: okHome(entry.value == null ? _guestJson() : fullHomeJson()),
        extraOverrides: [analyticsProvider.overrideWithValue(rec)],
      );
      expect(find.byKey(cardKey), findsOneWidget);
      double y(Finder f) => tester.getTopLeft(f).dy;
      final radar = y(find.text('Latest signals from Radar'));
      final guide = y(find.byKey(cardKey));
      final analysis = y(find.text('Your latest deep analysis'));
      expect(radar < guide, isTrue);
      expect(guide < analysis, isTrue);
      expect(find.text('How to read the signals'), findsOneWidget);

      await tester.tap(find.byKey(cardKey));
      await tester.pumpAndSettle();
      expect(find.byType(GuideScreen), findsOneWidget);
      final taps = rec.events.where((e) => e.name == 'guide_card_tapped');
      expect(taps.single.params, {'source': 'home'});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('guide card still shows when the home request fails', (
    tester,
  ) async {
    await pumpHome(
      tester,
      member: null,
      handler: () => Future.error(Exception('boom')),
    );
    expect(find.byKey(cardKey), findsOneWidget);
  });

  testWidgets('guide card fits at 320dp and 1.6 text scale', (tester) async {
    await pumpHome(
      tester,
      handler: okHome(fullHomeJson()),
      size: const Size(320, 4800),
      textScale: 1.6,
    );
    expect(find.byKey(cardKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings has a How it works entry that opens the guide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final rec = RecordingAnalyticsService();
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          analyticsProvider.overrideWithValue(rec),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    final tile = find.widgetWithText(ListTile, 'How it works');
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(GuideScreen), findsOneWidget);
    expect(rec.events.single.params, {'source': 'settings'});
  });

  test('guide screen is registered for screen_view', () {
    expect(analyticsScreenRegistry[GuideScreen], 'guide');
  });
}
