import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads_controller.dart';
import '../ads/rewarded_ad_button.dart';
import '../l10n/app_localizations.dart';
import '../screens/credit_packages_screen.dart';

/// Shown when an analysis is refused with 402: buy credits, or (Free users
/// with rewards left today) watch a rewarded ad for free credits.
Future<void> showInsufficientCreditDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _InsufficientCreditDialog(),
  );
}

class _InsufficientCreditDialog extends ConsumerStatefulWidget {
  const _InsufficientCreditDialog();

  @override
  ConsumerState<_InsufficientCreditDialog> createState() =>
      _InsufficientCreditDialogState();
}

class _InsufficientCreditDialogState
    extends ConsumerState<_InsufficientCreditDialog> {
  @override
  void initState() {
    super.initState();
    ref.read(adsControllerProvider.notifier).preloadRewarded();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = ref.watch(rewardedOfferProvider);
    final navigator = Navigator.of(context);

    return AlertDialog(
      icon: const Icon(Icons.toll_outlined),
      title: Text(l10n.insufficientCreditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer
                ? l10n.insufficientCreditBodyWithAd
                : l10n.insufficientCreditBody,
          ),
          if (offer) ...[
            const SizedBox(height: 16),
            RewardedAdButton(beforeShow: () => navigator.pop()),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => navigator.pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            navigator.pop();
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => const CreditPackagesScreen(),
              ),
            );
          },
          child: Text(l10n.buyCredits),
        ),
      ],
    );
  }
}
