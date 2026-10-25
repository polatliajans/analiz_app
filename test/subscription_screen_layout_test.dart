import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/price_alert_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';

const _plan = SubscriptionPlan(
  id: 1,
  name: 'CryptoAnaliz Pro Monthly',
  price: '9.99',
  durationDays: 30,
  storeProductIdAndroid: 'pro_monthly',
  monthlyCredit: 300,
);

void main() {
  for (final lang in ['en', 'tr', 'es']) {
    for (final b in [Brightness.light, Brightness.dark]) {
      for (final pro in [false, true]) {
        testWidgets('subscription no overflow 360dp x1.6 $lang $b pro=$pro', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                subscriptionPlanListProvider.overrideWith(
                  (ref) async => [_plan],
                ),
                storePricesProvider.overrideWith(
                  (ref, ids) async => {'pro_monthly': 'TRY 349,99'},
                ),
                isProProvider.overrideWithValue(pro),
              ],
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
                home: const SubscriptionScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('CryptoAnaliz Pro'), findsOneWidget);
          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (!pro) expect(find.text('TRY 349,99'), findsOneWidget);
        });
      }
    }
  }
}
