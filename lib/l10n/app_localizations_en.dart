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
  String get cancel => 'Cancel';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmBody =>
      'This permanently deletes your account and all your data: watchlist, analysis history, credits, notifications and linked sign-in methods. This cannot be undone.';

  @override
  String get deleteAccountProNote =>
      'If you have an active Pro subscription, deleting your account does not cancel it. Please cancel it separately in Google Play, otherwise you may keep being charged.';

  @override
  String get deleteAccountConfirmAction => 'Delete';

  @override
  String deleteAccountCreditsLost(int credits) {
    return '$credits credits will be deleted and will not be refunded.';
  }

  @override
  String get deleteAccountManageSubscription =>
      'Manage subscription in Google Play';

  @override
  String get deleteAccountAckCheckbox =>
      'I understand that my credits will be deleted and will not be refunded';

  @override
  String get deleteAccountOpenFailed => 'Could not open Google Play.';

  @override
  String get errorPurchaseAlreadyProcessed =>
      'This purchase was already processed and cannot be redeemed again.';

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
  String get strongSignalsProNote => 'Strong (3) signals are Pro';

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
  String get deepAnalysisWaitingTitle => 'Deep analysis is running';

  @override
  String get deepAnalysisWaitingBody =>
      'This usually takes 30-90 seconds, sometimes up to 4 minutes. You can leave this screen - we\'ll send you a notification when it\'s ready.';

  @override
  String get deepAnalysisFailedRefunded =>
      'The deep analysis could not be completed. Your credits have been refunded.';

  @override
  String get deepAnalysisAlreadyRunning =>
      'You already have a deep analysis running. Please wait for it to finish.';

  @override
  String get deepAnalysisCheckLater =>
      'We couldn\'t reach the server. Your analysis may still be running - check back later or look at your analysis history.';

  @override
  String get deepAnalysisStillRunning =>
      'Your analysis is still running. You\'ll get a notification when it\'s ready, or you can find it in your analysis history.';

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

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get guestProfileHint =>
      'Log in or sign up to track your watchlist, buy credits and sync your account.';

  @override
  String get tabChart => 'Chart';

  @override
  String get tabWatchlist => 'Watchlist';

  @override
  String get tabProfile => 'Profile';

  @override
  String get analysisInProgress => 'Analysis in progress';

  @override
  String get analysisMayTakeTime => 'This may take 20-30 seconds';

  @override
  String get analysisHistoryTitle => 'My Analyses';

  @override
  String get analysisHistorySection => 'Past analyses';

  @override
  String get analysisHistoryEmpty => 'No analyses yet';

  @override
  String get analysisHistoryLoginHint => 'Log in to see your past analyses';

  @override
  String get analysisTypeQuick => 'Quick';

  @override
  String get analysisTypeDeep => 'Deep';

  @override
  String get favoritesTab => 'Favorites';

  @override
  String get favoritesLoginHint => 'Log in to see your favorite coins';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get alertTooltip => 'Price alert';

  @override
  String get myAlerts => 'My alerts';

  @override
  String get alertsTabActive => 'Active';

  @override
  String get alertsTabHistory => 'History';

  @override
  String get alertSetTitle => 'Set price alert';

  @override
  String alertCurrentPrice(String price) {
    return 'Current price: $price';
  }

  @override
  String get alertWaitingPrice => 'Waiting for the current price...';

  @override
  String get alertTargetPriceLabel => 'Target price';

  @override
  String alertWillTriggerAbove(String price) {
    return 'You will get a notification when the price rises to $price or higher.';
  }

  @override
  String alertWillTriggerBelow(String price) {
    return 'You will get a notification when the price falls to $price or lower.';
  }

  @override
  String get alertEnterDifferentPrice =>
      'Enter a target price different from the current price.';

  @override
  String get alertSetButton => 'Set alert';

  @override
  String alertSetSuccess(String symbol) {
    return 'Alert set for $symbol';
  }

  @override
  String get alertActiveForCoin => 'Active alerts for this coin';

  @override
  String alertLimitInfo(int count, int max) {
    return '$count of $max active alerts used';
  }

  @override
  String get alertCancelTooltip => 'Cancel alert';

  @override
  String get alertCanceled => 'Alert canceled';

  @override
  String get alertRearm => 'Set again';

  @override
  String get alertRearmed => 'Alert set again';

  @override
  String alertDirectionAbove(String price) {
    return 'Above $price';
  }

  @override
  String alertDirectionBelow(String price) {
    return 'Below $price';
  }

  @override
  String get alertStatusTriggered => 'Triggered';

  @override
  String get alertStatusCanceled => 'Canceled';

  @override
  String alertTriggeredAt(String date, String price) {
    return '$date at $price';
  }

  @override
  String get alertsEmptyActive =>
      'No active alerts. Open a coin chart and tap the bell to set one.';

  @override
  String get alertsEmptyHistory => 'No triggered or canceled alerts yet.';

  @override
  String get alertProTitle => 'Price alerts are a Pro feature';

  @override
  String get alertProBody =>
      'Pro members get a push notification the moment a coin reaches their target price.';

  @override
  String get alertErrorProRequired =>
      'Price alerts are available for Pro members only.';

  @override
  String alertErrorLimitReached(int limit) {
    return 'You can have at most $limit active alerts. Cancel one to add another.';
  }

  @override
  String get alertErrorDuplicate =>
      'You already have an active alert for this price.';

  @override
  String get alertErrorGeneric =>
      'Something went wrong with the alert. Please try again.';

  @override
  String get legalAboutSection => 'Legal & About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get deleteAccountPage => 'Delete account';

  @override
  String get support => 'Support';

  @override
  String get financialDisclaimer => 'Financial disclaimer';

  @override
  String get financialDisclaimerText =>
      'CryptoAnaliz does not provide investment advice. Signals and analyses are for informational purposes only and carry no guarantee. Crypto asset investments carry high risk; you are responsible for your decisions and any resulting losses.';

  @override
  String get appVersion => 'App version';

  @override
  String get close => 'Close';

  @override
  String get couldNotOpenLink => 'Could not open the link.';

  @override
  String get proUpsellBenefitsHeading => 'With Pro you get';

  @override
  String get proBenefitNoAds => 'No ads';

  @override
  String get proBenefitDeepAnalysis => 'Deep analysis';

  @override
  String get proBenefitCredits => '300 credits every month';

  @override
  String get proBenefitAlerts => 'Push notifications and price alerts';

  @override
  String get proBenefitTimeframes =>
      '1m and 5m timeframes and strong (3) level signals';

  @override
  String get proBenefitWatchlist => 'Unlimited watchlist';

  @override
  String get proUpsellNotNow => 'Not now';

  @override
  String get proUpsellDeepTitle => 'Deep analysis is a Pro feature';

  @override
  String get proUpsellDeepBody =>
      'Pro members get a more detailed, multi-timeframe deep analysis of any coin.';

  @override
  String get proUpsellTimeframeTitle => '1m and 5m are Pro timeframes';

  @override
  String get proUpsellTimeframeBody =>
      'Pro members can watch the fastest timeframes and run AI analysis on them.';

  @override
  String get proUpsellStrongSignalsTitle =>
      'Strong (3) level signals are a Pro feature';

  @override
  String get proUpsellStrongSignalsBody =>
      'Pro members see all signal levels on the chart, including the strongest (3).';

  @override
  String proUpsellWatchlistTitle(int count, int limit) {
    return 'Your watchlist is full ($count/$limit)';
  }

  @override
  String get proUpsellWatchlistBody =>
      'Upgrade to Pro for an unlimited watchlist.';

  @override
  String get proUpsellGenericTitle => 'This is a Pro feature';

  @override
  String get proUpsellGenericBody => 'Upgrade to Pro to unlock it.';

  @override
  String get proBadgeTooltip => 'Pro feature';

  @override
  String get adLabel => 'Ad';

  @override
  String rewardedWatchButton(int amount, int remaining) {
    return 'Watch an ad, +$amount credits (left today: $remaining)';
  }

  @override
  String get rewardedEarnedPending =>
      'Thanks! Your credits will arrive in a few seconds.';

  @override
  String get rewardedAdUnavailable =>
      'No ad is available right now. Please try again a bit later.';

  @override
  String get rewardedNotCompleted =>
      'The ad was closed early, so no credits were added.';

  @override
  String get insufficientCreditTitle => 'Not enough credits';

  @override
  String get insufficientCreditBody =>
      'You don\'t have enough credits for this analysis. You can buy credits to continue.';

  @override
  String get insufficientCreditBodyWithAd =>
      'You don\'t have enough credits for this analysis. Buy credits, or watch a short ad to earn free credits.';

  @override
  String get notifChannelAnnouncementsName => 'Announcements';

  @override
  String get notifChannelAnnouncementsDesc =>
      'News and announcements from the app';

  @override
  String get notifChannelCreditsName => 'Credits';

  @override
  String get notifChannelCreditsDesc =>
      'Notifications when credits are added to your account';

  @override
  String get notifChannelSignalsName => 'Watchlist signals';

  @override
  String get notifChannelSignalsDesc =>
      'Trading signals for the coins you follow';

  @override
  String get notifChannelAlertsName => 'Price alerts';

  @override
  String get notifChannelAlertsDesc =>
      'Notifications when a coin reaches your target price';

  @override
  String get notifRationaleTitle => 'Turn on notifications?';

  @override
  String get notifRationaleBody =>
      'Get credit and announcement notifications. Pro members also get watchlist signal and price alert notifications.';

  @override
  String get notifRationaleAllow => 'Allow';

  @override
  String get notifRationaleLater => 'Not now';

  @override
  String get notifSettingsSection => 'Notifications';

  @override
  String get notifAnnouncementsTitle => 'Announcements';

  @override
  String get notifAnnouncementsSubtitle => 'News and updates from the app';

  @override
  String get notifCreditsTitle => 'Credit notifications';

  @override
  String get notifCreditsSubtitle => 'When credits are added to your account';

  @override
  String get notifSignalsTitle => 'Watchlist signals';

  @override
  String get notifSignalsSubtitle => 'New signals for the coins you follow';

  @override
  String get notifAlertsTitle => 'Price alerts';

  @override
  String get notifAlertsSubtitle => 'When a coin reaches your target price';

  @override
  String get notifPermissionOffTitle => 'Notification permission is off';

  @override
  String get notifPermissionOffBody =>
      'You won\'t receive notifications until you allow them.';

  @override
  String get notifOpenSystemSettings => 'Open system settings';

  @override
  String get notifPermissionManual =>
      'Turn notifications on from your phone\'s settings.';

  @override
  String get notifSettingsLoadFailed => 'Couldn\'t load notification settings.';

  @override
  String get notifSettingsSaveFailed =>
      'Couldn\'t save the change. Please try again.';

  @override
  String get proUpsellPushSignalsTitle =>
      'Signal notifications are a Pro feature';

  @override
  String get proUpsellPushSignalsBody =>
      'Pro members get a push notification when a coin on their watchlist gets a new signal.';

  @override
  String get structuredBiasBullish => 'Bullish';

  @override
  String get structuredBiasBearish => 'Bearish';

  @override
  String get structuredBiasNeutral => 'Neutral';

  @override
  String structuredConfidence(int value) {
    return 'Confidence $value%';
  }

  @override
  String structuredHorizon(String label) {
    return 'Horizon: $label';
  }

  @override
  String structuredHorizonCandles(int count) {
    return '$count candles';
  }

  @override
  String get structuredSectionSummary => 'Summary';

  @override
  String get structuredSectionDrivers => 'Key drivers';

  @override
  String get structuredSectionScenarios => 'Scenarios';

  @override
  String get structuredSectionLevels => 'Key levels';

  @override
  String get structuredSectionRisks => 'Risks';

  @override
  String get structuredSectionWatch => 'What to watch';

  @override
  String get structuredSectionSources => 'Sources';

  @override
  String get structuredScenarioBull => 'Bull case';

  @override
  String get structuredScenarioBase => 'Base case';

  @override
  String get structuredScenarioBear => 'Bear case';

  @override
  String structuredScenarioTrigger(String price) {
    return 'Trigger: $price';
  }

  @override
  String structuredScenarioTarget(String price) {
    return 'Target: $price';
  }

  @override
  String get structuredLevelResistance => 'Resistance';

  @override
  String get structuredLevelSupport => 'Support';

  @override
  String get structuredLevelInvalidation => 'Invalidation';

  @override
  String get structuredLevelPrice => 'Price at analysis';

  @override
  String structuredDataMissing(String sources) {
    return 'Some data sources were unavailable: $sources';
  }

  @override
  String get structuredDisclaimer => 'Not investment advice.';

  @override
  String get structuredSourceOpenFailed => 'Couldn\'t open the link.';

  @override
  String get glossaryTitle => 'Glossary of technical terms';

  @override
  String get glossarySearchHint => 'Search terms (e.g. RSI, funding)';

  @override
  String get glossaryNoResults => 'No matching terms.';

  @override
  String get glossaryLearnTerms => 'Learn the terms';

  @override
  String get glossaryIntro =>
      'Short, neutral explanations of the terms used in analyses. For information only, not investment advice.';

  @override
  String get structuredConclusionTitle => 'Final take';

  @override
  String get structuredSectionBalance => 'Driver balance';

  @override
  String get structuredSectionLadder => 'Price ladder';

  @override
  String get structuredSectionDataNotes => 'Data notes';

  @override
  String get structuredSectionOdds => 'Scenario odds';

  @override
  String structuredBalanceItem(String label, int count) {
    return '$label $count';
  }

  @override
  String analysisPreparedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prepared $count min ago',
      one: 'Prepared 1 min ago',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prepared $count hr ago',
      one: 'Prepared 1 hr ago',
    );
    return '$_temp0';
  }

  @override
  String analysisPreparedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prepared $count days ago',
      one: 'Prepared 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get analysisPreparedJustNow => 'Just prepared';
}
