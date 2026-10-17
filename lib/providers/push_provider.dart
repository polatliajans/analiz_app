import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_logic.dart';
import '../services/push_notification_service.dart';

/// A notification tap waiting to be applied once the app is ready.
class PendingNotificationTargetNotifier extends Notifier<NotificationTarget?> {
  @override
  NotificationTarget? build() => null;

  void set(NotificationTarget? target) => state = target;
}

final pendingNotificationTargetProvider =
    NotifierProvider<PendingNotificationTargetNotifier, NotificationTarget?>(
      PendingNotificationTargetNotifier.new,
    );

final pushServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    onTarget: (t) => ref.read(pendingNotificationTargetProvider.notifier).set(t),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Whether the system lets the app post notifications. Invalidate to re-check
/// (e.g. when returning from the system settings).
final notificationPermissionProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(pushServiceProvider).notificationsEnabled(),
);

const notificationPromptShownKey = 'notification_permission_prompt_shown';
