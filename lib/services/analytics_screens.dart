import '../screens/alarms_screen.dart';
import '../screens/analysis_history_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/credit_packages_screen.dart';
import '../screens/email_auth_screen.dart';
import '../screens/glossary_screen.dart';
import '../screens/guest_benefits_screen.dart';
import '../screens/guide_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';

/// Pushed (full-page) screens and the `screen_view` name each one reports.
/// Keyed by widget type, so release obfuscation cannot change the names and no
/// push site needs to know about analytics.
final Map<Type, String> analyticsScreenRegistry = {
  SubscriptionScreen: 'subscription',
  CreditPackagesScreen: 'credit_packages',
  AuthScreen: 'auth',
  EmailAuthScreen: 'email_auth',
  GlossaryScreen: 'glossary',
  GuideScreen: 'guide',
  GuestBenefitsScreen: 'guest_benefits',
  AlarmsScreen: 'alarms',
  OnboardingScreen: 'onboarding',
  SettingsScreen: 'settings',
  AnalysisHistoryScreen: 'analysis_history',
};
