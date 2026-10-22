import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ad_logic.dart';
import '../ads/banner_ad_slot.dart';
import '../l10n/app_localizations.dart';
import '../models/member.dart';
import '../providers/auth_prompt_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_tab_provider.dart';
import '../services/auth_failure.dart';
import '../services/delete_account_warnings.dart';
import '../widgets/email_verification_banner.dart';
import 'alarms_screen.dart';
import 'analysis_history_screen.dart';
import 'auth_screen.dart';
import 'credit_packages_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import 'watchlist_screen.dart';

/// Profile page. Works both when pushed and as a bottom-navigation tab.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = ref.read(authProvider.notifier);
    final promptDone = ref.read(authPromptDoneProvider.notifier);

    final warnings = deleteAccountWarnings(
      role: member.role,
      creditBalance: member.creditBalance,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteAccountDialog(warnings: warnings),
    );
    if (confirmed != true) return;

    try {
      await auth.deleteAccount();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
      return;
    }
    // Back to the root, then re-open the first-run sign-in screen.
    navigator.popUntil((route) => route.isFirst);
    await promptDone.reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final member = authState.isLoggedIn ? authState.member : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccount)),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (member == null)
                  _GuestCard(onTap: () => openAuthScreen(context))
                else ...[
                  _HeaderCard(member: member),
                  const SizedBox(height: 12),
                  _CreditCard(
                    member: member,
                    onBuy: () => _push(context, const CreditPackagesScreen()),
                    onUpgrade: () => _push(context, const SubscriptionScreen()),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (member != null) ...[
                        ListTile(
                          leading: const Icon(Icons.star_outline),
                          title: Text(l10n.myWatchlist),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _push(context, const WatchlistScreen()),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: Text(l10n.myAlerts),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _push(context, const AlarmsScreen()),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(l10n.analysisHistoryTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _push(context, const AnalysisHistoryScreen()),
                        ),
                        const Divider(height: 1),
                      ],
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(l10n.settings),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                      if (member != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout, color: scheme.error),
                          title: Text(
                            l10n.logOut,
                            style: TextStyle(color: scheme.error),
                          ),
                          onTap: () => ref.read(authProvider.notifier).logout(),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: scheme.error,
                          ),
                          title: Text(
                            l10n.deleteAccount,
                            style: TextStyle(color: scheme.error),
                          ),
                          onTap: () => _confirmDelete(context, ref, member),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const BannerAdSlot(
            placementKey: AdPlacementKeys.bannerProfile,
            tabIndex: profileTabIndex,
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Member member;
  const _HeaderCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = member.name?.trim() ?? '';
    final displayName = name.isNotEmpty ? name : member.email;
    final initial = displayName.isEmpty
        ? '?'
        : displayName.substring(0, 1).toUpperCase();
    final isPro = member.role == 'pro';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                initial,
                style: textTheme.headlineSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (name.isNotEmpty)
                    Text(
                      member.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          isPro
                              ? Icons.workspace_premium
                              : Icons.person_outline,
                          size: 16,
                        ),
                        label: Text(isPro ? l10n.rolePro : l10n.roleFree),
                        backgroundColor: isPro
                            ? scheme.tertiaryContainer
                            : scheme.surfaceContainerHighest,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            member.emailVerified
                                ? Icons.verified_outlined
                                : Icons.error_outline,
                            size: 16,
                            color: member.emailVerified
                                ? scheme.primary
                                : scheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.emailVerified
                                ? l10n.accountEmailVerified
                                : l10n.accountEmailNotVerified,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  final Member member;
  final VoidCallback onBuy;
  final VoidCallback onUpgrade;
  const _CreditCard({
    required this.member,
    required this.onBuy,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.toll_outlined, color: scheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.accountCreditBalance(member.creditBalance),
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onBuy,
                  icon: const Icon(Icons.add_card),
                  label: Text(l10n.buyCredits),
                ),
                if (member.role == 'free')
                  OutlinedButton.icon(
                    onPressed: onUpgrade,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: Text(l10n.upgradeToPro),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GuestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                size: 32,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.guestProfileHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onTap, child: Text(l10n.logInOrSignUp)),
          ],
        ),
      ),
    );
  }
}

const _playSubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

class _DeleteAccountDialog extends StatefulWidget {
  final DeleteAccountWarnings warnings;
  const _DeleteAccountDialog({required this.warnings});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _acknowledged = false;

  Future<void> _openPlay(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(_playSubscriptionsUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final w = widget.warnings;

    return AlertDialog(
      title: Text(l10n.deleteAccountConfirmTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountConfirmBody),
          if (w.showCredits) ...[
            const SizedBox(height: 12),
            Text(
              l10n.deleteAccountCreditsLost(w.credits),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.error,
              ),
            ),
          ],
          if (w.showProWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deleteAccountProNote,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openPlay(l10n),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.deleteAccountManageSubscription),
                  ),
                ],
              ),
            ),
          ],
          if (w.requiresAck) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acknowledged,
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
              title: Text(l10n.deleteAccountAckCheckbox),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: w.canDelete(acknowledged: _acknowledged)
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n.deleteAccountConfirmAction),
        ),
      ],
    );
  }
}
