import 'package:flutter/foundation.dart';

/// Platform name the server expects in `X-Platform` and in device/purchase
/// payloads: `ios` on iOS, `android` everywhere else.
String platformName([TargetPlatform? platform]) =>
    (platform ?? defaultTargetPlatform) == TargetPlatform.iOS
    ? 'ios'
    : 'android';

/// True when running on iOS (App Store build).
bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
