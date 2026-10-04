import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/member.dart';
import '../providers/auth_provider.dart';
import '../widgets/email_verification_banner.dart';
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
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
