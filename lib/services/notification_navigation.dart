import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coin.dart';
import '../providers/coin_list_provider.dart';
import '../providers/deep_analysis_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../screens/alarms_screen.dart';
import '../screens/credit_packages_screen.dart';
import '../screens/subscription_screen.dart';
import '../widgets/pro_upsell_sheet.dart';
import 'notification_logic.dart';

Future<Coin?> _findCoin(WidgetRef ref, int id) async {
  for (final market in const ['spot', 'futures']) {
    try {
      final coins = await ref.read(coinListProvider(market).future);
      for (final c in coins) {
        if (c.id == id) return c;
      }
    } catch (_) {
      // Coin list unavailable; fall through to "chart tab only".
    }
  }
  return null;
}

/// Opens the screen a tapped notification points to. The caller makes sure the
/// home shell is showing and, for login-only screens, that the member is
/// signed in.
Future<void> applyNotificationTarget(
  WidgetRef ref,
  NavigatorState navigator,
  NotificationTarget target,
) async {
  if (target.screen == NotificationScreen.none) return;
  navigator.popUntil((route) => route.isFirst);
  final tabs = ref.read(homeTabProvider.notifier);

  switch (target.screen) {
    case NotificationScreen.none:
      return;
    case NotificationScreen.profile:
      tabs.select(profileTabIndex);
    case NotificationScreen.radar:
      tabs.select(radarTabIndex);
    case NotificationScreen.creditPackages:
      tabs.select(profileTabIndex);
      navigator.push(
        MaterialPageRoute(builder: (_) => const CreditPackagesScreen()),
      );
    case NotificationScreen.subscription:
      tabs.select(profileTabIndex);
      navigator.push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    case NotificationScreen.alarms:
      tabs.select(profileTabIndex);
      if (ref.read(isProProvider)) {
        navigator.push(MaterialPageRoute(builder: (_) => const AlarmsScreen()));
      } else {
        final context = navigator.overlay?.context;
        if (context != null) showProUpsell(context, ProFeature.priceAlert);
      }
    case NotificationScreen.deepAnalysis:
      // The chart tab shows the result sheet once the job has been fetched.
      tabs.select(chartTabIndex);
      final jobId = target.jobId;
      if (jobId == null) return;
      ref.read(deepAnalysisProvider.notifier).openJob(jobId);
    case NotificationScreen.chart:
      tabs.select(chartTabIndex);
      final id = target.coinId;
      if (id == null) return;
      final coin = await _findCoin(ref, id);
      if (coin != null) {
        await ref.read(selectedCoinProvider.notifier).select(coin);
      }
  }
}
