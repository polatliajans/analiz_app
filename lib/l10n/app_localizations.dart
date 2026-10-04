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

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountSignUp;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Password (at least 8 characters)'**
  String get passwordMinChars;

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
