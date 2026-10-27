import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/credit_packages_screen.dart';
import '../screens/subscription_screen.dart';

/// Whether the Pro subscription can be bought on [platform].
///
/// iOS v1 sells credit packs only (the server answers iOS subscription
/// purchases with 422 `subscription_not_supported_ios`). Flip this single
/// switch back on when iOS subscriptions are built. Members who are already
/// Pro (e.g. bought on Android) keep their status and benefits everywhere.
bool proPurchaseAvailableFor(TargetPlatform platform) =>
    platform != TargetPlatform.iOS;

/// Central, overridable switch for every Pro purchase surface (plan cards,
/// buy/restore buttons, upsell CTAs, promo cards). Tests override it.
final proPurchaseAvailableProvider = Provider<bool>(
  (ref) => proPurchaseAvailableFor(defaultTargetPlatform),
);

/// [proPurchaseAvailableProvider] for code that only has a [BuildContext].
bool proPurchaseAvailable(BuildContext context) => ProviderScope.containerOf(
  context,
  listen: false,
).read(proPurchaseAvailableProvider);

/// Where an "upgrade" action leads: the Pro page where Pro can be bought,
/// the credit packs everywhere else.
Widget proUpgradeScreen({required bool available}) =>
    available ? const SubscriptionScreen() : const CreditPackagesScreen();

/// Pushes [proUpgradeScreen].
Future<void> openProUpgrade(BuildContext context) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => proUpgradeScreen(available: proPurchaseAvailable(context)),
  ),
);
