import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ad_logic.dart';
import 'package:kriptoanaliz/ads/consent_flow.dart';
import 'package:kriptoanaliz/data/api_http.dart';
import 'package:kriptoanaliz/data/purchase_payload.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/services/apple_sign_in_logic.dart';
import 'package:kriptoanaliz/services/push_notification_service.dart';
import 'package:kriptoanaliz/utils/platform_info.dart';
import 'package:kriptoanaliz/widgets/apple_sign_in_button.dart';

void main() {
  group('platform header', () {
    tearDown(() => ApiHttp.platformResolver = platformName);

    test('platformName maps iOS and everything else', () {
      expect(platformName(TargetPlatform.iOS), 'ios');
      expect(platformName(TargetPlatform.android), 'android');
      expect(platformName(TargetPlatform.macOS), 'android');
    });

    test('every request carries X-Platform and Accept-Language', () {
      ApiHttp.platformResolver = () => 'ios';
      final h = ApiHttp.defaultHeaders({'Authorization': 'Bearer t'});
      expect(h['X-Platform'], 'ios');
      expect(h['Accept-Language'], ApiHttp.languageCode);
      expect(h['Authorization'], 'Bearer t');
      ApiHttp.platformResolver = () => 'android';
      expect(ApiHttp.defaultHeaders()['X-Platform'], 'android');
    });
  });

  group('Sign in with Apple helpers', () {
    test('nonce has requested length and URL-safe charset', () {
      final n = generateAppleNonce();
      expect(n.length, 32);
      expect(RegExp(r'^[0-9A-Za-z\-._]+$').hasMatch(n), isTrue);
      expect(generateAppleNonce(), isNot(n));
      expect(generateAppleNonce(10).length, 10);
    });

    test('sha256 matches the known vector', () {
      expect(
        sha256ofString('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('display name joins the parts Apple provided', () {
      expect(appleDisplayName('Ada', 'Lovelace'), 'Ada Lovelace');
      expect(appleDisplayName('Ada', null), 'Ada');
      expect(appleDisplayName(' ', ''), isNull);
      expect(appleDisplayName(null, null), isNull);
    });
  });

  group('purchase payload', () {
    test('android keeps the single purchase_token field', () {
      final proof = purchaseProofFrom(
        ios: false,
        purchaseId: 'GPA.1',
        serverVerificationData: 'play-token',
      );
      expect(buildPurchaseBody(proof, platform: 'android'), {
        'purchase_token': 'play-token',
      });
    });

    test('ios sends transaction id as token plus the receipt', () {
      final proof = purchaseProofFrom(
        ios: true,
        purchaseId: '1000000123',
        serverVerificationData: 'base64receipt',
      );
      expect(buildPurchaseBody(proof, platform: 'ios'), {
        'platform': 'ios',
        'purchase_token': '1000000123',
        'receipt': 'base64receipt',
      });
    });

    test('ios without a transaction id falls back to the receipt', () {
      final proof = purchaseProofFrom(
        ios: true,
        purchaseId: null,
        serverVerificationData: 'r',
      );
      expect(proof.token, 'r');
      expect(proof.receipt, 'r');
    });
  });

  group('store product ids', () {
    test('credit package uses the Apple id on iOS with Android fallback', () {
      final p = CreditPackage.fromJson({
        'id': 1,
        'name': 'x',
        'credit_amount': 10,
        'price': '1.99',
        'store_product_id_android': 'and',
        'apple_product_id': 'apl',
      });
      expect(p.productIdFor(TargetPlatform.iOS), 'apl');
      expect(p.productIdFor(TargetPlatform.android), 'and');
      const legacy = CreditPackage(
        id: 2,
        name: 'y',
        creditAmount: 1,
        price: '1',
        storeProductIdAndroid: 'and',
      );
      expect(legacy.productIdFor(TargetPlatform.iOS), 'and');
      expect(legacy.storeProductId, 'and'); // tests run as Android
    });

    test('subscription plan uses the Apple id on iOS', () {
      final p = SubscriptionPlan.fromJson({
        'id': 1,
        'name': 'Pro',
        'price': '4.99',
        'duration_days': 30,
        'store_product_id_android': 'and',
        'apple_product_id': 'apl',
      });
      expect(p.productIdFor(TargetPlatform.iOS), 'apl');
      expect(p.productIdFor(TargetPlatform.android), 'and');
    });
  });

  group('ad unit ids per platform', () {
    test('Google iOS test ids', () {
      expect(
        testUnitIdFor(AdFormat.banner, ios: true),
        'ca-app-pub-3940256099942544/2435281174',
      );
      expect(
        testUnitIdFor(AdFormat.interstitial, ios: true),
        'ca-app-pub-3940256099942544/4411468910',
      );
      expect(
        testUnitIdFor(AdFormat.native, ios: true),
        'ca-app-pub-3940256099942544/3986624511',
      );
      expect(
        testUnitIdFor(AdFormat.rewarded, ios: true),
        'ca-app-pub-3940256099942544/1712485313',
      );
      expect(
        testUnitIdFor(AdFormat.banner),
        'ca-app-pub-3940256099942544/9214589741',
      );
    });

    test('debug falls back to the platform test unit, release to null', () {
      expect(
        resolveUnitId(null, AdFormat.banner, isDebug: true, ios: true),
        iosTestUnitIds[AdFormat.banner],
      );
      expect(
        resolveUnitId(null, AdFormat.banner, isDebug: true),
        testUnitIds[AdFormat.banner],
      );
      expect(
        resolveUnitId(null, AdFormat.banner, isDebug: false, ios: true),
        isNull,
      );
    });

    test('the server unit id always wins', () {
      expect(
        resolveUnitId(
          'ca-app-pub-1/2',
          AdFormat.banner,
          isDebug: true,
          ios: true,
        ),
        'ca-app-pub-1/2',
      );
    });
  });

  group('consent flow order', () {
    ConsentFlowSteps steps(
      List<String> log, {
      required bool ios,
      bool canRequest = true,
      bool attThrows = false,
    }) => ConsentFlowSteps(
      ios: ios,
      ump: () async => log.add('ump'),
      canRequestAds: () async {
        log.add('can');
        return canRequest;
      },
      requestTracking: () async {
        log.add('att');
        if (attThrows) throw StateError('att');
      },
      initialize: () async => log.add('init'),
    );

    test('iOS: UMP, then ATT, then SDK init', () async {
      final log = <String>[];
      expect(await runConsentFlow(steps(log, ios: true)), isTrue);
      expect(log, ['ump', 'can', 'att', 'init']);
    });

    test('Android never asks ATT', () async {
      final log = <String>[];
      expect(await runConsentFlow(steps(log, ios: false)), isTrue);
      expect(log, ['ump', 'can', 'init']);
    });

    test('no ads allowed: no ATT, no init', () async {
      final log = <String>[];
      expect(
        await runConsentFlow(steps(log, ios: true, canRequest: false)),
        isFalse,
      );
      expect(log, ['ump', 'can']);
    });

    test('a failing ATT request does not block init', () async {
      final log = <String>[];
      expect(
        await runConsentFlow(steps(log, ios: true, attThrows: true)),
        isTrue,
      );
      expect(log, ['ump', 'can', 'att', 'init']);
    });
  });

  group('retryUntilNonNull (APNs token)', () {
    test('returns null after the attempts when never available', () async {
      var calls = 0;
      final v = await retryUntilNonNull<String>(
        () async {
          calls++;
          return null;
        },
        attempts: 3,
        delay: Duration.zero,
      );
      expect(v, isNull);
      expect(calls, 3);
    });

    test('returns the value once it appears; errors count as null', () async {
      var calls = 0;
      final v = await retryUntilNonNull<String>(
        () async {
          calls++;
          if (calls == 1) throw StateError('apns-token-not-set');
          return calls == 2 ? null : 'token';
        },
        attempts: 5,
        delay: Duration.zero,
      );
      expect(v, 'token');
      expect(calls, 3);
    });
  });

  group('Apple button', () {
    Widget host(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );

    testWidgets('hidden off iOS', (tester) async {
      await tester.pumpWidget(host(AppleSignInButton(onPressed: () {})));
      expect(find.byKey(const Key('apple-sign-in')), findsNothing);
    });

    testWidgets('black on light, white on dark, localized label', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(AppleSignInButton(onPressed: () {}, forceVisible: true)),
      );
      expect(find.text('Continue with Apple'), findsOneWidget);
      var btn = tester.widget<FilledButton>(
        find.byKey(const Key('apple-sign-in')),
      );
      expect(btn.style!.backgroundColor!.resolve({}), Colors.black);
      await tester.pumpWidget(
        host(
          AppleSignInButton(onPressed: () {}, forceVisible: true),
          b: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle(); // theme animation
      btn = tester.widget<FilledButton>(find.byKey(const Key('apple-sign-in')));
      expect(btn.style!.backgroundColor!.resolve({}), Colors.white);
    });
  });
}
