import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/config/legal_links.dart';
import 'package:kriptoanaliz/config/terms.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/providers/locale_provider.dart';
import 'package:kriptoanaliz/providers/terms_acceptance_provider.dart';
import 'package:kriptoanaliz/screens/terms_acceptance_screen.dart';
import 'package:kriptoanaliz/services/analytics_events.dart';
import 'package:kriptoanaliz/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/analytics_fakes.dart';
import 'helpers/terms_helpers.dart';

const _childKey = Key('app-child');

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  String version = '2026-11-02',
  String lang = 'en',
  double width = 360,
  double height = 800,
  double scale = 1,
  Brightness brightness = Brightness.light,
  AnalyticsService? analytics,
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      termsVersionProvider.overrideWithValue(version),
      termsClockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 2, 9)),
      if (analytics != null) analyticsProvider.overrideWithValue(analytics),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          brightness: brightness,
        ),
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const TermsGate(child: SizedBox(key: _childKey)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('the shipped terms version is a date stamp', () {
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(termsVersion), isTrue);
  });

  group('gate', () {
    testWidgets('shows when nothing was accepted yet', (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('terms-gate')), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets('hides when the current version was accepted', (tester) async {
      await _pump(tester, stored: {termsAcceptedVersionKey: '2026-11-02'});
      expect(find.byKey(const Key('terms-gate')), findsNothing);
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets('re-shows when the terms version changed', (tester) async {
      await _pump(
        tester,
        stored: {termsAcceptedVersionKey: '2026-01-01'},
        version: '2026-11-02',
      );
      expect(find.byKey(const Key('terms-gate')), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets('the test override skips the gate', (tester) async {
      await _pump(tester, extra: [termsAcceptedOverride]);
      expect(find.byKey(_childKey), findsOneWidget);
    });
  });

  group('screen', () {
    testWidgets('Continue stays disabled until the box is ticked', (
      tester,
    ) async {
      await _pump(tester, height: 3000);
      FilledButton button() =>
          tester.widget<FilledButton>(find.byKey(const Key('terms-continue')));
      expect(button().onPressed, isNull);

      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pump();
      expect(button().onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pump();
      expect(button().onPressed, isNull);
    });

    testWidgets('accepting stores version and time, logs event, opens app', (
      tester,
    ) async {
      final backend = FakeAnalyticsBackend();
      final analytics = SafeAnalyticsService(backend);
      await analytics.applyConsent(allowed: true);
      final container = await _pump(tester, height: 3000, analytics: analytics);

      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('terms-continue')));
      await tester.pumpAndSettle();

      expect(find.byKey(_childKey), findsOneWidget);
      expect(container.read(termsAcceptedProvider), isTrue);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString(termsAcceptedVersionKey), '2026-11-02');
      expect(prefs.getString(termsAcceptedAtKey), '2026-11-02T09:00:00.000Z');
      final events = backend.events.where(
        (e) => e.name == AnalyticsEvents.termsAccepted,
      );
      expect(events, hasLength(1));
      expect(events.single.params, {'version': '2026-11-02'});
    });

    testWidgets('has links to the Terms and the Privacy Policy', (
      tester,
    ) async {
      await _pump(tester, height: 3000);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byKey(const Key('legal-terms')), findsOneWidget);
      expect(find.byKey(const Key('legal-privacy')), findsOneWidget);
      expect(find.text(l10n.termsOfUse), findsOneWidget);
      expect(find.text(l10n.privacyPolicy), findsOneWidget);
      // The links come from the shared legal config.
      expect(
        LegalLinks.page(LegalLinks.termsPath, 'en').toString(),
        endsWith('/terms?lang=en'),
      );
    });

    for (final lang in ['en', 'tr', 'es']) {
      testWidgets('shows the full copy in $lang', (tester) async {
        await _pump(tester, lang: lang, height: 3000);
        final l10n = await AppLocalizations.delegate.load(Locale(lang));
        for (final text in [
          l10n.termsGateTitle,
          l10n.termsGateIntro,
          l10n.termsGateBullet1,
          l10n.termsGateBullet2,
          l10n.termsGateBullet3,
          l10n.termsGateBullet4,
          l10n.termsGateBullet5,
          l10n.termsGateBullet6,
          l10n.termsGateLinksLabel,
          l10n.termsGateCheckbox,
          l10n.continueButton,
          l10n.termsGateContinueHint,
          l10n.termsOfUse,
          l10n.privacyPolicy,
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(tester.takeException(), isNull);
      });

      for (final b in [Brightness.light, Brightness.dark]) {
        testWidgets('no overflow $lang $b at 320dp, 1.6x text', (tester) async {
          await _pump(
            tester,
            lang: lang,
            width: 320,
            height: 568,
            scale: 1.6,
            brightness: b,
          );
          expect(tester.takeException(), isNull);
          // Everything is reachable by scrolling down to the button.
          await tester.scrollUntilVisible(
            find.byKey(const Key('terms-continue')),
            200,
            scrollable: find.descendant(
              of: find.byKey(const Key('terms-gate')),
              matching: find.byType(Scrollable),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('back button', () {
    final popped = <MethodCall>[];

    setUp(() {
      popped.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') popped.add(call);
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('closes the app on Android and never skips the gate', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await _pump(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(popped, hasLength(1));
      expect(find.byKey(const Key('terms-gate')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('does nothing on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await _pump(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(popped, isEmpty);
      expect(find.byKey(const Key('terms-gate')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
