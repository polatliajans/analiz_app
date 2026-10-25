import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_config.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_prompt_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_failure.dart';
import '../widgets/brand_page.dart';
import 'email_auth_screen.dart';

/// Opens the "What you can do after signing in" page. Every locked spot a
/// guest can tap leads here.
Future<void> openGuestBenefits(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const GuestBenefitsScreen()));
}

/// What a free account unlocks, built from the server's plan config (never
/// hard-coded numbers), with the two sign-in buttons pinned at the bottom.
class GuestBenefitsScreen extends ConsumerStatefulWidget {
  const GuestBenefitsScreen({super.key});

  @override
  ConsumerState<GuestBenefitsScreen> createState() =>
      _GuestBenefitsScreenState();
}

/// The benefits shown for [plan] (what a Free member really gets).
List<BrandBenefit> guestBenefitsFor(AppLocalizations l10n, PlanConfig plan) {
  final credits = plan.freeMonthlyCredits;
  final watchlistMax = plan.freeWatchlistMax;
  return [
    BrandBenefit(
      Icons.toll_rounded,
      credits == null
          ? l10n.gbCreditsTitleGeneric
          : l10n.gbCreditsTitle(credits),
      l10n.gbCreditsDesc,
    ),
    BrandBenefit(
      Icons.psychology_outlined,
      l10n.gbQuickTitle,
      l10n.gbQuickDesc(plan.quickAnalysisCost),
    ),
    if (!plan.deepAnalysisRequiresPro)
      BrandBenefit(
        Icons.query_stats_rounded,
        l10n.gbDeepTitle,
        l10n.gbDeepDesc,
      ),
    BrandBenefit(
      Icons.show_chart_rounded,
      l10n.gbSignalsTitle(plan.freeMaxSignalStrength),
      l10n.gbSignalsDesc,
    ),
    BrandBenefit(
      Icons.star_rounded,
      l10n.gbWatchlistTitle,
      watchlistMax == null
          ? l10n.gbWatchlistDescUnlimited
          : l10n.gbWatchlistDescLimit(watchlistMax),
    ),
    BrandBenefit(
      Icons.history_rounded,
      l10n.gbHistoryTitle,
      l10n.gbHistoryDesc,
    ),
    if (!plan.alertsRequirePro)
      BrandBenefit(
        Icons.notifications_active_rounded,
        l10n.gbAlertsTitle,
        l10n.gbAlertsDesc,
      ),
  ];
}

class _GuestBenefitsScreenState extends ConsumerState<GuestBenefitsScreen> {
  bool _busy = false;

  Future<void> _google() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final promptDone = ref.read(authPromptDoneProvider.notifier);
    final auth = ref.read(authProvider.notifier);
    setState(() => _busy = true);
    try {
      await auth.signInWithGoogle();
      await promptDone.complete();
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (e is AuthFailure && e.kind == AuthErrorKind.cancelled) return;
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _email() async {
    final promptDone = ref.read(authPromptDoneProvider.notifier);
    final navigator = Navigator.of(context);
    final success = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
    );
    if (success != true) return;
    await promptDone.complete();
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = ref.watch(appConfigProvider.select((c) => c.plan));
    final loading = _busy || ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.logIn)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                BrandHero(
                  icon: Icons.lock_open_rounded,
                  iconColor: Colors.white,
                  title: l10n.gbTitle,
                  tagline: l10n.gbHeroTagline,
                ),
                const SizedBox(height: 20),
                BrandSectionHeading(l10n.gbHeading),
                const SizedBox(height: 8),
                BrandBenefitsCard(
                  key: const Key('guest-benefits-list'),
                  benefits: guestBenefitsFor(l10n, plan),
                ),
                const SizedBox(height: 16),
                Container(
                  key: const Key('guest-pro-tease'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.gbProTease,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('guest-google'),
                      onPressed: loading ? null : _google,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(l10n.continueWithGoogle),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('guest-email'),
                      onPressed: loading ? null : _email,
                      icon: const Icon(Icons.email_outlined),
                      label: Text(l10n.continueWithEmail),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
