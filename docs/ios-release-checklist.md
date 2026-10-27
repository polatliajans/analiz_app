# iOS release checklist (CryptoAnaliz, `com.polatliajans.kriptoanaliz`)

The iOS project was prepared without a Mac. Everything below marked **YOU** has to be done
in the Apple / Firebase / AdMob / Codemagic consoles. Secrets are never committed.

## 0. How the pieces fit

| Item | Where it comes from |
|---|---|
| `GoogleService-Info.plist` | Codemagic secure var `GOOGLE_SERVICE_INFO_PLIST` (base64). `tool/ios_prepare_secrets.sh` writes `ios/Runner/GoogleService-Info.plist` (git-ignored). The Xcode project lists it as a bundle resource, so a build **fails** without it. |
| Google Sign-In URL scheme | The same script reads `REVERSED_CLIENT_ID` from the plist and writes `GOOGLE_REVERSED_CLIENT_ID` into `ios/Flutter/Secrets.xcconfig` (git-ignored). It feeds `Info.plist` `CFBundleURLTypes`. |
| AdMob iOS **app** id | Codemagic var `ADMOB_IOS_APP_ID` goes into the same `Secrets.xcconfig` and then `Info.plist` `GADApplicationIdentifier`. The default in `ios/Flutter/AppConfig.xcconfig` is Google's test app id. |
| Build number | `ios-release` workflow: max(latest TestFlight build number, pubspec build number) + 1; values are logged, a CLI failure fails the build |
| Crashlytics dSYMs | Xcode run-script phase "Upload Crashlytics dSYMs" (non-Debug builds) |

## 1. Apple Developer portal (YOU)

1. **Identifiers > App IDs**: register `com.polatliajans.kriptoanaliz` (explicit) and enable:
   - **Push Notifications**
   - **Sign in with Apple** (enable as primary App ID)
   - **In-App Purchase**
2. **Keys**: create
   - an **APNs Auth Key** (`.p8`, Apple Push Notifications service), needed by Firebase;
   - a **Sign in with Apple key** (`.p8`, with its Key ID), needed by Firebase to revoke the Apple token on account deletion;
   - an **App Store Connect API key** (Users and Access > Integrations > App Store Connect API, role App Manager or Admin) for Codemagic;
   - an **In-App Purchase key** (App Store Connect > Users and Access > Integrations > In-App Purchase, `.p8`): note the **Issuer ID** (shown on that page), the **Key ID**, and download the `.p8` once (it cannot be downloaded again). The server uses it to verify purchases with the App Store Server API.
3. Note your **Team ID**.

## 2. App Store Connect (YOU)

1. My Apps > **New App**: iOS, name `CryptoAnaliz`, bundle id `com.polatliajans.kriptoanaliz`. Note the numeric **Apple ID** (App Information > General); it is the Codemagic variable `APP_STORE_APPLE_ID`.
2. **Agreements, Tax, and Banking**: accept the Paid Apps agreement and fill in bank/tax info (required for IAP).
3. **In-App Purchases**: create the credit packs as **Consumable** products (price, localized names tr/en/es, review screenshot). Enter each product id in the **iOS product id** field of the matching credit package in the Laravel admin (it is stored as `apple_product_id`). **Pro is NOT sold on iOS in v1**: do not create an auto-renewable subscription or a subscription group; the server rejects iOS subscription purchases with `422 subscription_not_supported_ios`, and the app hides every Pro purchase surface on iOS (members who already are Pro, e.g. bought on Android, keep their Pro status and benefits).
4. **Server configuration** (Laravel admin > Settings > "Apple App Store Ayarları"): enter the In-App Purchase key from step 1.2: `apple_issuer_id` (Issuer ID), `apple_key_id` (Key ID), `apple_private_key` (contents of the `.p8`) and `apple_bundle_id` (`com.polatliajans.kriptoanaliz`). The legacy App-Specific Shared Secret is not used.
5. **App Privacy** questionnaire: answer it consistently with `ios/Runner/PrivacyInfo.xcprivacy` (name, email, user id, device id, advertising data, purchase history, crash data, performance data, product interaction; tracking = yes because of ads).
6. Age rating, category, support URL, **Privacy Policy URL** (`https://www.cryptoanaliz.net/privacy`), screenshots (6.9" and 6.5" iPhone; the app is iPhone-only).
7. **App Review information**: a demo account (email + password) and a note such as "Crypto market analysis, no trading, not financial advice".
8. Put the Terms of Use link (`https://www.cryptoanaliz.net/terms`) into the app description (the app also links it on the login screen and the legal links row).

## 3. Firebase console (YOU)

1. Project settings > Your apps > **Add iOS app** with bundle id `com.polatliajans.kriptoanaliz`. Download `GoogleService-Info.plist` (never commit it).
2. Authentication > Sign-in method:
   - keep **Google** enabled (download the plist again after adding the iOS app so it contains `CLIENT_ID` and `REVERSED_CLIENT_ID`);
   - enable **Apple**; for native iOS the Services ID can stay empty. Add Team ID, Key ID and the Sign in with Apple `.p8` so `revokeTokenWithAuthorizationCode` works on account deletion.
3. Project settings > Cloud Messaging > Apple app configuration: upload the **APNs Auth Key** (`.p8`) with Key ID and Team ID.
4. Crashlytics: the iOS app shows up after its first run.
5. Create the Codemagic value: `base64 -i GoogleService-Info.plist | tr -d '\n'` (macOS) or `base64 -w0 GoogleService-Info.plist` (Linux).

## 4. AdMob (YOU)

1. Apps > **Add app** > iOS.
2. Copy the **iOS App ID** (`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`, note the `~`) into Codemagic as `ADMOB_IOS_APP_ID`.
3. Create the iOS ad units (banner x2, native x2, interstitial x2, rewarded) and enter them as the iOS unit ids in the Laravel admin (the server returns the platform specific `unit_id`).
4. Privacy & messaging: make sure the GDPR (UMP) message is published; optionally add the IDFA explainer message (the app asks ATT right after UMP).
5. Keep `app-ads.txt` on the developer website up to date.

## 5. Codemagic (YOU)

1. Add the repository as an application and choose the **codemagic.yaml** configuration.
2. Teams > Integrations > Developer Portal > **App Store Connect**: add the API key from step 1.2 and name the integration exactly `codemagic_asc`.
3. Code signing identities > iOS: let Codemagic create/fetch a distribution certificate and an App Store provisioning profile through the integration, or upload your own. The profile must be for `com.polatliajans.kriptoanaliz` and was generated after enabling Push and Sign in with Apple.
4. Environment variables > group **`ios_release`** (mark secure):
   - `GOOGLE_SERVICE_INFO_PLIST`: base64 of the plist (step 3.5)
   - `ADMOB_IOS_APP_ID`: step 4.2
   - `APP_STORE_APPLE_ID`: step 2.1
5. Run workflow **ios-release** manually. It analyzes, tests, signs, builds the IPA and uploads it to App Store Connect (`submit_to_testflight: false`; change to `true` for automatic TestFlight distribution). Workflow **ios-ci** runs on every push and only checks analyze, tests and an unsigned debug build with a stub plist.

## 6. First device test via TestFlight (YOU)

Install the build on a real iPhone and verify: Google login; **Continue with Apple** (visible on iOS only); push permission and receiving a push (FCM token registered with platform `ios`); the ATT prompt appears after the consent form; test ads; sandbox purchase of a credit pack (incl. killing the app mid-purchase and relaunching: the pending transaction must be credited at launch); no Pro price, plan card, buy or restore button anywhere on iOS (a free account sees only the credit packs); account deletion (Apple users get a re-authorization prompt to revoke the token); Privacy/Terms links on the login screen.

## 7. Limits of the Windows-only verification (assumptions)

- Nothing in `ios/` was compiled. `project.pbxproj` was edited by hand and only parsed with a pbxproj parser.
- `NSPrivacyTrackingDomains` lists `googleads.g.doubleclick.net` and `pagead2.googlesyndication.com`; Google's SDK ships its own manifest which Xcode merges. Re-check against Google's current docs.
- The SKAdNetwork list (50 ids) comes from the AdMob iOS quick-start page on the day of implementation; Google updates it periodically.
- `aps-environment` is `development` in `Runner.entitlements`; the App Store export re-signs with the distribution profile (production APNs).
- iPad is not targeted (`TARGETED_DEVICE_FAMILY = 1`, portrait only), so no iPad screenshots are required.
- Credit packs are consumables and cannot be restored; a Restore button exists only in the (currently iOS-hidden) Pro screen. When iOS subscriptions are built, flip `proPurchaseAvailableFor` in `lib/utils/pro_purchase.dart` and add the Pro product, the subscription group and the Restore flow back to this checklist.
- Binance market data falls back to `data-api.binance.vision` / `data-stream.binance.vision` when the main hosts answer HTTP 451/403 (US IPs, e.g. App Review). Futures-only data has no such fallback and degrades gracefully.
