import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'providers/auth_prompt_provider.dart';
import 'providers/credit_purchase_provider.dart';
import 'providers/home_tab_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/language_selection_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/push_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'utils/platform_info.dart';
import 'services/analytics_events.dart';
import 'services/analytics_observer.dart';
import 'services/analytics_screens.dart';
import 'services/analytics_service.dart';
import 'services/crash_reporter.dart';
import 'services/firebase_analytics_backend.dart';
import 'services/firebase_crash_backend.dart';
import 'services/notification_logic.dart';
import 'services/notification_navigation.dart';
import 'services/push_notification_service.dart';
import 'widgets/notification_permission_dialog.dart';

/// Debug builds send no analytics unless started with
/// `--dart-define=ANALYTICS_DEBUG=true` (needed to see events in DebugView).
const _analyticsInDebug = bool.fromEnvironment('ANALYTICS_DEBUG');

Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stack) {
    CrashReporter.instance.recordFatal(error, stack);
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars on every Android version (Android 15 enforces
  // it); screens add their own insets.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  try {
    await Firebase.initializeApp();
    // Crash reporting: off in debug, wrapped so it can never break startup.
    final reporter = SafeCrashReporter(FirebaseCrashBackend());
    await reporter.init(enabled: !kDebugMode);
    CrashReporter.instance = reporter;
    installCrashHandlers(reporter);
    unawaited(_setVersionContext(reporter));
  } catch (_) {
    // Firebase is not configured yet; the app still starts (auth/push disabled).
  }
  final analytics = await _createAnalytics();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: const KriptoAnalizApp(),
    ),
  );
}

/// The real analytics service starts denied (nothing is collected until the
/// consent flow grants it); a no-op when Firebase is missing or in debug.
Future<AnalyticsService> _createAnalytics() async {
  if (kDebugMode && !_analyticsInDebug) return const NoopAnalyticsService();
  try {
    if (Firebase.apps.isEmpty) return const NoopAnalyticsService();
    final service = SafeAnalyticsService(FirebaseAnalyticsBackend());
    await service.init();
    return service;
  } catch (_) {
    return const NoopAnalyticsService();
  }
}

Future<void> _setVersionContext(CrashReporter reporter) async {
  try {
    final info = await PackageInfo.fromPlatform();
    reporter.setContext(appVersion: '${info.version}+${info.buildNumber}');
  } catch (_) {}
}

const _screenNames = ['home', 'chart', 'radar', 'watchlist', 'profile'];

String _planOf(AuthState auth) {
  final member = auth.member;
  if (member == null) return 'guest';
  return member.role == 'pro' ? 'pro' : 'free';
}

class KriptoAnalizApp extends ConsumerStatefulWidget {
  const KriptoAnalizApp({super.key});

  @override
  ConsumerState<KriptoAnalizApp> createState() => _KriptoAnalizAppState();
}

class _KriptoAnalizAppState extends ConsumerState<KriptoAnalizApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final PushNotificationService _pushService;
  late final AnalyticsService _analytics;
  late final ScreenViewObserver _screenObserver;
  String? _stage;
  bool _promptChecked = false;
  bool _promptRunning = false;
  bool _applyScheduled = false;

  @override
  void initState() {
    super.initState();
    _pushService = ref.read(pushServiceProvider);
    _analytics = ref.read(analyticsProvider);
    _screenObserver = ScreenViewObserver(
      onScreen: _analytics.logScreenView,
      registry: analyticsScreenRegistry,
      rootScreen: _rootScreenName,
    );
    _analytics.setUserProperty(
      AnalyticsUserProps.platform,
      isIOS ? 'ios' : 'android',
    );
    // Build the locale first so channel names use the active language.
    final initialLocale = ref.read(localeProvider).locale;
    _analytics.setUserProperty(
      AnalyticsUserProps.language,
      initialLocale.languageCode,
    );
    // Start listening to the store right at launch so unfinished purchases
    // are delivered and credited even if the credit screen is never opened.
    ref.read(creditPurchaseControllerProvider);
    _pushService.initialize();
  }

  String? _rootScreenName() => _stage == 'home'
      ? AnalyticsScreens.tab(ref.read(homeTabProvider))
      : _stage;

  /// The root route's content (language, onboarding, auth, tabs) changes in
  /// place, so its screen views are reported when the stage changes.
  void _trackStage(String? stage) {
    if (stage == null || stage == _stage) return;
    _stage = stage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = _rootScreenName();
      if (mounted && name != null) _analytics.logScreenView(name);
    });
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
      CrashReporter.instance.setContext(loggedIn: next.isLoggedIn);
      // Numeric member id only (never email or name); cleared on sign-out.
      final memberId = next.member?.id;
      if (previous == null ||
          previous.member?.id != memberId ||
          _planOf(previous) != _planOf(next)) {
        _analytics.setUserId(memberId == null ? null : '$memberId');
        _analytics.setUserProperty(AnalyticsUserProps.plan, _planOf(next));
      }
      _pushService.updateAuth(authToken: next.isLoggedIn ? next.token : null);
    });
    ref.listen(localeProvider, (previous, next) {
      if (previous?.locale != next.locale) _pushService.refreshChannels();
      CrashReporter.instance.setContext(locale: next.locale.languageCode);
      _analytics.setUserProperty(
        AnalyticsUserProps.language,
        next.locale.languageCode,
      );
    });
    ref.listen(homeTabProvider, (previous, next) {
      if (next >= 0 && next < _screenNames.length) {
        CrashReporter.instance.setContext(screen: _screenNames[next]);
      }
      if (_stage == 'home') {
        _analytics.logScreenView(AnalyticsScreens.tab(next));
      }
    });

    final localeState = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboardingDone = ref.watch(onboardingDoneProvider);
    final authPromptDone = ref.watch(authPromptDoneProvider);
    final auth = ref.watch(authProvider);
    ref.watch(pendingNotificationTargetProvider);

    final homeShowing =
        localeState.hasChosen &&
        onboardingDone &&
        (authPromptDone || (!auth.isRestoring && auth.isLoggedIn));
    _afterFrame(homeShowing && !auth.isRestoring, auth);
    _trackStage(
      !localeState.hasChosen
          ? AnalyticsScreens.language
          : !onboardingDone
          ? AnalyticsScreens.onboarding
          : !authPromptDone
          ? (auth.isRestoring
                ? null
                : auth.isLoggedIn
                ? 'home'
                : AnalyticsScreens.auth)
          : 'home',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      navigatorObservers: [_screenObserver],
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      builder: appThemeBuilder,
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
