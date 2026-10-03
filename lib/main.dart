import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/coin_list_screen.dart';
import 'services/push_notification_service.dart';

void main() {
  runApp(const ProviderScope(child: KriptoAnalizApp()));
}

class KriptoAnalizApp extends ConsumerStatefulWidget {
  const KriptoAnalizApp({super.key});

  @override
  ConsumerState<KriptoAnalizApp> createState() => _KriptoAnalizAppState();
}

class _KriptoAnalizAppState extends ConsumerState<KriptoAnalizApp> {
  final _pushService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    _pushService.initialize();
  }

  @override
  void dispose() {
    _pushService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      _pushService.updateAuth(authToken: next.token, role: next.member?.role);
    });

    return MaterialApp(
      title: 'Kripto Analiz',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const CoinListScreen(),
    );
  }
}
