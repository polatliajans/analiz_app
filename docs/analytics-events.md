# Analytics (Firebase Analytics / GA4)

The app reports a small, modest set of events to Firebase Analytics (GA4
property linked to Firebase project `kripto-analiz-affb8`). All code lives in
`lib/services/analytics_*.dart`; call sites use the typed helpers in
`analytics_events.dart` so event and parameter names are spelled in one place.

- Package: `firebase_analytics 11.6.0` (the 11.x line matches `firebase_core ^3.15.x`; no other Firebase package was changed).
- Service: `AnalyticsService` (interface) behind `analyticsProvider`. The default is a no-op, so tests never need Firebase. `main.dart` overrides it with `SafeAnalyticsService(FirebaseAnalyticsBackend())` in release builds.
- Every call is non-blocking and wrapped in try/catch; an SDK failure can never break the app.
- Limits enforced before the SDK sees anything: event name <= 40 chars (`[a-z][a-z0-9_]*`, no `firebase_`/`google_`/`ga_` prefix), <= 25 params, param name <= 40, string value <= 100, user property name <= 24 / value <= 36. Booleans are sent as 1/0, nulls are dropped.
- No PII: no email, no name, no free text. No user id is sent (`setUserId` is not called; the privacy policy says so). Events are tied only to the Analytics app instance id, which is reset on account deletion.

## Consent

Analytics follows the user's consent (Google UMP, the same flow as ads):

1. At start-up the service is **denied**: all consent types denied and collection disabled. Events logged meanwhile (first screens) are held in memory (max 50) and are dropped if consent is never granted.
2. UMP resolves (`lib/ads/ads_controller.dart` after the consent flow; for members whose ads never run, e.g. Pro, a silent form-less UMP refresh once per run):
   - consent **not required** (outside EEA/UK/...): collection is enabled, held events are flushed;
   - consent **obtained** and `canRequestAds()`: enabled;
   - consent still **required**, **unknown**, declined, or UMP unavailable: stays off.
3. Re-evaluated after the user closes **Settings > Ad privacy options**, so a revoked choice stops collection immediately.
4. Only `analytics_storage` is ever granted. `ad_storage`, `ad_user_data`, `ad_personalization` are always denied (analytics is not used for advertising).
5. No advertising ids: Android `google_analytics_adid_collection_enabled=false` (manifest); iOS `$FirebaseAnalyticsWithoutAdIdSupport = true` (Podfile, links the Firebase Analytics build without the IDFA code path). IDFV (vendor id, not an advertising id) is left on so iOS users can be counted. ATT only concerns AdMob, never analytics. Automatic screen reporting is off on both platforms (`google_analytics_automatic_screen_reporting_enabled`, `FirebaseAutomaticScreenReportingEnabled`); screens are reported manually.
6. Debug builds send nothing unless started with `--dart-define=ANALYTICS_DEBUG=true`.

## Events

| Event | Params | Fired from |
|---|---|---|
| `screen_view` | `firebase_screen` (name) | `ScreenViewObserver` (pushed pages), tab changes and root stage in `main.dart` |
| `login` | `method`: google, email, apple, guest | `AuthNotifier._signIn`; guest in `AuthPromptDoneNotifier.continueAsGuest` |
| `sign_up` | `method`: email | `AuthNotifier.registerWithEmail` (Google/Apple report `login`: the app cannot tell a new account) |
| `logout` | - | `AuthNotifier.logout` |
| `analysis_started` | `analysis_type`: quick, ad, deep; `timeframe_class`: short (1m-15m), medium (1h-4h), long (1d+) | `chart_screen.dart` |
| `analysis_completed` | `analysis_type`, `timeframe_class`, `credit_cost_bucket`: 0, 1_2, 3_5, 6_plus | `chart_screen.dart` |
| `analysis_failed` | `analysis_type`, `reason`: insufficient_credit, pro_required, error, job_failed (or server code), timed_out, network_lost (deep: client stopped waiting), or the ad flow outcome (`adUnavailable`, `verificationTimeout`, `capReached`, ...) | `chart_screen.dart` |
| `credit_purchase_started` | `item_id` (store product id; also used for Pro plans) | `CreditPurchaseController.beginBuy` |
| `purchase` | `item_id`, `item_type`=credits | `CreditPurchaseController`, only after the server confirmed a new credit pack purchase (no value/currency: the app does not know them) |
| `subscription_started` | `item_id` | same place, new Pro subscription confirmed by the server (a restore is not a start) |
| `pro_screen_view` | `source`: subscription_screen, upsell_<feature> | `SubscriptionScreen`, `showProUpsell` |
| `paywall_dismissed` | `source` | left the Pro screen / upsell without upgrading |
| `restore_tapped` | - | `CreditPurchaseController.restorePurchases` |
| `ad_shown` | `placement` (interstitial_analysis, interstitial_navigation, rewarded_analysis), `ad_format` (interstitial, rewarded) | `AdsController` full-screen callbacks. Banner/native are not logged (very high volume) |
| `rewarded_ad_completed` | `placement` | `AdsController` (reward earned) |
| `push_opened` | `screen` (target screen name) | `pushServiceProvider` (notification tap) |

Not implemented because the feature does not exist in the app: `share_analysis_tapped`, `report_analysis_tapped`.

Screens reported by `screen_view`: `language`, `onboarding`, `auth`, the tabs (`home`, `chart`, `radar`, `watchlist`, `account`) and pushed pages (`subscription`, `credit_packages`, `auth`, `email_auth`, `glossary`, `guest_benefits`, `alarms`, `onboarding`, `settings`, `analysis_history`; see `analytics_screens.dart`).

## User properties

| Property | Values |
|---|---|
| `plan` | guest, free, pro |
| `language` | app language code (tr, en, es, ...) |
| `platform` | android, ios |

In GA4 register `plan`, `language` and `platform` as custom dimensions (user scope), and the event params you want to report on (`method`, `analysis_type`, `timeframe_class`, `credit_cost_bucket`, `reason`, `item_id`, `source`, `placement`, `ad_format`, `screen`) as event-scoped custom dimensions; unregistered params are collected but not shown in reports.

## Verify in Firebase DebugView / Realtime

Standard GA4 reports take 24-48 hours to fill. **Realtime** and **DebugView** show events within minutes, so verify there first.

Android (debug or release build installed on a device, consent granted):

```
adb shell setprop debug.firebase.analytics.app com.polatliajans.kriptoanaliz
# to switch it off again:
adb shell setprop debug.firebase.analytics.app .none.
```

iOS (Xcode scheme > Run > Arguments Passed On Launch): `-FIRAnalyticsDebugEnabled` (and `-FIRAnalyticsDebugDisabled` to turn it off).

Then open Firebase console > Analytics > **DebugView** (or GA4 > Admin > DebugView / Reports > Realtime) and check: `screen_view` while switching tabs, `login`, an analysis (`analysis_started` / `analysis_completed`), the Pro screen (`pro_screen_view`), and that user property `plan` is set. In the EEA/UK nothing appears until the consent form is accepted; declining it must keep DebugView empty.

For a debug build add `--dart-define=ANALYTICS_DEBUG=true` to `flutter run`.
