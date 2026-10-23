import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Crypto Analysis'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameTr.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageNameTr;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageNameEs;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {details}'**
  String errorOccurred(String details);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your data: watchlist, analysis history, credits, notifications and linked sign-in methods. This cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountProNote.
  ///
  /// In en, this message translates to:
  /// **'If you have an active Pro subscription, deleting your account does not cancel it. Please cancel it separately in Google Play, otherwise you may keep being charged.'**
  String get deleteAccountProNote;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirmAction;

  /// No description provided for @deleteAccountCreditsLost.
  ///
  /// In en, this message translates to:
  /// **'{credits} credits will be deleted and will not be refunded.'**
  String deleteAccountCreditsLost(int credits);

  /// No description provided for @deleteAccountManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription in Google Play'**
  String get deleteAccountManageSubscription;

  /// No description provided for @deleteAccountAckCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand that my credits will be deleted and will not be refunded'**
  String get deleteAccountAckCheckbox;

  /// No description provided for @deleteAccountOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Play.'**
  String get deleteAccountOpenFailed;

  /// No description provided for @errorPurchaseAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This purchase was already processed and cannot be redeemed again.'**
  String get errorPurchaseAlreadyProcessed;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @myWatchlist.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get myWatchlist;

  /// No description provided for @mustLogIn.
  ///
  /// In en, this message translates to:
  /// **'You need to log in'**
  String get mustLogIn;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String accountEmail(String email);

  /// No description provided for @accountRole.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String accountRole(String role);

  /// No description provided for @roleFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get roleFree;

  /// No description provided for @rolePro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get rolePro;

  /// No description provided for @accountCreditBalance.
  ///
  /// In en, this message translates to:
  /// **'Credit balance: {count}'**
  String accountCreditBalance(int count);

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy Credits'**
  String get buyCredits;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @logInOrSignUp.
  ///
  /// In en, this message translates to:
  /// **'Log in / Sign up'**
  String get logInOrSignUp;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @radar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get radar;

  /// No description provided for @searchSymbol.
  ///
  /// In en, this message translates to:
  /// **'Search symbol...'**
  String get searchSymbol;

  /// No description provided for @noCoinsFound.
  ///
  /// In en, this message translates to:
  /// **'No coins found'**
  String get noCoinsFound;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume: {value}'**
  String volumeLabel(String value);

  /// No description provided for @noCandleData.
  ///
  /// In en, this message translates to:
  /// **'No candle data'**
  String get noCandleData;

  /// No description provided for @strongSignalsProNote.
  ///
  /// In en, this message translates to:
  /// **'Strong (3) signals are Pro'**
  String get strongSignalsProNote;

  /// No description provided for @creditsSpent.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 credit spent} other{{count} credits spent}}'**
  String creditsSpent(int count);

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {details}'**
  String analysisFailed(String details);

  /// No description provided for @deepAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis failed: {details}'**
  String deepAnalysisFailed(String details);

  /// No description provided for @quickAnalysisButton.
  ///
  /// In en, this message translates to:
  /// **'Quick Analysis'**
  String get quickAnalysisButton;

  /// No description provided for @deepAnalysisButton.
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis'**
  String get deepAnalysisButton;

  /// No description provided for @creditsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 credit} other{{count} credits}}'**
  String creditsCount(int count);

  /// No description provided for @proSubscription.
  ///
  /// In en, this message translates to:
  /// **'Pro Subscription'**
  String get proSubscription;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String durationDays(int count);

  /// No description provided for @monthlyCredits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 credit every month} other{{count} credits every month}}'**
  String monthlyCredits(int count);

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {details}'**
  String purchaseFailed(String details);

  /// No description provided for @purchaseNoPackage.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be verified because the package information was not found. It will be retried the next time you open the app.'**
  String get purchaseNoPackage;

  /// No description provided for @purchaseNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be verified because the subscription plan information was not found. It will be retried the next time you open the app.'**
  String get purchaseNoPlan;

  /// No description provided for @creditsAdded.
  ///
  /// In en, this message translates to:
  /// **'Credits have been added to your balance.'**
  String get creditsAdded;

  /// No description provided for @proActivated.
  ///
  /// In en, this message translates to:
  /// **'Your Pro subscription has been activated.'**
  String get proActivated;

  /// No description provided for @purchaseWillRetry.
  ///
  /// In en, this message translates to:
  /// **'{details} The purchase will be retried.'**
  String purchaseWillRetry(String details);

  /// No description provided for @purchaseServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The purchase service is unavailable.'**
  String get purchaseServiceUnavailable;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in the store.'**
  String get productNotFound;

  /// No description provided for @purchaseStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the purchase: {details}'**
  String purchaseStartFailed(String details);

  /// No description provided for @termAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get termAll;

  /// No description provided for @termShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get termShort;

  /// No description provided for @termMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get termMedium;

  /// No description provided for @termLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get termLong;

  /// No description provided for @termShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Short term'**
  String get termShortLabel;

  /// No description provided for @termMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium term'**
  String get termMediumLabel;

  /// No description provided for @termLongLabel.
  ///
  /// In en, this message translates to:
  /// **'Long term'**
  String get termLongLabel;

  /// No description provided for @agoNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMinutes(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String agoDays(int n);

  /// No description provided for @radarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No opportunities meet the technical criteria right now.'**
  String get radarEmpty;

  /// No description provided for @radarFooter.
  ///
  /// In en, this message translates to:
  /// **'Score 0-100: shows how oversold it is. Tap an opportunity for an AI-powered deep analysis.'**
  String get radarFooter;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are not following any coins yet'**
  String get watchlistEmpty;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error: {status}'**
  String errorServer(int status);

  /// No description provided for @errorInsufficientCredit.
  ///
  /// In en, this message translates to:
  /// **'Insufficient credit.'**
  String get errorInsufficientCredit;

  /// No description provided for @errorAnalysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Analysis is currently unavailable.'**
  String get errorAnalysisUnavailable;

  /// No description provided for @errorDeepAnalysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis is currently unavailable.'**
  String get errorDeepAnalysisUnavailable;

  /// No description provided for @deepAnalysisWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis is running'**
  String get deepAnalysisWaitingTitle;

  /// No description provided for @deepAnalysisWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'This usually takes 30-90 seconds, sometimes up to 4 minutes. You can leave this screen - we\'ll send you a notification when it\'s ready.'**
  String get deepAnalysisWaitingBody;

  /// No description provided for @deepAnalysisFailedRefunded.
  ///
  /// In en, this message translates to:
  /// **'The deep analysis could not be completed. Your credits have been refunded.'**
  String get deepAnalysisFailedRefunded;

  /// No description provided for @deepAnalysisAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'You already have a deep analysis running. Please wait for it to finish.'**
  String get deepAnalysisAlreadyRunning;

  /// No description provided for @deepAnalysisCheckLater.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Your analysis may still be running - check back later or look at your analysis history.'**
  String get deepAnalysisCheckLater;

  /// No description provided for @deepAnalysisStillRunning.
  ///
  /// In en, this message translates to:
  /// **'Your analysis is still running. You\'ll get a notification when it\'s ready, or you can find it in your analysis history.'**
  String get deepAnalysisStillRunning;

  /// No description provided for @errorAnalysisRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the analysis request: {details}'**
  String errorAnalysisRequestFailed(String details);

  /// No description provided for @errorDeepAnalysisRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the deep analysis request: {details}'**
  String errorDeepAnalysisRequestFailed(String details);

  /// No description provided for @errorSessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your session.'**
  String get errorSessionInvalid;

  /// No description provided for @errorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request: {details}'**
  String errorRequestFailed(String details);

  /// No description provided for @errorInvalidCredentialsOrEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'Invalid details, or this email is already registered.'**
  String get errorInvalidCredentialsOrEmailTaken;

  /// No description provided for @errorSignalsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load signal data: {details}'**
  String errorSignalsFailed(String details);

  /// No description provided for @errorServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server: {details}'**
  String errorServerUnreachable(String details);

  /// No description provided for @errorCreditPackagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load credit packages: {details}'**
  String errorCreditPackagesFailed(String details);

  /// No description provided for @errorDeviceTokenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not register the device token: {details}'**
  String errorDeviceTokenFailed(String details);

  /// No description provided for @errorProOnly.
  ///
  /// In en, this message translates to:
  /// **'This feature is for Pro members only.'**
  String get errorProOnly;

  /// No description provided for @errorPurchaseVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be verified: {details}'**
  String errorPurchaseVerifyFailed(String details);

  /// No description provided for @errorPurchaseInvalid.
  ///
  /// In en, this message translates to:
  /// **'The purchase is not valid.'**
  String get errorPurchaseInvalid;

  /// No description provided for @errorPlayVerificationUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the Google Play verification service.'**
  String get errorPlayVerificationUnreachable;

  /// No description provided for @errorRadarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load Radar: {details}'**
  String errorRadarFailed(String details);

  /// No description provided for @errorPlansFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription plans: {details}'**
  String errorPlansFailed(String details);

  /// No description provided for @errorSubscriptionVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'The subscription could not be verified: {details}'**
  String errorSubscriptionVerifyFailed(String details);

  /// No description provided for @errorSubscriptionInvalid.
  ///
  /// In en, this message translates to:
  /// **'The subscription is not valid.'**
  String get errorSubscriptionInvalid;

  /// No description provided for @errorWatchlistFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your watchlist.'**
  String get errorWatchlistFailed;

  /// No description provided for @errorFollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not follow this coin.'**
  String get errorFollowFailed;

  /// No description provided for @errorUnfollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove it from your watchlist.'**
  String get errorUnfollowFailed;

  /// No description provided for @errorCandlesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load candle data: {details}'**
  String errorCandlesFailed(String details);

  /// No description provided for @errorBinance.
  ///
  /// In en, this message translates to:
  /// **'Binance error: {status}'**
  String errorBinance(int status);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingStart;

  /// No description provided for @replayIntro.
  ///
  /// In en, this message translates to:
  /// **'Replay intro'**
  String get replayIntro;

  /// No description provided for @onboardingDefault1Title.
  ///
  /// In en, this message translates to:
  /// **'Radar: the best setups'**
  String get onboardingDefault1Title;

  /// No description provided for @onboardingDefault1Body.
  ///
  /// In en, this message translates to:
  /// **'Radar scans the market and surfaces the coins with the strongest technical opportunities, so you do not have to hunt for them.'**
  String get onboardingDefault1Body;

  /// No description provided for @onboardingDefault2Title.
  ///
  /// In en, this message translates to:
  /// **'Charts with signals'**
  String get onboardingDefault2Title;

  /// No description provided for @onboardingDefault2Body.
  ///
  /// In en, this message translates to:
  /// **'Read the price action at a glance. Buy and sell arrows on the chart mark the signals as they appear.'**
  String get onboardingDefault2Body;

  /// No description provided for @onboardingDefault3Title.
  ///
  /// In en, this message translates to:
  /// **'AI analysis and alerts'**
  String get onboardingDefault3Title;

  /// No description provided for @onboardingDefault3Body.
  ///
  /// In en, this message translates to:
  /// **'Run a quick or deep AI analysis using credits, and add coins to My Watchlist to get notified when something happens.'**
  String get onboardingDefault3Body;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address is not valid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorWrongCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Use at least 8 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authErrorCancelled;

  /// No description provided for @authErrorEmailUnverifiedConflict.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Verify your email first.'**
  String get authErrorEmailUnverifiedConflict;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to run AI analyses, follow coins and get notified. You can also browse as a guest.'**
  String get authWelcomeSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get verificationEmailSent;

  /// No description provided for @verifyEmailBannerText.
  ///
  /// In en, this message translates to:
  /// **'Verify your email to receive your welcome credit.'**
  String get verifyEmailBannerText;

  /// No description provided for @iHaveVerified.
  ///
  /// In en, this message translates to:
  /// **'I verified'**
  String get iHaveVerified;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendEmail;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Your email is not verified yet.'**
  String get emailNotVerifiedYet;

  /// No description provided for @accountEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get accountEmailVerified;

  /// No description provided for @accountEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get accountEmailNotVerified;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @guestProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up to track your watchlist, buy credits and sync your account.'**
  String get guestProfileHint;

  /// No description provided for @tabChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get tabChart;

  /// No description provided for @tabWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get tabWatchlist;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @analysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'Analysis in progress'**
  String get analysisInProgress;

  /// No description provided for @analysisMayTakeTime.
  ///
  /// In en, this message translates to:
  /// **'This may take 20-30 seconds'**
  String get analysisMayTakeTime;

  /// No description provided for @analysisHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Analyses'**
  String get analysisHistoryTitle;

  /// No description provided for @analysisHistorySection.
  ///
  /// In en, this message translates to:
  /// **'Past analyses'**
  String get analysisHistorySection;

  /// No description provided for @analysisHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No analyses yet'**
  String get analysisHistoryEmpty;

  /// No description provided for @analysisHistoryLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your past analyses'**
  String get analysisHistoryLoginHint;

  /// No description provided for @analysisTypeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get analysisTypeQuick;

  /// No description provided for @analysisTypeDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get analysisTypeDeep;

  /// No description provided for @favoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTab;

  /// No description provided for @favoritesLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your favorite coins'**
  String get favoritesLoginHint;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @alertTooltip.
  ///
  /// In en, this message translates to:
  /// **'Price alert'**
  String get alertTooltip;

  /// No description provided for @myAlerts.
  ///
  /// In en, this message translates to:
  /// **'My alerts'**
  String get myAlerts;

  /// No description provided for @alertsTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get alertsTabActive;

  /// No description provided for @alertsTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get alertsTabHistory;

  /// No description provided for @alertSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set price alert'**
  String get alertSetTitle;

  /// No description provided for @alertCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price: {price}'**
  String alertCurrentPrice(String price);

  /// No description provided for @alertWaitingPrice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the current price...'**
  String get alertWaitingPrice;

  /// No description provided for @alertTargetPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Target price'**
  String get alertTargetPriceLabel;

  /// No description provided for @alertWillTriggerAbove.
  ///
  /// In en, this message translates to:
  /// **'You will get a notification when the price rises to {price} or higher.'**
  String alertWillTriggerAbove(String price);

  /// No description provided for @alertWillTriggerBelow.
  ///
  /// In en, this message translates to:
  /// **'You will get a notification when the price falls to {price} or lower.'**
  String alertWillTriggerBelow(String price);

  /// No description provided for @alertEnterDifferentPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a target price different from the current price.'**
  String get alertEnterDifferentPrice;

  /// No description provided for @alertSetButton.
  ///
  /// In en, this message translates to:
  /// **'Set alert'**
  String get alertSetButton;

  /// No description provided for @alertSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Alert set for {symbol}'**
  String alertSetSuccess(String symbol);

  /// No description provided for @alertActiveForCoin.
  ///
  /// In en, this message translates to:
  /// **'Active alerts for this coin'**
  String get alertActiveForCoin;

  /// No description provided for @alertLimitInfo.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} active alerts used'**
  String alertLimitInfo(int count, int max);

  /// No description provided for @alertCancelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel alert'**
  String get alertCancelTooltip;

  /// No description provided for @alertCanceled.
  ///
  /// In en, this message translates to:
  /// **'Alert canceled'**
  String get alertCanceled;

  /// No description provided for @alertRearm.
  ///
  /// In en, this message translates to:
  /// **'Set again'**
  String get alertRearm;

  /// No description provided for @alertRearmed.
  ///
  /// In en, this message translates to:
  /// **'Alert set again'**
  String get alertRearmed;

  /// No description provided for @alertDirectionAbove.
  ///
  /// In en, this message translates to:
  /// **'Above {price}'**
  String alertDirectionAbove(String price);

  /// No description provided for @alertDirectionBelow.
  ///
  /// In en, this message translates to:
  /// **'Below {price}'**
  String alertDirectionBelow(String price);

  /// No description provided for @alertStatusTriggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered'**
  String get alertStatusTriggered;

  /// No description provided for @alertStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get alertStatusCanceled;

  /// No description provided for @alertTriggeredAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {price}'**
  String alertTriggeredAt(String date, String price);

  /// No description provided for @alertsEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active alerts. Open a coin chart and tap the bell to set one.'**
  String get alertsEmptyActive;

  /// No description provided for @alertsEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No triggered or canceled alerts yet.'**
  String get alertsEmptyHistory;

  /// No description provided for @alertProTitle.
  ///
  /// In en, this message translates to:
  /// **'Price alerts are a Pro feature'**
  String get alertProTitle;

  /// No description provided for @alertProBody.
  ///
  /// In en, this message translates to:
  /// **'Pro members get a push notification the moment a coin reaches their target price.'**
  String get alertProBody;

  /// No description provided for @alertErrorProRequired.
  ///
  /// In en, this message translates to:
  /// **'Price alerts are available for Pro members only.'**
  String get alertErrorProRequired;

  /// No description provided for @alertErrorLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can have at most {limit} active alerts. Cancel one to add another.'**
  String alertErrorLimitReached(int limit);

  /// No description provided for @alertErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have an active alert for this price.'**
  String get alertErrorDuplicate;

  /// No description provided for @alertErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the alert. Please try again.'**
  String get alertErrorGeneric;

  /// No description provided for @legalAboutSection.
  ///
  /// In en, this message translates to:
  /// **'Legal & About'**
  String get legalAboutSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @deleteAccountPage.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountPage;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @financialDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Financial disclaimer'**
  String get financialDisclaimer;

  /// No description provided for @financialDisclaimerText.
  ///
  /// In en, this message translates to:
  /// **'CryptoAnaliz does not provide investment advice. Signals and analyses are for informational purposes only and carry no guarantee. Crypto asset investments carry high risk; you are responsible for your decisions and any resulting losses.'**
  String get financialDisclaimerText;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;

  /// No description provided for @proUpsellBenefitsHeading.
  ///
  /// In en, this message translates to:
  /// **'With Pro you get'**
  String get proUpsellBenefitsHeading;

  /// No description provided for @proBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get proBenefitNoAds;

  /// No description provided for @proBenefitDeepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis'**
  String get proBenefitDeepAnalysis;

  /// No description provided for @proBenefitCredits.
  ///
  /// In en, this message translates to:
  /// **'300 credits every month'**
  String get proBenefitCredits;

  /// No description provided for @proBenefitAlerts.
  ///
  /// In en, this message translates to:
  /// **'Push notifications and price alerts'**
  String get proBenefitAlerts;

  /// No description provided for @proBenefitTimeframes.
  ///
  /// In en, this message translates to:
  /// **'1m and 5m timeframes and strong (3) level signals'**
  String get proBenefitTimeframes;

  /// No description provided for @proBenefitWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Unlimited watchlist'**
  String get proBenefitWatchlist;

  /// No description provided for @proUpsellNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get proUpsellNotNow;

  /// No description provided for @proUpsellDeepTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis is a Pro feature'**
  String get proUpsellDeepTitle;

  /// No description provided for @proUpsellDeepBody.
  ///
  /// In en, this message translates to:
  /// **'Pro members get a more detailed, multi-timeframe deep analysis of any coin.'**
  String get proUpsellDeepBody;

  /// No description provided for @proUpsellTimeframeTitle.
  ///
  /// In en, this message translates to:
  /// **'1m and 5m are Pro timeframes'**
  String get proUpsellTimeframeTitle;

  /// No description provided for @proUpsellTimeframeBody.
  ///
  /// In en, this message translates to:
  /// **'Pro members can watch the fastest timeframes and run AI analysis on them.'**
  String get proUpsellTimeframeBody;

  /// No description provided for @proUpsellStrongSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Strong (3) level signals are a Pro feature'**
  String get proUpsellStrongSignalsTitle;

  /// No description provided for @proUpsellStrongSignalsBody.
  ///
  /// In en, this message translates to:
  /// **'Pro members see all signal levels on the chart, including the strongest (3).'**
  String get proUpsellStrongSignalsBody;

  /// No description provided for @proUpsellWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist is full ({count}/{limit})'**
  String proUpsellWatchlistTitle(int count, int limit);

  /// No description provided for @proUpsellWatchlistBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for an unlimited watchlist.'**
  String get proUpsellWatchlistBody;

  /// No description provided for @proUpsellGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'This is a Pro feature'**
  String get proUpsellGenericTitle;

  /// No description provided for @proUpsellGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to unlock it.'**
  String get proUpsellGenericBody;

  /// No description provided for @proBadgeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pro feature'**
  String get proBadgeTooltip;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adLabel;

  /// No description provided for @insufficientCreditTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough credits'**
  String get insufficientCreditTitle;

  /// No description provided for @insufficientCreditBody.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough credits for this analysis. You can buy credits to continue.'**
  String get insufficientCreditBody;

  /// No description provided for @insufficientCreditBodyWithAd.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough credits for this analysis. Watch a short ad to run this one quick analysis, buy credits, or go Pro.'**
  String get insufficientCreditBodyWithAd;

  /// No description provided for @insufficientCreditDeepBody.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough credits for a deep analysis. You can buy credits or go Pro.'**
  String get insufficientCreditDeepBody;

  /// No description provided for @adAnalysisDeepAlwaysCredits.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis always uses credits.'**
  String get adAnalysisDeepAlwaysCredits;

  /// No description provided for @adAnalysisWatchButton.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad and analyze'**
  String get adAnalysisWatchButton;

  /// No description provided for @adAnalysisRemainingToday.
  ///
  /// In en, this message translates to:
  /// **'Left today: {remaining}'**
  String adAnalysisRemainingToday(int remaining);

  /// No description provided for @adAnalysisCapReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all of today\'s ad-funded analyses: buy credits or go Pro.'**
  String get adAnalysisCapReached;

  /// No description provided for @adAnalysisEmailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Verify your e-mail address to run an analysis by watching an ad.'**
  String get adAnalysisEmailUnverified;

  /// No description provided for @adAnalysisAdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The ad couldn\'t be loaded right now. Please try again in a moment.'**
  String get adAnalysisAdUnavailable;

  /// No description provided for @adAnalysisVerifyTimeout.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm the ad yet. Please try again in a few seconds.'**
  String get adAnalysisVerifyTimeout;

  /// No description provided for @adAnalysisSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'This ad session has expired. Please try again.'**
  String get adAnalysisSessionExpired;

  /// No description provided for @adAnalysisNotFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-funded analysis is only available to free members.'**
  String get adAnalysisNotFree;

  /// No description provided for @adAnalysisDisabled.
  ///
  /// In en, this message translates to:
  /// **'Ad-funded analysis isn\'t available right now.'**
  String get adAnalysisDisabled;

  /// No description provided for @notifChannelAnnouncementsName.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notifChannelAnnouncementsName;

  /// No description provided for @notifChannelAnnouncementsDesc.
  ///
  /// In en, this message translates to:
  /// **'News and announcements from the app'**
  String get notifChannelAnnouncementsDesc;

  /// No description provided for @notifChannelCreditsName.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get notifChannelCreditsName;

  /// No description provided for @notifChannelCreditsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications when credits are added to your account'**
  String get notifChannelCreditsDesc;

  /// No description provided for @notifChannelSignalsName.
  ///
  /// In en, this message translates to:
  /// **'Watchlist signals'**
  String get notifChannelSignalsName;

  /// No description provided for @notifChannelSignalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Trading signals for the coins you follow'**
  String get notifChannelSignalsDesc;

  /// No description provided for @notifChannelAlertsName.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get notifChannelAlertsName;

  /// No description provided for @notifChannelAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications when a coin reaches your target price'**
  String get notifChannelAlertsDesc;

  /// No description provided for @notifRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications?'**
  String get notifRationaleTitle;

  /// No description provided for @notifRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'Get credit and announcement notifications. Pro members also get watchlist signal and price alert notifications.'**
  String get notifRationaleBody;

  /// No description provided for @notifRationaleAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notifRationaleAllow;

  /// No description provided for @notifRationaleLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifRationaleLater;

  /// No description provided for @notifSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsSection;

  /// No description provided for @notifAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get notifAnnouncementsTitle;

  /// No description provided for @notifAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'News and updates from the app'**
  String get notifAnnouncementsSubtitle;

  /// No description provided for @notifCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit notifications'**
  String get notifCreditsTitle;

  /// No description provided for @notifCreditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When credits are added to your account'**
  String get notifCreditsSubtitle;

  /// No description provided for @notifSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist signals'**
  String get notifSignalsTitle;

  /// No description provided for @notifSignalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New signals for the coins you follow'**
  String get notifSignalsSubtitle;

  /// No description provided for @notifAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get notifAlertsTitle;

  /// No description provided for @notifAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When a coin reaches your target price'**
  String get notifAlertsSubtitle;

  /// No description provided for @notifPermissionOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is off'**
  String get notifPermissionOffTitle;

  /// No description provided for @notifPermissionOffBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive notifications until you allow them.'**
  String get notifPermissionOffBody;

  /// No description provided for @notifOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get notifOpenSystemSettings;

  /// No description provided for @notifPermissionManual.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications on from your phone\'s settings.'**
  String get notifPermissionManual;

  /// No description provided for @notifSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notification settings.'**
  String get notifSettingsLoadFailed;

  /// No description provided for @notifSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the change. Please try again.'**
  String get notifSettingsSaveFailed;

  /// No description provided for @proUpsellPushSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Signal notifications are a Pro feature'**
  String get proUpsellPushSignalsTitle;

  /// No description provided for @proUpsellPushSignalsBody.
  ///
  /// In en, this message translates to:
  /// **'Pro members get a push notification when a coin on their watchlist gets a new signal.'**
  String get proUpsellPushSignalsBody;

  /// No description provided for @structuredBiasBullish.
  ///
  /// In en, this message translates to:
  /// **'Bullish'**
  String get structuredBiasBullish;

  /// No description provided for @structuredBiasBearish.
  ///
  /// In en, this message translates to:
  /// **'Bearish'**
  String get structuredBiasBearish;

  /// No description provided for @structuredBiasNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get structuredBiasNeutral;

  /// No description provided for @structuredConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {value}%'**
  String structuredConfidence(int value);

  /// No description provided for @structuredHorizon.
  ///
  /// In en, this message translates to:
  /// **'Horizon: {label}'**
  String structuredHorizon(String label);

  /// No description provided for @structuredHorizonCandles.
  ///
  /// In en, this message translates to:
  /// **'{count} candles'**
  String structuredHorizonCandles(int count);

  /// No description provided for @structuredSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get structuredSectionSummary;

  /// No description provided for @structuredSectionDrivers.
  ///
  /// In en, this message translates to:
  /// **'Key drivers'**
  String get structuredSectionDrivers;

  /// No description provided for @structuredSectionScenarios.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get structuredSectionScenarios;

  /// No description provided for @structuredSectionLevels.
  ///
  /// In en, this message translates to:
  /// **'Key levels'**
  String get structuredSectionLevels;

  /// No description provided for @structuredSectionRisks.
  ///
  /// In en, this message translates to:
  /// **'Risks'**
  String get structuredSectionRisks;

  /// No description provided for @structuredSectionWatch.
  ///
  /// In en, this message translates to:
  /// **'What to watch'**
  String get structuredSectionWatch;

  /// No description provided for @structuredSectionSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get structuredSectionSources;

  /// No description provided for @structuredScenarioBull.
  ///
  /// In en, this message translates to:
  /// **'Bull case'**
  String get structuredScenarioBull;

  /// No description provided for @structuredScenarioBase.
  ///
  /// In en, this message translates to:
  /// **'Base case'**
  String get structuredScenarioBase;

  /// No description provided for @structuredScenarioBear.
  ///
  /// In en, this message translates to:
  /// **'Bear case'**
  String get structuredScenarioBear;

  /// No description provided for @structuredScenarioTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger: {price}'**
  String structuredScenarioTrigger(String price);

  /// No description provided for @structuredScenarioTarget.
  ///
  /// In en, this message translates to:
  /// **'Target: {price}'**
  String structuredScenarioTarget(String price);

  /// No description provided for @structuredLevelResistance.
  ///
  /// In en, this message translates to:
  /// **'Resistance'**
  String get structuredLevelResistance;

  /// No description provided for @structuredLevelSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get structuredLevelSupport;

  /// No description provided for @structuredLevelInvalidation.
  ///
  /// In en, this message translates to:
  /// **'Invalidation'**
  String get structuredLevelInvalidation;

  /// No description provided for @structuredLevelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price at analysis'**
  String get structuredLevelPrice;

  /// No description provided for @structuredDataMissing.
  ///
  /// In en, this message translates to:
  /// **'Some data sources were unavailable: {sources}'**
  String structuredDataMissing(String sources);

  /// No description provided for @structuredDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Not investment advice.'**
  String get structuredDisclaimer;

  /// No description provided for @structuredSourceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get structuredSourceOpenFailed;

  /// No description provided for @glossaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Glossary of technical terms'**
  String get glossaryTitle;

  /// No description provided for @glossarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search terms (e.g. RSI, funding)'**
  String get glossarySearchHint;

  /// No description provided for @glossaryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching terms.'**
  String get glossaryNoResults;

  /// No description provided for @glossaryLearnTerms.
  ///
  /// In en, this message translates to:
  /// **'Learn the terms'**
  String get glossaryLearnTerms;

  /// No description provided for @glossaryIntro.
  ///
  /// In en, this message translates to:
  /// **'Short, neutral explanations of the terms used in analyses. For information only, not investment advice.'**
  String get glossaryIntro;

  /// No description provided for @structuredConclusionTitle.
  ///
  /// In en, this message translates to:
  /// **'Final take'**
  String get structuredConclusionTitle;

  /// No description provided for @structuredSectionBalance.
  ///
  /// In en, this message translates to:
  /// **'Driver balance'**
  String get structuredSectionBalance;

  /// No description provided for @structuredSectionLadder.
  ///
  /// In en, this message translates to:
  /// **'Price ladder'**
  String get structuredSectionLadder;

  /// No description provided for @structuredSectionDataNotes.
  ///
  /// In en, this message translates to:
  /// **'Data notes'**
  String get structuredSectionDataNotes;

  /// No description provided for @structuredSectionOdds.
  ///
  /// In en, this message translates to:
  /// **'Scenario odds'**
  String get structuredSectionOdds;

  /// No description provided for @structuredBalanceItem.
  ///
  /// In en, this message translates to:
  /// **'{label} {count}'**
  String structuredBalanceItem(String label, int count);

  /// No description provided for @analysisPreparedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Prepared 1 min ago} other{Prepared {count} min ago}}'**
  String analysisPreparedMinutes(int count);

  /// No description provided for @analysisPreparedHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Prepared 1 hr ago} other{Prepared {count} hr ago}}'**
  String analysisPreparedHours(int count);

  /// No description provided for @analysisPreparedDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Prepared 1 day ago} other{Prepared {count} days ago}}'**
  String analysisPreparedDays(int count);

  /// No description provided for @analysisPreparedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just prepared'**
  String get analysisPreparedJustNow;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @homeStaleNote.
  ///
  /// In en, this message translates to:
  /// **'Not up to date · updated {ago}'**
  String homeStaleNote(String ago);

  /// No description provided for @homeStaleNoTime.
  ///
  /// In en, this message translates to:
  /// **'Not up to date'**
  String get homeStaleNoTime;

  /// No description provided for @homeGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'See your overview'**
  String get homeGuestTitle;

  /// No description provided for @homeGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Log in to see the market pulse, your watchlist, radar signals and your latest analysis in one place.'**
  String get homeGuestBody;

  /// No description provided for @homeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the overview'**
  String get homeErrorTitle;

  /// No description provided for @homeLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading overview'**
  String get homeLoadingSemantics;

  /// No description provided for @homeResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you left off'**
  String get homeResumeTitle;

  /// No description provided for @homeResumeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open chart'**
  String get homeResumeOpen;

  /// No description provided for @homeMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market pulse'**
  String get homeMarketTitle;

  /// No description provided for @homeFearGreedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fear & Greed'**
  String get homeFearGreedTitle;

  /// No description provided for @homeFngExtremeFear.
  ///
  /// In en, this message translates to:
  /// **'Extreme fear'**
  String get homeFngExtremeFear;

  /// No description provided for @homeFngFear.
  ///
  /// In en, this message translates to:
  /// **'Fear'**
  String get homeFngFear;

  /// No description provided for @homeFngNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get homeFngNeutral;

  /// No description provided for @homeFngGreed.
  ///
  /// In en, this message translates to:
  /// **'Greed'**
  String get homeFngGreed;

  /// No description provided for @homeFngExtremeGreed.
  ///
  /// In en, this message translates to:
  /// **'Extreme greed'**
  String get homeFngExtremeGreed;

  /// No description provided for @homeFngChange7d.
  ///
  /// In en, this message translates to:
  /// **'7d: {delta}'**
  String homeFngChange7d(String delta);

  /// No description provided for @homeFngSemantics.
  ///
  /// In en, this message translates to:
  /// **'Fear and Greed index {value}, {label}'**
  String homeFngSemantics(int value, String label);

  /// No description provided for @homeBtcDominance.
  ///
  /// In en, this message translates to:
  /// **'BTC dominance'**
  String get homeBtcDominance;

  /// No description provided for @homeTotalCap.
  ///
  /// In en, this message translates to:
  /// **'Total market cap'**
  String get homeTotalCap;

  /// No description provided for @homeRegimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Regime: {regime}'**
  String homeRegimeLabel(String regime);

  /// No description provided for @homeRegimeBull.
  ///
  /// In en, this message translates to:
  /// **'Bull'**
  String get homeRegimeBull;

  /// No description provided for @homeRegimeBear.
  ///
  /// In en, this message translates to:
  /// **'Bear'**
  String get homeRegimeBear;

  /// No description provided for @homeRegimeSideways.
  ///
  /// In en, this message translates to:
  /// **'Sideways'**
  String get homeRegimeSideways;

  /// No description provided for @homeRegimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get homeRegimeUnknown;

  /// No description provided for @homeMarketUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Market data is unavailable right now.'**
  String get homeMarketUnavailable;

  /// No description provided for @homeMoversTitle.
  ///
  /// In en, this message translates to:
  /// **'My watchlist'**
  String get homeMoversTitle;

  /// No description provided for @homeMoversEmpty.
  ///
  /// In en, this message translates to:
  /// **'Follow coins to see their biggest 24h moves here.'**
  String get homeMoversEmpty;

  /// No description provided for @homeMoversEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Open my watchlist'**
  String get homeMoversEmptyAction;

  /// No description provided for @homeRadarTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest signals from Radar'**
  String get homeRadarTitle;

  /// No description provided for @homeRadarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No new radar signals right now.'**
  String get homeRadarEmpty;

  /// No description provided for @homeSignalBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get homeSignalBuy;

  /// No description provided for @homeSignalSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get homeSignalSell;

  /// No description provided for @homeSignalStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength {n}/3'**
  String homeSignalStrength(int n);

  /// No description provided for @homeAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Your latest deep analysis'**
  String get homeAnalysisTitle;

  /// No description provided for @homeAnalysisEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not run a deep analysis yet. Pick a coin and try your first one.'**
  String get homeAnalysisEmpty;

  /// No description provided for @homeAnalysisNew.
  ///
  /// In en, this message translates to:
  /// **'New analysis'**
  String get homeAnalysisNew;

  /// No description provided for @homeAnalysisCachedBadge.
  ///
  /// In en, this message translates to:
  /// **'Shared result'**
  String get homeAnalysisCachedBadge;

  /// No description provided for @homeAnalysisOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this analysis. Please try again.'**
  String get homeAnalysisOpenFailed;

  /// No description provided for @homeEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get homeEventsTitle;

  /// No description provided for @homeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {n} min'**
  String homeInMinutes(int n);

  /// No description provided for @homeInHours.
  ///
  /// In en, this message translates to:
  /// **'in {n} h'**
  String homeInHours(int n);

  /// No description provided for @homeInDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{in 1 day} other{in {n} days}}'**
  String homeInDays(int n);

  /// No description provided for @homeEventHigh.
  ///
  /// In en, this message translates to:
  /// **'High importance'**
  String get homeEventHigh;

  /// No description provided for @homeEventMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium importance'**
  String get homeEventMedium;

  /// No description provided for @homeLearnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get homeLearnTitle;

  /// No description provided for @homeTermOfDay.
  ///
  /// In en, this message translates to:
  /// **'Term of the day'**
  String get homeTermOfDay;

  /// No description provided for @homeOpenGlossary.
  ///
  /// In en, this message translates to:
  /// **'Open glossary'**
  String get homeOpenGlossary;

  /// No description provided for @homeProPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Go further with Pro'**
  String get homeProPromoTitle;

  /// No description provided for @homeProPromoBody.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis, price alerts and monthly credits, whenever you feel like it.'**
  String get homeProPromoBody;

  /// No description provided for @homeProPromoAction.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get homeProPromoAction;

  /// No description provided for @homeFooterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'For information only; not investment advice.'**
  String get homeFooterDisclaimer;

  /// No description provided for @homeFooterSources.
  ///
  /// In en, this message translates to:
  /// **'Data sources: Binance, CoinMarketCap, Alternative.me (Fear & Greed Index), FRED.'**
  String get homeFooterSources;

  /// No description provided for @startupPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Start page'**
  String get startupPageTitle;

  /// No description provided for @homeMktTitle.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get homeMktTitle;

  /// No description provided for @homeMktGainers.
  ///
  /// In en, this message translates to:
  /// **'Gainers'**
  String get homeMktGainers;

  /// No description provided for @homeMktLosers.
  ///
  /// In en, this message translates to:
  /// **'Losers'**
  String get homeMktLosers;

  /// No description provided for @homeMktVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get homeMktVolume;

  /// No description provided for @homeMktMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get homeMktMore;

  /// No description provided for @homeMktLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get homeMktLess;

  /// No description provided for @homeMktVolumeShort.
  ///
  /// In en, this message translates to:
  /// **'Vol {amount}'**
  String homeMktVolumeShort(String amount);

  /// No description provided for @homeQuickDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis'**
  String get homeQuickDeep;

  /// No description provided for @homeQuickAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get homeQuickAlerts;

  /// No description provided for @homeQuickGlossary.
  ///
  /// In en, this message translates to:
  /// **'Glossary'**
  String get homeQuickGlossary;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @quickAnalysisButtonCost.
  ///
  /// In en, this message translates to:
  /// **'Quick analysis · {cost, plural, =1{1 credit} other{{cost} credits}}'**
  String quickAnalysisButtonCost(int cost);

  /// No description provided for @deepAnalysisButtonCost.
  ///
  /// In en, this message translates to:
  /// **'Deep analysis · {cost, plural, =1{1 credit} other{{cost} credits}}'**
  String deepAnalysisButtonCost(int cost);

  /// No description provided for @chartTabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get chartTabSummary;

  /// No description provided for @chartTabAnalyses.
  ///
  /// In en, this message translates to:
  /// **'My analyses'**
  String get chartTabAnalyses;

  /// No description provided for @chartTabMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get chartTabMarket;

  /// No description provided for @chartTabSignals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get chartTabSignals;

  /// No description provided for @chartTabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get chartTabAlerts;

  /// No description provided for @ovEmpty.
  ///
  /// In en, this message translates to:
  /// **'No summary available for this coin yet.'**
  String get ovEmpty;

  /// No description provided for @ovMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get ovMarketCap;

  /// No description provided for @ovFdv.
  ///
  /// In en, this message translates to:
  /// **'FDV'**
  String get ovFdv;

  /// No description provided for @ovVolume24h.
  ///
  /// In en, this message translates to:
  /// **'24h volume'**
  String get ovVolume24h;

  /// No description provided for @ovVolMcap.
  ///
  /// In en, this message translates to:
  /// **'Volume / market cap'**
  String get ovVolMcap;

  /// No description provided for @ovSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Supply'**
  String get ovSupplyTitle;

  /// No description provided for @ovCirculating.
  ///
  /// In en, this message translates to:
  /// **'Circulating'**
  String get ovCirculating;

  /// No description provided for @ovTotalSupply.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ovTotalSupply;

  /// No description provided for @ovMaxSupply.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get ovMaxSupply;

  /// No description provided for @ovNoMaxSupply.
  ///
  /// In en, this message translates to:
  /// **'No max supply'**
  String get ovNoMaxSupply;

  /// No description provided for @ovCirculatingOfMax.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of the max supply is in circulation'**
  String ovCirculatingOfMax(String pct);

  /// No description provided for @ovPriceChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Price change'**
  String get ovPriceChangeTitle;

  /// No description provided for @ovPeriod24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get ovPeriod24h;

  /// No description provided for @ovPeriod7d.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get ovPeriod7d;

  /// No description provided for @ovPeriod30d.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get ovPeriod30d;

  /// No description provided for @ovPeriod90d.
  ///
  /// In en, this message translates to:
  /// **'90d'**
  String get ovPeriod90d;

  /// No description provided for @ovAth.
  ///
  /// In en, this message translates to:
  /// **'All-time high'**
  String get ovAth;

  /// No description provided for @ovAtl.
  ///
  /// In en, this message translates to:
  /// **'All-time low'**
  String get ovAtl;

  /// No description provided for @ovFromCurrent.
  ///
  /// In en, this message translates to:
  /// **'{pct} from current price'**
  String ovFromCurrent(String pct);

  /// No description provided for @ovCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ovCategory;

  /// No description provided for @ovTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get ovTags;

  /// No description provided for @ovPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get ovPlatform;

  /// No description provided for @ovCoinAge.
  ///
  /// In en, this message translates to:
  /// **'Coin age'**
  String get ovCoinAge;

  /// No description provided for @ovListingAge.
  ///
  /// In en, this message translates to:
  /// **'Listing age'**
  String get ovListingAge;

  /// No description provided for @ovNewListing.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get ovNewListing;

  /// No description provided for @ovAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String ovAgeDays(int count);

  /// No description provided for @ovAgeMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String ovAgeMonths(int count);

  /// No description provided for @ovAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String ovAgeYears(int count);

  /// No description provided for @ovSource.
  ///
  /// In en, this message translates to:
  /// **'Data: CoinMarketCap, Binance'**
  String get ovSource;

  /// No description provided for @tabLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section.'**
  String get tabLoadFailed;

  /// No description provided for @glossaryHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get glossaryHelpTooltip;

  /// No description provided for @coAnalysesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No analyses of this coin yet'**
  String get coAnalysesEmptyTitle;

  /// No description provided for @coAnalysesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Run your first quick or deep analysis with the buttons above.'**
  String get coAnalysesEmptyBody;

  /// No description provided for @coAnalysesLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your analyses of this coin'**
  String get coAnalysesLoginHint;

  /// No description provided for @coAnalysisCached.
  ///
  /// In en, this message translates to:
  /// **'cached'**
  String get coAnalysisCached;

  /// No description provided for @relAgoNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relAgoNow;

  /// No description provided for @relAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String relAgoMinutes(int count);

  /// No description provided for @relAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String relAgoHours(int count);

  /// No description provided for @relAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String relAgoDays(int count);

  /// No description provided for @mkEmpty.
  ///
  /// In en, this message translates to:
  /// **'No market data for this coin yet.'**
  String get mkEmpty;

  /// No description provided for @mkFuturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Futures (derivatives)'**
  String get mkFuturesTitle;

  /// No description provided for @mkFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding rate'**
  String get mkFunding;

  /// No description provided for @mkFundingPercentile.
  ///
  /// In en, this message translates to:
  /// **'Higher than {pct}% of recent readings'**
  String mkFundingPercentile(String pct);

  /// No description provided for @mkFundingHintHigh.
  ///
  /// In en, this message translates to:
  /// **'Funding is high compared to its recent history: longs are paying shorts, a sign of crowded long positions.'**
  String get mkFundingHintHigh;

  /// No description provided for @mkFundingHintLow.
  ///
  /// In en, this message translates to:
  /// **'Funding is low compared to its recent history: shorts are paying longs or longs are not crowded.'**
  String get mkFundingHintLow;

  /// No description provided for @mkFundingHintNormal.
  ///
  /// In en, this message translates to:
  /// **'Funding is within its usual range.'**
  String get mkFundingHintNormal;

  /// No description provided for @mkOpenInterest.
  ///
  /// In en, this message translates to:
  /// **'Open interest change'**
  String get mkOpenInterest;

  /// No description provided for @mkOiHint.
  ///
  /// In en, this message translates to:
  /// **'Rising open interest means new money is entering positions; falling means positions are being closed.'**
  String get mkOiHint;

  /// No description provided for @mkLongShort.
  ///
  /// In en, this message translates to:
  /// **'Long / short balance'**
  String get mkLongShort;

  /// No description provided for @mkLongShare.
  ///
  /// In en, this message translates to:
  /// **'Long share {pct}%'**
  String mkLongShare(String pct);

  /// No description provided for @mkLsRatio.
  ///
  /// In en, this message translates to:
  /// **'Long/short ratio'**
  String get mkLsRatio;

  /// No description provided for @mkTopTrader.
  ///
  /// In en, this message translates to:
  /// **'Top traders ratio'**
  String get mkTopTrader;

  /// No description provided for @mkLongShortHint.
  ///
  /// In en, this message translates to:
  /// **'Above 1 means more longs than shorts. It describes positioning, not direction.'**
  String get mkLongShortHint;

  /// No description provided for @mkTaker.
  ///
  /// In en, this message translates to:
  /// **'Taker buy / sell'**
  String get mkTaker;

  /// No description provided for @mkTakerHintBuy.
  ///
  /// In en, this message translates to:
  /// **'Aggressive buyers dominate recent trades.'**
  String get mkTakerHintBuy;

  /// No description provided for @mkTakerHintSell.
  ///
  /// In en, this message translates to:
  /// **'Aggressive sellers dominate recent trades.'**
  String get mkTakerHintSell;

  /// No description provided for @mkTakerHintBalanced.
  ///
  /// In en, this message translates to:
  /// **'Aggressive buying and selling are roughly balanced.'**
  String get mkTakerHintBalanced;

  /// No description provided for @mkBasis.
  ///
  /// In en, this message translates to:
  /// **'Basis (futures vs spot)'**
  String get mkBasis;

  /// No description provided for @mkBasisHintPos.
  ///
  /// In en, this message translates to:
  /// **'Futures trade above spot (premium).'**
  String get mkBasisHintPos;

  /// No description provided for @mkBasisHintNeg.
  ///
  /// In en, this message translates to:
  /// **'Futures trade below spot (discount).'**
  String get mkBasisHintNeg;

  /// No description provided for @mkLiquidityTitle.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get mkLiquidityTitle;

  /// No description provided for @mkSpread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get mkSpread;

  /// No description provided for @mkSpreadValue.
  ///
  /// In en, this message translates to:
  /// **'{bps} bps'**
  String mkSpreadValue(String bps);

  /// No description provided for @mkDepthTitle.
  ///
  /// In en, this message translates to:
  /// **'Order book depth'**
  String get mkDepthTitle;

  /// No description provided for @mkDepthBid.
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get mkDepthBid;

  /// No description provided for @mkDepthAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get mkDepthAsk;

  /// No description provided for @mkDepthImbalance.
  ///
  /// In en, this message translates to:
  /// **'Bid/ask depth ratio {pct}'**
  String mkDepthImbalance(String pct);

  /// No description provided for @mkDepthNote.
  ///
  /// In en, this message translates to:
  /// **'Depth is a momentary snapshot of the order book, not a signal.'**
  String get mkDepthNote;

  /// No description provided for @mkActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get mkActivityTitle;

  /// No description provided for @mkVolume24h.
  ///
  /// In en, this message translates to:
  /// **'24h volume'**
  String get mkVolume24h;

  /// No description provided for @mkTrades24h.
  ///
  /// In en, this message translates to:
  /// **'Trades (24h)'**
  String get mkTrades24h;

  /// No description provided for @mkVolumeRank.
  ///
  /// In en, this message translates to:
  /// **'Volume rank'**
  String get mkVolumeRank;

  /// No description provided for @mkSpotNote.
  ///
  /// In en, this message translates to:
  /// **'Derivatives metrics (funding, open interest, long/short) apply to futures coins only.'**
  String get mkSpotNote;

  /// No description provided for @sgEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No signals yet'**
  String get sgEmptyTitle;

  /// No description provided for @sgEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No arrows for this coin and timeframe in the loaded history.'**
  String get sgEmptyBody;

  /// No description provided for @sgUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Signals are available for the 15m, 1h, 4h and 1d timeframes.'**
  String get sgUnsupported;

  /// No description provided for @sgPriceAtSignal.
  ///
  /// In en, this message translates to:
  /// **'At signal {price}'**
  String sgPriceAtSignal(String price);

  /// No description provided for @sgSinceSignal.
  ///
  /// In en, this message translates to:
  /// **'{pct} since'**
  String sgSinceSignal(String pct);

  /// No description provided for @sgTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to go back to the chart.'**
  String get sgTapHint;

  /// No description provided for @alTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alerts for this coin yet.'**
  String get alTabEmpty;

  /// No description provided for @alTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add alert'**
  String get alTabAdd;

  /// No description provided for @alTabLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Log in to set price alerts'**
  String get alTabLoginHint;

  /// No description provided for @alTabHistory.
  ///
  /// In en, this message translates to:
  /// **'Past alerts'**
  String get alTabHistory;

  /// No description provided for @ovPeriod1h.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get ovPeriod1h;

  /// No description provided for @ovPeriod4h.
  ///
  /// In en, this message translates to:
  /// **'4h'**
  String get ovPeriod4h;

  /// No description provided for @mkDepthIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Depth is thin: only the covered window of ±{pct}% is shown'**
  String mkDepthIncomplete(String pct);

  /// No description provided for @ovSourceFrom.
  ///
  /// In en, this message translates to:
  /// **'Data: {sources}'**
  String ovSourceFrom(String sources);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
