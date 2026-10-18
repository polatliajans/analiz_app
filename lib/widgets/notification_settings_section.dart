import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/push_provider.dart';
import 'pro_upsell_sheet.dart';

/// Settings -> Notifications. Hidden for guests.
class NotificationSettingsSection extends ConsumerStatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  ConsumerState<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends ConsumerState<NotificationSettingsSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check the permission after returning from the system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(String key, bool value) async {
    final failed = AppLocalizations.of(context)!.notifSettingsSaveFailed;
    try {
      await ref
          .read(notificationSettingsProvider.notifier)
          .setValue(key, value);
    } catch (_) {
      if (mounted) _snack(failed);
    }
  }

  Future<void> _openSystemSettings() async {
    final manual = AppLocalizations.of(context)!.notifPermissionManual;
    final service = ref.read(pushServiceProvider);
    if (await service.openSystemNotificationSettings()) return;
    // Fallback: ask again (a no-op once the system stopped asking) and tell
    // the member where to switch it on.
    await service.requestPermission();
    ref.invalidate(notificationPermissionProvider);
    if (mounted) _snack(manual);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));
    if (!loggedIn) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(isProProvider);
    final settings = ref.watch(notificationSettingsProvider);
    final permission = ref.watch(notificationPermissionProvider);
    final scheme = Theme.of(context).colorScheme;

    final rows = <(String, String, String, ProFeature)>[
      (
        'announcements',
        l10n.notifAnnouncementsTitle,
        l10n.notifAnnouncementsSubtitle,
        ProFeature.generic,
      ),
      (
        'credits',
        l10n.notifCreditsTitle,
        l10n.notifCreditsSubtitle,
        ProFeature.generic,
      ),
      (
        'signals',
        l10n.notifSignalsTitle,
        l10n.notifSignalsSubtitle,
        ProFeature.pushSignals,
      ),
      (
        'alerts',
        l10n.notifAlertsTitle,
        l10n.notifAlertsSubtitle,
        ProFeature.priceAlert,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.notifSettingsSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (permission.value == false)
          ListTile(
            leading: Icon(
              Icons.notifications_off_outlined,
              color: scheme.error,
            ),
            title: Text(l10n.notifPermissionOffTitle),
            subtitle: Text(l10n.notifPermissionOffBody),
            trailing: TextButton(
              onPressed: _openSystemSettings,
              child: Text(l10n.notifOpenSystemSettings),
            ),
          ),
        settings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(l10n.notifSettingsLoadFailed),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(notificationSettingsProvider),
            ),
          ),
          data: (data) {
            if (data == null) return const SizedBox.shrink();
            return Column(
              children: [
                for (final (key, title, subtitle, feature) in rows)
                  _row(
                    key: key,
                    title: title,
                    subtitle: subtitle,
                    feature: feature,
                    value: data.isOn(key),
                    locked: data.isProOnly(key) && !isPro,
                  ),
              ],
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _row({
    required String key,
    required String title,
    required String subtitle,
    required ProFeature feature,
    required bool value,
    required bool locked,
  }) {
    final titleWidget = Row(
      children: [
        Flexible(child: Text(title)),
        if (locked) ...[const SizedBox(width: 6), const ProBadge()],
      ],
    );
    return SwitchListTile(
      title: titleWidget,
      subtitle: Text(subtitle),
      // Locked rows look off and open the Pro upsell instead of toggling.
      value: locked ? false : value,
      onChanged: locked
          ? (_) => showProUpsell(context, feature)
          : (v) => _toggle(key, v),
    );
  }
}
