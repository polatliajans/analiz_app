import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/coin_list_screen.dart';
import 'screens/language_selection_screen.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KriptoAnalizApp(),
    ),
  );
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

    final localeState = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      locale: localeState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: localeState.hasChosen
          ? const CoinListScreen()
          : const LanguageSelectionScreen(),
    );
  }
}
