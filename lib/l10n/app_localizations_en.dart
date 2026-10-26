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
  String get strongSignalsProNote =>
      'Pro adds the strongest (level 3) signals, 1m/5m and alerts';

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
  String get agoYesterday => 'yesterday';

  @override
  String radarDetectedAt(String dateTime) {
    return 'Detected $dateTime';
  }

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
  String get radarTopPick => 'Top pick';

  @override
  String get radarTierStrong => 'Strong';

  @override
  String get radarTierGood => 'Good';

  @override
  String get radarTierWatch => 'Watch';

  @override
  String get radarTierWeak => 'Low';

  @override
  String get radarEmptyTitle => 'No oversold coins right now';

  @override
  String get radarInfoTooltip => 'How radar works';

  @override
  String get radarHowTitle => 'How radar works';

  @override
  String get radarHowOversold =>
      'Radar lists coins that look oversold: RSI is below the oversold threshold and the price has dropped under the lower Bollinger band. It can hint that a fall is stretched.';

  @override
  String radarHowScore(
    int strong,
    int good,
    int goodMax,
    int watch,
    int watchMax,
  ) {
    return 'The score (0-100) rates how strong the oversold setup is: $strong+ Strong, $good-$goodMax Good, $watch-$watchMax Watch, below $watch Low.';
  }

  @override
  String get radarHowFactors =>
      'The score combines oversold depth, Bollinger stretch, higher-timeframe trend, volume, reversal evidence and support proximity, with a liquidity guard that caps thin markets.';

  @override
  String radarTermLocked(String term) {
    return '$term is locked';
  }

  @override
  String get radarUpsellGuest => 'Sign in to see more';

  @override
  String get radarUpsellFree =>
      'Pro unlocks all terms, up to 20 opportunities, AI notes and radar alerts';

  @override
  String get radarAiNote => 'AI note';

  @override
  String get radarAiNoteHint => 'Automated commentary, not financial advice.';

  @override
  String get radarFactorsTitle => 'Score factors';

  @override
  String get radarFactorOversold => 'Oversold';

  @override
  String get radarFactorBollinger => 'Bollinger';

  @override
  String get radarFactorTrend => 'Trend';

  @override
  String get radarFactorVolume => 'Volume';

  @override
  String get radarFactorReversal => 'Reversal';

  @override
  String get radarFactorSupport => 'Support';

  @override
  String get radarTrendUp => 'Uptrend';

  @override
  String get radarTrendDown => 'Downtrend';

  @override
  String radarVolumeRatio(String v) {
    return 'Vol x$v';
  }

  @override
  String get radarDetailsTooltip => 'Show details';

  @override
  String get radarHideDetailsTooltip => 'Hide details';

  @override
  String get radarHowTerms =>
      'Short, medium and long term use different chart timeframes. Pick the one that fits your horizon.';

  @override
  String get radarHowDisclaimer =>
      'Radar is a technical screening tool, not financial advice. An oversold coin can keep falling, so always do your own research.';

  @override
  String radarRsi(String v) {
    return 'RSI $v';
  }

  @override
  String radarScoreSemantics(int score, String tier) {
    return 'Score $score of 100, $tier';
  }

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
  String get authWelcomeSubtitleNoGuest =>
      'Log in to run AI analyses, follow coins and get notified.';

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
  String get crashReportingTitle => 'Crash reporting';

  @override
  String get crashReportingNote =>
      'Anonymous crash reports (app version, language, screen, signed-in yes/no) help us fix bugs. No personal or financial data is included.';

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
  String get insufficientCreditTitle => 'Not enough credits';

  @override
  String get insufficientCreditBody =>
      'You don\'t have enough credits for this analysis. You can buy credits to continue.';

  @override
  String get insufficientCreditBodyWithAd =>
      'You don\'t have enough credits for this analysis. Watch a short ad to run this one quick analysis, buy credits, or go Pro.';

  @override
  String get insufficientCreditDeepBody =>
      'You don\'t have enough credits for a deep analysis. You can buy credits or go Pro.';

  @override
  String get adAnalysisDeepAlwaysCredits =>
      'Deep analysis always uses credits.';

  @override
  String get adAnalysisWatchButton => 'Watch an ad and analyze';

  @override
  String adAnalysisRemainingToday(int remaining) {
    return 'Left today: $remaining';
  }

  @override
  String get adAnalysisCapReached =>
      'You\'ve used all of today\'s ad-funded analyses: buy credits or go Pro.';

  @override
  String get adAnalysisEmailUnverified =>
      'Verify your e-mail address to run an analysis by watching an ad.';

  @override
  String get adAnalysisAdUnavailable =>
      'The ad couldn\'t be loaded right now. Please try again in a moment.';

  @override
  String get adAnalysisVerifyTimeout =>
      'We couldn\'t confirm the ad yet. Please try again in a few seconds.';

  @override
  String get adAnalysisSessionExpired =>
      'This ad session has expired. Please try again.';

  @override
  String get adAnalysisNotFree =>
      'Ad-funded analysis is only available to free members.';

  @override
  String get adAnalysisDisabled =>
      'Ad-funded analysis isn\'t available right now.';

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

  @override
  String get tabHome => 'Home';

  @override
  String homeStaleNote(String ago) {
    return 'Not up to date · updated $ago';
  }

  @override
  String get homeStaleNoTime => 'Not up to date';

  @override
  String get homeGuestUnlock =>
      'Sign in to unlock analysis, watchlist and alerts';

  @override
  String get homeErrorTitle => 'Could not load the overview';

  @override
  String get homeLoadingSemantics => 'Loading overview';

  @override
  String get homeMarketTitle => 'Market pulse';

  @override
  String get homeFearGreedTitle => 'Fear & Greed';

  @override
  String get homeFngExtremeFear => 'Extreme fear';

  @override
  String get homeFngFear => 'Fear';

  @override
  String get homeFngNeutral => 'Neutral';

  @override
  String get homeFngGreed => 'Greed';

  @override
  String get homeFngExtremeGreed => 'Extreme greed';

  @override
  String homeFngChange7d(String delta) {
    return '7d: $delta';
  }

  @override
  String homeFngSemantics(int value, String label) {
    return 'Fear and Greed index $value, $label';
  }

  @override
  String get homeBtcDominance => 'BTC dominance';

  @override
  String get homeTotalCap => 'Total market cap';

  @override
  String homeRegimeLabel(String regime) {
    return 'Regime: $regime';
  }

  @override
  String get homeRegimeBull => 'Bull';

  @override
  String get homeRegimeBear => 'Bear';

  @override
  String get homeRegimeSideways => 'Sideways';

  @override
  String get homeRegimeUnknown => 'Unknown';

  @override
  String get homeMarketUnavailable => 'Market data is unavailable right now.';

  @override
  String get homeMoversTitle => 'My watchlist';

  @override
  String get homeMoversEmpty =>
      'Follow coins to see their biggest 24h moves here.';

  @override
  String get homeMoversEmptyAction => 'Open my watchlist';

  @override
  String get homeRadarTitle => 'Latest signals from Radar';

  @override
  String get homeRadarEmpty => 'No new radar signals right now.';

  @override
  String get homeSignalBuy => 'Buy';

  @override
  String get homeSignalSell => 'Sell';

  @override
  String homeSignalStrength(int n) {
    return 'Strength $n/3';
  }

  @override
  String get homeAnalysisTitle => 'Your latest deep analysis';

  @override
  String get homeAnalysisEmpty =>
      'You have not run a deep analysis yet. Pick a coin and try your first one.';

  @override
  String get homeAnalysisNew => 'New analysis';

  @override
  String get homeAnalysisCachedBadge => 'Shared result';

  @override
  String get homeAnalysisOpenFailed =>
      'Could not open this analysis. Please try again.';

  @override
  String get homeEventsTitle => 'Upcoming events';

  @override
  String homeInMinutes(int n) {
    return 'in $n min';
  }

  @override
  String homeInHours(int n) {
    return 'in $n h';
  }

  @override
  String homeInDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get homeEventHigh => 'High importance';

  @override
  String get homeEventMedium => 'Medium importance';

  @override
  String get homeLearnTitle => 'Learn';

  @override
  String get homeTermOfDay => 'Term of the day';

  @override
  String get homeOpenGlossary => 'Open glossary';

  @override
  String get homeProPromoTitle => 'Upgrade to Pro';

  @override
  String get homeProPromoBody =>
      'Deep analysis, price alerts and monthly credits, whenever you feel like it.';

  @override
  String get homeProPromoAction => 'See Pro benefits';

  @override
  String get homeFooterDisclaimer =>
      'For information only; not investment advice.';

  @override
  String get homeFooterSources =>
      'Data sources: Binance, CoinMarketCap, Alternative.me (Fear & Greed Index), FRED.';

  @override
  String get startupPageTitle => 'Start page';

  @override
  String get homeMktTitle => 'Market';

  @override
  String get homeMktGainers => 'Gainers';

  @override
  String get homeMktLosers => 'Losers';

  @override
  String get homeMktVolume => 'Volume';

  @override
  String get homeMktMore => 'Show more';

  @override
  String get homeMktLess => 'Show less';

  @override
  String homeMktVolumeShort(String amount) {
    return 'Vol $amount';
  }

  @override
  String get homeQuickDeep => 'Deep analysis';

  @override
  String get homeQuickAlerts => 'Alerts';

  @override
  String get homeQuickGlossary => 'Glossary';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String quickAnalysisButtonCost(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost credits',
      one: '1 credit',
    );
    return 'Quick analysis · $_temp0';
  }

  @override
  String deepAnalysisButtonCost(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$cost credits',
      one: '1 credit',
    );
    return 'Deep analysis · $_temp0';
  }

  @override
  String get chartTabSummary => 'Summary';

  @override
  String get chartTabAnalyses => 'My analyses';

  @override
  String get chartTabMarket => 'Market';

  @override
  String get chartTabSignals => 'Signals';

  @override
  String get chartTabAlerts => 'Alerts';

  @override
  String get ovEmpty => 'No summary available for this coin yet.';

  @override
  String get ovMarketCap => 'Market cap';

  @override
  String get ovFdv => 'FDV';

  @override
  String get ovVolume24h => '24h volume';

  @override
  String get ovVolMcap => 'Volume / market cap';

  @override
  String get ovSupplyTitle => 'Supply';

  @override
  String get ovCirculating => 'Circulating';

  @override
  String get ovTotalSupply => 'Total';

  @override
  String get ovMaxSupply => 'Max';

  @override
  String get ovNoMaxSupply => 'No max supply';

  @override
  String ovCirculatingOfMax(String pct) {
    return '$pct% of the max supply is in circulation';
  }

  @override
  String get ovPriceChangeTitle => 'Price change';

  @override
  String get ovPeriod24h => '24h';

  @override
  String get ovPeriod7d => '7d';

  @override
  String get ovPeriod30d => '30d';

  @override
  String get ovPeriod90d => '90d';

  @override
  String get ovAth => 'All-time high';

  @override
  String get ovAtl => 'All-time low';

  @override
  String ovFromCurrent(String pct) {
    return '$pct from current price';
  }

  @override
  String get ovCategory => 'Category';

  @override
  String get ovTags => 'Tags';

  @override
  String get ovPlatform => 'Platform';

  @override
  String get ovCoinAge => 'Coin age';

  @override
  String get ovListingAge => 'Listing age';

  @override
  String get ovNewListing => 'New listing';

  @override
  String ovAgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String ovAgeMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String ovAgeYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get ovSource => 'Data: CoinMarketCap, Binance';

  @override
  String get tabLoadFailed => 'Could not load this section.';

  @override
  String get glossaryHelpTooltip => 'What does this mean?';

  @override
  String get coAnalysesEmptyTitle => 'No analyses of this coin yet';

  @override
  String get coAnalysesEmptyBody =>
      'Run your first quick or deep analysis with the buttons above.';

  @override
  String get coAnalysesLoginHint => 'Log in to see your analyses of this coin';

  @override
  String get coAnalysisCached => 'cached';

  @override
  String get relAgoNow => 'just now';

  @override
  String relAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String relAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String relAgoDays(int count) {
    return '$count d ago';
  }

  @override
  String get mkEmpty => 'No market data for this coin yet.';

  @override
  String get mkFuturesTitle => 'Futures (derivatives)';

  @override
  String get mkFunding => 'Funding rate';

  @override
  String mkFundingPercentile(String pct) {
    return 'Higher than $pct% of recent readings';
  }

  @override
  String get mkFundingHintHigh =>
      'Funding is high compared to its recent history: longs are paying shorts, a sign of crowded long positions.';

  @override
  String get mkFundingHintLow =>
      'Funding is low compared to its recent history: shorts are paying longs or longs are not crowded.';

  @override
  String get mkFundingHintNormal => 'Funding is within its usual range.';

  @override
  String get mkOpenInterest => 'Open interest change';

  @override
  String get mkOiHint =>
      'Rising open interest means new money is entering positions; falling means positions are being closed.';

  @override
  String get mkLongShort => 'Long / short balance';

  @override
  String mkLongShare(String pct) {
    return 'Long share $pct%';
  }

  @override
  String get mkLsRatio => 'Long/short ratio';

  @override
  String get mkTopTrader => 'Top traders ratio';

  @override
  String get mkLongShortHint =>
      'Above 1 means more longs than shorts. It describes positioning, not direction.';

  @override
  String get mkTaker => 'Taker buy / sell';

  @override
  String get mkTakerHintBuy => 'Aggressive buyers dominate recent trades.';

  @override
  String get mkTakerHintSell => 'Aggressive sellers dominate recent trades.';

  @override
  String get mkTakerHintBalanced =>
      'Aggressive buying and selling are roughly balanced.';

  @override
  String get mkBasis => 'Basis (futures vs spot)';

  @override
  String get mkBasisHintPos => 'Futures trade above spot (premium).';

  @override
  String get mkBasisHintNeg => 'Futures trade below spot (discount).';

  @override
  String get mkLiquidityTitle => 'Liquidity';

  @override
  String get mkSpread => 'Spread';

  @override
  String mkSpreadValue(String bps) {
    return '$bps bps';
  }

  @override
  String get mkDepthTitle => 'Order book depth';

  @override
  String get mkDepthBid => 'Bid';

  @override
  String get mkDepthAsk => 'Ask';

  @override
  String mkDepthImbalance(String pct) {
    return 'Bid/ask depth ratio $pct';
  }

  @override
  String get mkDepthNote =>
      'Depth is a momentary snapshot of the order book, not a signal.';

  @override
  String get mkActivityTitle => 'Activity';

  @override
  String get mkVolume24h => '24h volume';

  @override
  String get mkTrades24h => 'Trades (24h)';

  @override
  String get mkVolumeRank => 'Volume rank';

  @override
  String get mkSpotNote =>
      'Derivatives metrics (funding, open interest, long/short) apply to futures coins only.';

  @override
  String get sgEmptyTitle => 'No signals yet';

  @override
  String get sgEmptyBody =>
      'No arrows for this coin and timeframe in the loaded history.';

  @override
  String get sgUnsupported =>
      'Signals are available for the 15m, 1h, 4h and 1d timeframes.';

  @override
  String sgPriceAtSignal(String price) {
    return 'At signal $price';
  }

  @override
  String sgSinceSignal(String pct) {
    return '$pct since';
  }

  @override
  String get sgTapHint => 'Tap a row to go back to the chart.';

  @override
  String get alTabEmpty => 'No alerts for this coin yet.';

  @override
  String get alTabAdd => 'Add alert';

  @override
  String get alTabLoginHint => 'Log in to set price alerts';

  @override
  String get alTabHistory => 'Past alerts';

  @override
  String get ovPeriod1h => '1h';

  @override
  String get ovPeriod4h => '4h';

  @override
  String mkDepthIncomplete(String pct) {
    return 'Depth is thin: only the covered window of ±$pct% is shown';
  }

  @override
  String ovSourceFrom(String sources) {
    return 'Data: $sources';
  }

  @override
  String get creditSummaryTitle => 'Your credits';

  @override
  String creditSummaryTotal(int count) {
    return 'Total: $count';
  }

  @override
  String creditSummaryMonthly(int left, int total) {
    return 'Monthly credits $left / $total';
  }

  @override
  String creditSummaryMonthlyLeft(int left) {
    return 'Monthly credits $left';
  }

  @override
  String creditSummaryRenewal(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'in 1 day',
      zero: 'today',
    );
    return 'Renews: $date ($_temp0)';
  }

  @override
  String creditSummaryPurchased(int count) {
    return 'Purchased credits $count — never expire';
  }

  @override
  String get creditPolicyGeneric =>
      'Monthly credits do not carry over to the next month. On the renewal day your remaining monthly credits are topped up to your package amount (Free: 10, Pro: 300). Purchased credits never expire; monthly credits are spent first.';

  @override
  String creditPolicyWithTotal(int total) {
    return 'Monthly credits do not carry over to the next month. On the renewal day your remaining monthly credits are topped up to your package amount ($total). Purchased credits never expire; monthly credits are spent first.';
  }

  @override
  String get creditPolicyShort =>
      'Monthly credits do not carry over; they are topped up to your package amount on the renewal day. Purchased credits never expire.';

  @override
  String planMonthlyNoCarry(int count) {
    return '$count credits every month · no carry-over, topped up to $count credits on the renewal day';
  }

  @override
  String insufficientRenewsOn(String date) {
    return 'Your monthly credits renew on $date.';
  }

  @override
  String insufficientKeepsPurchased(int count) {
    return 'Your $count purchased credits never expire.';
  }

  @override
  String get creditTxMonthlyReset => 'Monthly credit renewal';

  @override
  String get watchlistEmptyHint =>
      'Tap the star on a coin\'s chart to add it here.';

  @override
  String get marketTypeSpot => 'Spot';

  @override
  String get marketTypeFutures => 'Futures';

  @override
  String get quickAnalysisShort => 'Quick analysis';

  @override
  String get deepAnalysisShort => 'Deep analysis';

  @override
  String get subTagline => 'Faster signals, deeper analysis, zero ads.';

  @override
  String subBenefitCreditsTitle(int count) {
    return '$count credits every month';
  }

  @override
  String get subBenefitCreditsDesc =>
      'Topped up on each renewal. Unused monthly credits do not carry over; credits you buy never expire.';

  @override
  String get subBenefitDeepDesc =>
      'Detailed multi-timeframe deep analysis for any coin.';

  @override
  String get subBenefitAlertsDesc =>
      'Set price alerts and get push notifications for new signals on your watchlist.';

  @override
  String get subBenefitTimeframesDesc =>
      'Unlock the fastest 1m and 5m charts and the strongest level 3 signals.';

  @override
  String get subBenefitNoAdsDesc => 'Use the whole app without advertisements.';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subCancelNote => 'Cancel anytime in Google Play.';

  @override
  String get subAlreadyProTitle => 'You are a Pro member';

  @override
  String get subAlreadyProBody =>
      'Thank you for your support! You can manage or cancel your subscription anytime in Google Play.';

  @override
  String get subPlansHeading => 'Choose your plan';

  @override
  String get gbTitle => 'What you can do after signing in';

  @override
  String get gbHeroTagline =>
      'Creating an account is free. Here is what it unlocks.';

  @override
  String get gbHeading => 'With your free account';

  @override
  String gbCreditsTitle(int count) {
    return '$count free credits every month';
  }

  @override
  String get gbCreditsTitleGeneric => 'Free credits every month';

  @override
  String get gbCreditsDesc =>
      'Spend them on AI analyses. Unused monthly credits do not carry over; credits you buy never expire.';

  @override
  String get gbQuickTitle => 'AI analysis of any coin';

  @override
  String gbQuickDesc(int cost) {
    return 'A quick analysis costs $cost credits.';
  }

  @override
  String get gbDeepTitle => 'Deep analysis';

  @override
  String get gbDeepDesc =>
      'Detailed multi-timeframe deep analysis, paid with credits.';

  @override
  String gbSignalsTitle(int level) {
    return 'Chart signals up to level $level';
  }

  @override
  String get gbSignalsDesc =>
      'See buy and sell signals on the chart and in the Signals tab.';

  @override
  String get gbWatchlistTitle => 'Your watchlist';

  @override
  String gbWatchlistDescLimit(int count) {
    return 'Follow up to $count coins and keep an eye on them from the home page.';
  }

  @override
  String get gbWatchlistDescUnlimited =>
      'Follow your coins and keep an eye on them from the home page.';

  @override
  String get gbHistoryTitle => 'Analysis history';

  @override
  String get gbHistoryDesc =>
      'Every analysis you run is saved, so you can reopen it any time.';

  @override
  String get gbAlertsTitle => 'Price alerts and notifications';

  @override
  String get gbAlertsDesc => 'Get notified when a price level is reached.';

  @override
  String get gbProTease =>
      'Want even more? Pro adds deep analysis, price alerts, the strongest signals and the fastest timeframes.';

  @override
  String get homeLockedAction => 'See what you get';

  @override
  String get homeLockedWatchlist =>
      'Log in to follow coins and see their moves here.';

  @override
  String get homeLockedAnalysis =>
      'Log in to run AI analyses and find your latest one here.';

  @override
  String get ovGuestHint =>
      'Log in to see this coin\'s summary and market data';

  @override
  String get sgGuestHint => 'Log in to see this coin\'s signals';

  @override
  String get signalsGuestNote => 'Sign in to see signals';
}
