import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import 'credit_packages_screen.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'watchlist_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAccount)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: authState.isLoggedIn
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.accountEmail(authState.member!.email)),
                  Text(
                    l10n.accountRole(
                      authState.member!.role == 'pro'
                          ? l10n.rolePro
                          : l10n.roleFree,
                    ),
                  ),
                  Text(
                    l10n.accountCreditBalance(authState.member!.creditBalance),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WatchlistScreen(),
                      ),
                    ),
                    child: Text(l10n.myWatchlist),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreditPackagesScreen(),
                      ),
                    ),
                    child: Text(l10n.buyCredits),
                  ),
                  if (authState.member!.role == 'free') ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      ),
                      child: Text(l10n.upgradeToPro),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: Text(l10n.logOut),
                  ),
                ],
              )
            : Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(l10n.logInOrSignUp),
                ),
              ),
      ),
    );
  }
}
