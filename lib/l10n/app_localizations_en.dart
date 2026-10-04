// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crypto Analysis';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameTr => 'Türkçe';

  @override
  String get languageNameEs => 'Español';

  @override
  String get retry => 'Try again';

  @override
  String errorOccurred(String details) {
    return 'An error occurred: $details';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logIn => 'Log in';

  @override
  String get signUp => 'Sign up';

  @override
  String get logOut => 'Log out';

  @override
  String get myAccount => 'My Account';

  @override
  String get myWatchlist => 'My Watchlist';

  @override
  String get mustLogIn => 'You need to log in';

  @override
  String get buy => 'Buy';

  @override
  String accountEmail(String email) {
    return 'Email: $email';
  }

  @override
  String accountRole(String role) {
    return 'Role: $role';
  }

  @override
  String get roleFree => 'Free';

  @override
  String get rolePro => 'Pro';

  @override
  String accountCreditBalance(int count) {
    return 'Credit balance: $count';
  }

  @override
  String get buyCredits => 'Buy Credits';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get logInOrSignUp => 'Log in / Sign up';

  @override
  String get coins => 'Coins';

  @override
  String get radar => 'Radar';

  @override
  String get searchSymbol => 'Search symbol...';

  @override
  String get noCoinsFound => 'No coins found';

  @override
  String volumeLabel(String value) {
    return 'Volume: $value';
  }

  @override
  String get noCandleData => 'No candle data';

  @override
  String creditsSpent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits spent',
      one: '1 credit spent',
    );
    return '$_temp0';
  }

  @override
  String analysisFailed(String details) {
    return 'Analysis failed: $details';
  }

  @override
  String deepAnalysisFailed(String details) {
    return 'Deep analysis failed: $details';
  }

  @override
  String get quickAnalysisButton => 'Quick Analysis';

  @override
  String get deepAnalysisButton => 'Deep Analysis';

  @override
  String creditsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits',
      one: '1 credit',
    );
    return '$_temp0';
  }

  @override
  String get proSubscription => 'Pro Subscription';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String monthlyCredits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits every month',
      one: '1 credit every month',
    );
    return '$_temp0';
  }

  @override
  String purchaseFailed(String details) {
    return 'Purchase failed: $details';
  }

  @override
  String get purchaseNoPackage =>
      'Purchase could not be verified because the package information was not found. It will be retried the next time you open the app.';

  @override
  String get purchaseNoPlan =>
      'Purchase could not be verified because the subscription plan information was not found. It will be retried the next time you open the app.';

  @override
  String get creditsAdded => 'Credits have been added to your balance.';

  @override
  String get proActivated => 'Your Pro subscription has been activated.';

  @override
  String purchaseWillRetry(String details) {
    return '$details The purchase will be retried.';
  }

  @override
  String get purchaseServiceUnavailable =>
      'The purchase service is unavailable.';

  @override
  String get productNotFound => 'Product not found in the store.';

  @override
  String purchaseStartFailed(String details) {
    return 'Could not start the purchase: $details';
  }

  @override
  String get termAll => 'All';

  @override
  String get termShort => 'Short';

  @override
  String get termMedium => 'Medium';

  @override
  String get termLong => 'Long';

  @override
  String get termShortLabel => 'Short term';

  @override
  String get termMediumLabel => 'Medium term';

  @override
  String get termLongLabel => 'Long term';

  @override
  String get agoNow => 'just now';

  @override
  String agoMinutes(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get radarEmpty =>
      'No opportunities meet the technical criteria right now.';

  @override
  String get radarFooter =>
      'Score 0-100: shows how oversold it is. Tap an opportunity for an AI-powered deep analysis.';

  @override
  String get watchlistEmpty => 'You are not following any coins yet';

  @override
  String errorServer(int status) {
    return 'Server error: $status';
  }

  @override
  String get errorInsufficientCredit => 'Insufficient credit.';

  @override
  String get errorAnalysisUnavailable => 'Analysis is currently unavailable.';

  @override
  String get errorDeepAnalysisUnavailable =>
      'Deep analysis is currently unavailable.';

  @override
  String errorAnalysisRequestFailed(String details) {
    return 'Could not send the analysis request: $details';
  }

  @override
  String errorDeepAnalysisRequestFailed(String details) {
    return 'Could not send the deep analysis request: $details';
  }

  @override
  String get errorSessionInvalid => 'Could not verify your session.';

  @override
  String errorRequestFailed(String details) {
    return 'Could not send the request: $details';
  }

  @override
  String get errorInvalidCredentialsOrEmailTaken =>
      'Invalid details, or this email is already registered.';

  @override
  String errorSignalsFailed(String details) {
    return 'Could not load signal data: $details';
  }

  @override
  String errorServerUnreachable(String details) {
    return 'Could not connect to the server: $details';
  }

  @override
  String errorCreditPackagesFailed(String details) {
    return 'Could not load credit packages: $details';
  }

  @override
  String errorDeviceTokenFailed(String details) {
    return 'Could not register the device token: $details';
  }

  @override
  String get errorProOnly => 'This feature is for Pro members only.';

  @override
  String errorPurchaseVerifyFailed(String details) {
    return 'The purchase could not be verified: $details';
  }

  @override
  String get errorPurchaseInvalid => 'The purchase is not valid.';

  @override
  String get errorPlayVerificationUnreachable =>
      'Could not reach the Google Play verification service.';

  @override
  String errorRadarFailed(String details) {
    return 'Could not load Radar: $details';
  }

  @override
  String errorPlansFailed(String details) {
    return 'Could not load subscription plans: $details';
  }

  @override
  String errorSubscriptionVerifyFailed(String details) {
    return 'The subscription could not be verified: $details';
  }

  @override
  String get errorSubscriptionInvalid => 'The subscription is not valid.';

  @override
  String get errorWatchlistFailed => 'Could not load your watchlist.';

  @override
  String get errorFollowFailed => 'Could not follow this coin.';

  @override
  String get errorUnfollowFailed => 'Could not remove it from your watchlist.';

  @override
  String errorCandlesFailed(String details) {
    return 'Could not load candle data: $details';
  }

  @override
  String errorBinance(int status) {
    return 'Binance error: $status';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get replayIntro => 'Replay intro';

  @override
  String get onboardingDefault1Title => 'Radar: the best setups';

  @override
  String get onboardingDefault1Body =>
      'Radar scans the market and surfaces the coins with the strongest technical opportunities, so you do not have to hunt for them.';

  @override
  String get onboardingDefault2Title => 'Charts with signals';

  @override
  String get onboardingDefault2Body =>
      'Read the price action at a glance. Buy and sell arrows on the chart mark the signals as they appear.';

  @override
  String get onboardingDefault3Title => 'AI analysis and alerts';

  @override
  String get onboardingDefault3Body =>
      'Run a quick or deep AI analysis using credits, and add coins to My Watchlist to get notified when something happens.';

  @override
  String get authErrorInvalidEmail => 'That email address is not valid.';

  @override
  String get authErrorWrongCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailInUse =>
      'An account with this email already exists.';

  @override
  String get authErrorWeakPassword =>
      'The password is too weak. Use at least 8 characters.';

  @override
  String get authErrorNetwork =>
      'Network error. Check your connection and try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get authErrorCancelled => 'Sign-in was cancelled.';

  @override
  String get authErrorEmailUnverifiedConflict =>
      'An account with this email already exists. Verify your email first.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get authWelcomeTitle => 'Welcome';

  @override
  String get authWelcomeSubtitle =>
      'Log in to run AI analyses, follow coins and get notified. You can also browse as a guest.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetEmailSent => 'Password reset email sent. Check your inbox.';

  @override
  String get verificationEmailSent =>
      'Verification email sent. Check your inbox.';

  @override
  String get verifyEmailBannerText =>
      'Verify your email to receive your welcome credit.';

  @override
  String get iHaveVerified => 'I verified';

  @override
  String get resendEmail => 'Resend';

  @override
  String get emailNotVerifiedYet => 'Your email is not verified yet.';

  @override
  String get accountEmailVerified => 'Email verified';

  @override
  String get accountEmailNotVerified => 'Email not verified';
}
