import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final lang in ['en', 'tr', 'es']) {
    for (final b in [Brightness.light, Brightness.dark]) {
      testWidgets('settings no overflow 360dp x1.6 $lang $b', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData(
                colorSchemeSeed: Colors.deepPurple,
                brightness: b,
              ),
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!,
              ),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.language));
        await tester.pumpAndSettle();
        expect(find.byType(RadioListTile<Locale>), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
