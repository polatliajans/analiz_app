import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/price_alert_provider.dart';
import 'ad_logic.dart';
import 'ads_controller.dart';

/// Whether "watch an ad for credits" should be offered to the current user.
final rewardedOfferProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return canOfferRewarded(
    ads: ref.watch(effectiveAdsConfigProvider),
    isPro: ref.watch(isProProvider),
    isLoggedIn: auth.isLoggedIn,
    emailVerified: auth.member?.emailVerified ?? false,
  );
});

/// Shows the rewarded ad and reports the outcome with [messenger]. On a
/// reward the balance is refreshed in the background (server-side SSV).
Future<void> watchRewardedAd(
  AdsController controller,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final outcome = await controller.showRewarded();
  switch (outcome) {
    case RewardedOutcome.earned:
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rewardedEarnedPending)),
      );
      await controller.refreshBalanceAfterReward();
    case RewardedOutcome.unavailable:
    case RewardedOutcome.failed:
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rewardedAdUnavailable)),
      );
    case RewardedOutcome.dismissed:
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.rewardedNotCompleted)),
      );
  }
}

/// "Watch an ad, +N credits (left today: X)". Hidden when not offered;
/// disabled while no ad is loaded. [beforeShow] runs right before the ad
/// (e.g. to close the dialog hosting the button).
class RewardedAdButton extends ConsumerWidget {
  final VoidCallback? beforeShow;
  const RewardedAdButton({super.key, this.beforeShow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(rewardedOfferProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final rewarded = ref.watch(effectiveAdsConfigProvider).rewarded;
    final loaded = ref.watch(
      adsControllerProvider.select((s) => s.rewardedLoaded),
    );
    return OutlinedButton.icon(
      onPressed: loaded
          ? () {
              final messenger = ScaffoldMessenger.of(context);
              final controller = ref.read(adsControllerProvider.notifier);
              beforeShow?.call();
              watchRewardedAd(controller, messenger, l10n);
            }
          : null,
      icon: const Icon(Icons.ondemand_video_outlined),
      label: Text(
        l10n.rewardedWatchButton(rewarded.amount, rewarded.remainingToday ?? 0),
      ),
    );
  }
}
