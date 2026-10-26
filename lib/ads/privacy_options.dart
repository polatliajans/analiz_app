import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/price_alert_provider.dart';

/// Thin wrapper over the UMP privacy-options API so it can be faked in tests.
abstract class PrivacyOptions {
  /// UMP says the user must be able to reopen their privacy choices.
  Future<bool> isRequired();

  /// Shows the privacy options form (no-op result for callers on failure).
  Future<void> show();
}

class UmpPrivacyOptions implements PrivacyOptions {
  const UmpPrivacyOptions();

  @override
  Future<bool> isRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> show() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {
      // Best effort: nothing to show if the form is unavailable.
    }
  }
}

final privacyOptionsProvider = Provider<PrivacyOptions>(
  (ref) => const UmpPrivacyOptions(),
);

/// Whether to list the privacy options entry in Settings. Never for Pro (no
/// ads, so no consent flow). Re-evaluated when the Pro state changes.
final privacyOptionsRequiredProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(isProProvider)) return false;
  return ref.watch(privacyOptionsProvider).isRequired();
});
