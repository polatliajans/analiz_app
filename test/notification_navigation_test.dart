import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/providers/home_tab_provider.dart';
import 'package:kriptoanaliz/services/notification_logic.dart';
import 'package:kriptoanaliz/services/notification_navigation.dart';

void main() {
  Future<ProviderContainer> run(
    WidgetTester tester,
    Map<String, dynamic> data,
  ) async {
    final navKey = GlobalKey<NavigatorState>();
    late WidgetRef ref;
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          navigatorKey: navKey,
          home: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    c.read(homeTabProvider.notifier).select(homeTabIndex);
    await applyNotificationTarget(
      ref,
      navKey.currentState!,
      resolveNotificationTarget(data),
    );
    return c;
  }

  testWidgets('screen:radar opens the Radar tab', (tester) async {
    final c = await run(tester, {'screen': 'radar'});
    expect(c.read(homeTabProvider), radarTabIndex);
  });

  testWidgets('unknown screen is ignored safely', (tester) async {
    final c = await run(tester, {'screen': 'does_not_exist'});
    expect(c.read(homeTabProvider), homeTabIndex);
  });
}
