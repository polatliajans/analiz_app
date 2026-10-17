import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'providers/auth_prompt_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/push_provider.dart';
import 'services/notification_logic.dart';
import 'services/notification_navigation.dart';
import 'services/push_notification_service.dart';
import 'widgets/notification_permission_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is not configured yet; the app still starts (auth/push disabled).
  }
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final PushNotificationService _pushService;
  bool _promptChecked = false;
  bool _promptRunning = false;
  bool _applyScheduled = false;

  @override
  void initState() {
    super.initState();
    _pushService = ref.read(pushServiceProvider);
    // Build the locale first so channel names use the active language.
    ref.read(localeProvider);
    _pushService.initialize();
  }

  /// Applies a pending notification tap and, once per account, offers the
  /// notification permission, as soon as the home shell is showing.
  void _afterFrame(bool ready, AuthState auth) {
    if (_applyScheduled) return;
    _applyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;
      if (!mounted || !ready) return;
      final pending = ref.read(pendingNotificationTargetProvider);
      if (pending != null) {
        ref.read(pendingNotificationTargetProvider.notifier).set(null);
        final navigator = _navigatorKey.currentState;
        // Login-only screens are dropped for guests (nothing to show them).
        if (navigator != null && (auth.isLoggedIn || !pending.requiresLogin)) {
          applyNotificationTarget(ref, navigator, pending);
        }
      }
      if (!auth.isLoggedIn) {
        _promptChecked = false;
      } else if (!_promptChecked && !_promptRunning) {
        _maybeAskPermission();
      }
    });
  }

  Future<void> _maybeAskPermission() async {
    _promptRunning = true;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final enabled = await _pushService.notificationsEnabled();
      _promptChecked = true;
      final show = decideNotificationPermissionPrompt(
        loggedIn: true,
        alreadyAsked: prefs.getBool(notificationPromptShownKey) ?? false,
        permissionGranted: enabled,
      );
      final context = _navigatorKey.currentState?.overlay?.context;
      if (!show || context == null || !mounted) return;
      await prefs.setBool(notificationPromptShownKey, true);
      if (!context.mounted) return;
      if (await showNotificationRationale(context)) {
        await _pushService.requestPermission();
        ref.invalidate(notificationPermissionProvider);
      }
    } finally {
      _promptRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      _pushService.updateAuth(authToken: next.isLoggedIn ? next.token : null);
    });
    ref.listen(localeProvider, (previous, next) {
      if (previous?.locale != next.locale) _pushService.refreshChannels();
    });

    final localeState = ref.watch(localeProvider);
    final onboardingDone = ref.watch(onboardingDoneProvider);
    final authPromptDone = ref.watch(authPromptDoneProvider);
    final auth = ref.watch(authProvider);
    ref.watch(pendingNotificationTargetProvider);

    final homeShowing =
        localeState.hasChosen &&
        onboardingDone &&
        (authPromptDone || (!auth.isRestoring && auth.isLoggedIn));
    _afterFrame(homeShowing && !auth.isRestoring, auth);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      locale: localeState.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: !localeState.hasChosen
          ? const LanguageSelectionScreen()
          : !onboardingDone
          ? const OnboardingScreen()
          : !authPromptDone
          ? (auth.isRestoring
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : auth.isLoggedIn
                ? const HomeShell()
                : const AuthScreen(showGuest: true))
          : const HomeShell(),
    );
  }
}
