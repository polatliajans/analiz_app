import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_plan_api.dart';
import '../data/subscription_purchase_api.dart';
import '../models/subscription_plan.dart';

final subscriptionPlanApiProvider = Provider<SubscriptionPlanApi>(
  (ref) => SubscriptionPlanApi(),
);
final subscriptionPurchaseApiProvider = Provider<SubscriptionPurchaseApi>(
  (ref) => SubscriptionPurchaseApi(),
);

final subscriptionPlanListProvider = FutureProvider<List<SubscriptionPlan>>((
  ref,
) async {
  return ref.read(subscriptionPlanApiProvider).fetchActivePlans();
});
