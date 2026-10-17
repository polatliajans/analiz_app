import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_settings_api.dart';
import 'auth_provider.dart';

final notificationSettingsApiProvider = Provider<NotificationSettingsApi>(
  (ref) => NotificationSettingsApi(),
);

/// The signed-in member's notification preferences. `null` data for guests.
class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings?> {
  @override
  Future<NotificationSettings?> build() async {
    final token = ref.watch(authProvider.select((s) => s.token));
    if (token == null) return null;
    return ref.read(notificationSettingsApiProvider).fetch(token);
  }

  /// Optimistic update: the switch flips at once; on failure the previous
  /// value is restored and the error is rethrown for the UI to report.
  Future<void> setValue(String key, bool value) async {
    final token = ref.read(authProvider).token;
    final current = state.value;
    if (token == null || current == null) return;
    state = AsyncData(current.withValue(key, value));
    try {
      final saved = await ref
          .read(notificationSettingsApiProvider)
          .update(token, {key: value});
      // Keep any other switch the user flipped meanwhile.
      final latest = state.value ?? saved;
      // (state.value is never null here, but stay defensive.)
      state = AsyncData(
        NotificationSettings(
          values: {...latest.values, key: saved.isOn(key)},
          proOnly: saved.proOnly,
        ),
      );
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(latest.withValue(key, current.isOn(key)));
      rethrow;
    }
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings?>(
      NotificationSettingsNotifier.new,
    );
