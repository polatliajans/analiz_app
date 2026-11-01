import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/services/analytics_observer.dart';

class _PageA extends StatelessWidget {
  const _PageA();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('a'));
}

class _Unregistered extends StatelessWidget {
  const _Unregistered();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('u'));
}

void main() {
  late List<String> seen;
  late GlobalKey<NavigatorState> nav;

  Future<void> pumpApp(WidgetTester tester) async {
    seen = [];
    nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [
          ScreenViewObserver(
            onScreen: seen.add,
            registry: {_PageA: 'page_a'},
            rootScreen: () => 'root_screen',
          ),
        ],
        home: const Scaffold(body: Text('root')),
      ),
    );
    await tester.pump();
  }

  testWidgets('the initial root route is left to the app', (tester) async {
    await pumpApp(tester);
    expect(seen, isEmpty);
  });

  testWidgets('a pushed registered page reports its name', (tester) async {
    await pumpApp(tester);
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _PageA()),
    );
    await tester.pumpAndSettle();
    expect(seen, ['page_a']);
  });

  testWidgets('popping back reports the root screen again', (tester) async {
    await pumpApp(tester);
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _PageA()),
    );
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(seen, ['page_a', 'root_screen']);
  });

  testWidgets('unregistered pages and dialogs report nothing', (tester) async {
    await pumpApp(tester);
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _Unregistered()),
    );
    await tester.pumpAndSettle();
    showDialog<void>(
      context: nav.currentContext!,
      builder: (_) => const AlertDialog(title: Text('d')),
    );
    await tester.pumpAndSettle();
    nav.currentState!.pop(); // closes the dialog
    await tester.pumpAndSettle();
    expect(seen, isEmpty);
  });
}
