import 'analytics_service.dart';

/// Every event name the app sends. Short, snake_case, at most 40 characters,
/// no personal data in any parameter.
abstract final class AnalyticsEvents {
  static const signUp = 'sign_up';
  static const login = 'login';
  static const logout = 'logout';
  static const analysisStarted = 'analysis_started';
  static const analysisCompleted = 'analysis_completed';
  static const analysisFailed = 'analysis_failed';
  static const creditPurchaseStarted = 'credit_purchase_started';
  static const purchase = 'purchase';
  static const subscriptionStarted = 'subscription_started';
  static const proScreenView = 'pro_screen_view';
  static const paywallDismissed = 'paywall_dismissed';
  static const restoreTapped = 'restore_tapped';
  static const adShown = 'ad_shown';
  static const rewardedAdCompleted = 'rewarded_ad_completed';
  static const pushOpened = 'push_opened';
  static const guideCardTapped = 'guide_card_tapped';
  static const termsAccepted = 'terms_accepted';

  static const all = [
    signUp,
    login,
    logout,
    analysisStarted,
    analysisCompleted,
    analysisFailed,
    creditPurchaseStarted,
    purchase,
    subscriptionStarted,
    proScreenView,
    paywallDismissed,
    restoreTapped,
    adShown,
    rewardedAdCompleted,
    pushOpened,
    guideCardTapped,
    termsAccepted,
  ];
}

/// User property names.
abstract final class AnalyticsUserProps {
  static const plan = 'plan';
  static const language = 'language';
  static const platform = 'platform';
}

/// Screen names reported through `screen_view`.
abstract final class AnalyticsScreens {
  static const language = 'language';
  static const onboarding = 'onboarding';
  static const auth = 'auth';
  static const terms = 'terms';

  /// Bottom-tab screens, indexed like `homeTabProvider`.
  static const tabs = ['home', 'chart', 'radar', 'watchlist', 'account'];

  static String tab(int index) =>
      index >= 0 && index < tabs.length ? tabs[index] : tabs.first;
}

/// Sign-in methods for `login` / `sign_up`.
enum AuthMethod { google, email, apple, guest }

/// Which kind of analysis a funnel event is about.
enum AnalysisFunnel { quick, ad, deep }

/// `short` (1m-15m), `medium` (1h-4h), `long` (1d+): the raw interval is not
/// needed for the funnel and keeps the parameter low-cardinality.
String timeframeClass(String timeframe) {
  switch (timeframe) {
    case '1m':
    case '5m':
    case '15m':
      return 'short';
    case '1h':
    case '4h':
      return 'medium';
    default:
      return 'long';
  }
}

String creditCostBucket(int cost) {
  if (cost <= 0) return '0';
  if (cost <= 2) return '1_2';
  if (cost <= 5) return '3_5';
  return '6_plus';
}

/// Typed helpers so call sites never spell event or parameter names.
extension AnalyticsEventLog on AnalyticsService {
  void logLogin(AuthMethod method) =>
      logEvent(AnalyticsEvents.login, {'method': method.name});

  void logSignUp(AuthMethod method) =>
      logEvent(AnalyticsEvents.signUp, {'method': method.name});

  void logLogout() => logEvent(AnalyticsEvents.logout);

  void logAnalysisStarted(AnalysisFunnel kind, String timeframe) => logEvent(
    AnalyticsEvents.analysisStarted,
    {'analysis_type': kind.name, 'timeframe_class': timeframeClass(timeframe)},
  );

  void logAnalysisCompleted(AnalysisFunnel kind, String timeframe, int cost) =>
      logEvent(AnalyticsEvents.analysisCompleted, {
        'analysis_type': kind.name,
        'timeframe_class': timeframeClass(timeframe),
        'credit_cost_bucket': creditCostBucket(cost),
      });

  void logAnalysisFailed(AnalysisFunnel kind, String reason) => logEvent(
    AnalyticsEvents.analysisFailed,
    {'analysis_type': kind.name, 'reason': reason},
  );

  void logCreditPurchaseStarted(String productId) =>
      logEvent(AnalyticsEvents.creditPurchaseStarted, {'item_id': productId});

  /// Server-confirmed credit pack purchase (value/currency are not known to
  /// the app, so only the product id is sent).
  void logPurchase(String productId) => logEvent(AnalyticsEvents.purchase, {
    'item_id': productId,
    'item_type': 'credits',
  });

  /// Server-confirmed new Pro subscription.
  void logSubscriptionStarted(String productId) =>
      logEvent(AnalyticsEvents.subscriptionStarted, {'item_id': productId});

  void logProScreenView(String source) =>
      logEvent(AnalyticsEvents.proScreenView, {'source': source});

  void logPaywallDismissed(String source) =>
      logEvent(AnalyticsEvents.paywallDismissed, {'source': source});

  void logRestoreTapped() => logEvent(AnalyticsEvents.restoreTapped);

  void logAdShown(String placement, String format) => logEvent(
    AnalyticsEvents.adShown,
    {'placement': placement, 'ad_format': format},
  );

  void logRewardedAdCompleted(String placement) =>
      logEvent(AnalyticsEvents.rewardedAdCompleted, {'placement': placement});

  void logPushOpened(String screen) =>
      logEvent(AnalyticsEvents.pushOpened, {'screen': screen});

  /// `source`: home | settings.
  void logGuideCardTapped(String source) =>
      logEvent(AnalyticsEvents.guideCardTapped, {'source': source});

  /// The user accepted the Terms of Use / Privacy Policy version [version].
  void logTermsAccepted(String version) =>
      logEvent(AnalyticsEvents.termsAccepted, {'version': version});
}
