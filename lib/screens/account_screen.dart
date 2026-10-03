import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: authState.isLoggedIn
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-posta: ${authState.member!.email}'),
                  Text('Rol: ${authState.member!.role == 'pro' ? 'Pro' : 'Ücretsiz'}'),
                  Text('Kredi Bakiyesi: ${authState.member!.creditBalance}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                    ),
                    child: const Text('Takip Listem'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreditPackagesScreen()),
                    ),
                    child: const Text('Kredi Satın Al'),
                  ),
                  if (authState.member!.role == 'free') ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      ),
                      child: const Text("Pro'ya Yükselt"),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: const Text('Çıkış Yap'),
                  ),
                ],
              )
            : Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Giriş Yap / Kayıt Ol'),
                ),
              ),
      ),
    );
  }
}
