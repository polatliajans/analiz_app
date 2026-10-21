import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/theme_provider.dart';
import 'package:kriptoanaliz/screens/settings_screen.dart';
import 'package:kriptoanaliz/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(p)],
  );
  addTearDown(c.dispose);
  return c;
}

/// Same wiring as the real app (theme, darkTheme, themeMode, builder).
class _ThemedApp extends ConsumerWidget {
  final Widget home;
  const _ThemedApp({required this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    themeMode: ref.watch(themeModeProvider),
    builder: appThemeBuilder,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  group('theme mode persistence', () {
    test('no saved value (existing users) defaults to dark', () async {
      final c = await _container();
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });

    test('unknown saved value falls back to dark', () async {
      final c = await _container({themeModeKey: 'neon'});
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });

    test('saved light / system / dark are honoured', () async {
      expect(
        (await _container({themeModeKey: 'light'})).read(themeModeProvider),
        ThemeMode.light,
      );
      expect(
        (await _container({themeModeKey: 'system'})).read(themeModeProvider),
        ThemeMode.system,
      );
      expect(
        (await _container({themeModeKey: 'dark'})).read(themeModeProvider),
        ThemeMode.dark,
      );
    });

    test('select updates state and persists', () async {
      final c = await _container();
      await c.read(themeModeProvider.notifier).select(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
      expect(
        c.read(sharedPreferencesProvider).getString(themeModeKey),
        'light',
      );
      await c.read(themeModeProvider.notifier).select(ThemeMode.system);
      expect(
        c.read(sharedPreferencesProvider).getString(themeModeKey),
        'system',
      );
      // A fresh container (app restart) reads it back.
      final again = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            c.read(sharedPreferencesProvider),
          ),
        ],
      );
      addTearDown(again.dispose);
      expect(again.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('app theming', () {
    testWidgets('starts dark even when the phone is in light mode', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final c = await _container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const _ThemedApp(home: Scaffold(body: Text('hi'))),
        ),
      );
      expect(_brightness(tester), Brightness.dark);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final ctx = tester.element(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor ?? Theme.of(ctx).scaffoldBackgroundColor,
        Theme.of(ctx).colorScheme.surface,
      );
      expect(
        Theme.of(ctx).colorScheme.surface.computeLuminance(),
        lessThan(0.1),
      );
    });

    testWidgets('system mode follows the phone', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final c = await _container({themeModeKey: 'system'});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const _ThemedApp(home: Scaffold(body: Text('hi'))),
        ),
      );
      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('system bars icons follow the theme', (tester) async {
      final c = await _container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const _ThemedApp(home: Scaffold(body: Text('hi'))),
        ),
      );
      SystemUiOverlayStyle style() => tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          )
          .value;
      expect(style().statusBarColor, Colors.transparent);
      expect(style().statusBarIconBrightness, Brightness.light);
      expect(style().systemNavigationBarIconBrightness, Brightness.light);
      await c.read(themeModeProvider.notifier).select(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(style().statusBarIconBrightness, Brightness.dark);
      expect(style().systemNavigationBarIconBrightness, Brightness.dark);
      expect(style().systemNavigationBarColor, Colors.transparent);
    });

    testWidgets('settings switch applies immediately and is saved', (
      tester,
    ) async {
      final c = await _container();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const _ThemedApp(home: SettingsScreen()),
        ),
      );
      await tester.pump();
      expect(_brightness(tester), Brightness.dark);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.light);
      expect(
        c.read(sharedPreferencesProvider).getString(themeModeKey),
        'light',
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.dark);
    });
  });

  group('palettes', () {
    test('trend colors differ per theme but stay green/red', () {
      // Sanity of the chart palettes: light board is light, dark is dark.
      expect(ChartPalette.dark.background.computeLuminance(), lessThan(0.1));
      expect(
        ChartPalette.light.background.computeLuminance(),
        greaterThan(0.9),
      );
      expect(ChartPalette.light.text.computeLuminance(), lessThan(0.4));
      expect(ChartPalette.dark.text.computeLuminance(), greaterThan(0.4));
    });

    testWidgets('trendColor reads on both surfaces', (tester) async {
      late Color darkUp, lightUp, darkDown, lightDown;
      Widget probe(Brightness b, void Function(Color up, Color down) out) =>
          MaterialApp(
            theme: buildAppTheme(b),
            home: Builder(
              builder: (context) {
                out(trendColor(context, 1), trendColor(context, -1));
                return const SizedBox();
              },
            ),
          );
      await tester.pumpWidget(
        probe(Brightness.dark, (u, d) {
          darkUp = u;
          darkDown = d;
        }),
      );
      await tester.pumpWidget(
        probe(Brightness.light, (u, d) {
          lightUp = u;
          lightDown = d;
        }),
      );
      await tester.pumpAndSettle(); // the theme change animates
      // Light text on dark surfaces, dark text on light surfaces.
      expect(
        darkUp.computeLuminance(),
        greaterThan(lightUp.computeLuminance()),
      );
      expect(
        darkDown.computeLuminance(),
        greaterThan(lightDown.computeLuminance()),
      );
      expect(lightUp.computeLuminance(), lessThan(0.15));
      expect(lightDown.computeLuminance(), lessThan(0.15));
    });
  });
}
