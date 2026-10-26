import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/privacy_options.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePrivacy implements PrivacyOptions {
  final bool required;
  int shown = 0;
  _FakePrivacy(this.required);

  @override
  Future<bool> isRequired() async => required;

  @override
  Future<void> show() async => shown++;
}

Future<void> _pump(
  WidgetTester tester,
  _FakePrivacy fake, {
  bool pro = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        privacyOptionsProvider.overrideWithValue(fake),
        isProProvider.overrideWithValue(pro),
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
  await tester.pump();
}

void main() {
  testWidgets('shown when required and opens the privacy form', (tester) async {
    final fake = _FakePrivacy(true);
    await _pump(tester, fake);
    expect(find.text('Ad privacy options'), findsOneWidget);
    await tester.tap(find.text('Ad privacy options'));
    await tester.pump();
    expect(fake.shown, 1);
  });

  testWidgets('hidden when not required', (tester) async {
    await _pump(tester, _FakePrivacy(false));
    expect(find.text('Ad privacy options'), findsNothing);
  });

  testWidgets('hidden for Pro even when required', (tester) async {
    await _pump(tester, _FakePrivacy(true), pro: true);
    expect(find.text('Ad privacy options'), findsNothing);
  });
}
