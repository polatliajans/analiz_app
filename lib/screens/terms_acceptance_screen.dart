import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/terms_acceptance_provider.dart';
import '../utils/platform_info.dart';
import '../widgets/legal_links_row.dart';

/// Shows [TermsAcceptanceScreen] until the current terms version is accepted,
/// then [child]. There is no way past it other than accepting.
class TermsGate extends ConsumerWidget {
  final Widget child;
  const TermsGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(termsAcceptedProvider) ? child : const TermsAcceptanceScreen();
}

/// Mandatory full-screen "clickwrap": plain-language summary, links to the
/// full Terms and Privacy Policy, a required checkbox and a Continue button
/// that stays disabled until it is ticked. Back closes the app on Android and
/// does nothing on iOS.
class TermsAcceptanceScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceScreen> createState() =>
      _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends ConsumerState<TermsAcceptanceScreen> {
  bool _checked = false;
  bool _busy = false;

  Future<void> _continue() async {
    if (!_checked || _busy) return;
    setState(() => _busy = true);
    await ref.read(termsAcceptedProvider.notifier).accept();
  }

  void _onBack(bool didPop, Object? result) {
    if (!didPop && !isIOS) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bullets = [
      l10n.termsGateBullet1,
      l10n.termsGateBullet2,
      l10n.termsGateBullet3,
      l10n.termsGateBullet4,
      l10n.termsGateBullet5,
      l10n.termsGateBullet6,
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                key: const Key('terms-gate'),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Icon(Icons.gavel_rounded, size: 40, color: scheme.primary),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.termsGateTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.termsGateIntro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < bullets.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == bullets.length - 1 ? 0 : 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bullets[i],
                                      key: Key('terms-bullet-${i + 1}'),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.termsGateLinksLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge,
                  ),
                  const LegalLinksRow(),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('terms-checkbox'),
                    value: _checked,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _checked = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.termsGateCheckbox,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('terms-continue'),
                    onPressed: _checked && !_busy ? _continue : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(l10n.continueButton),
                  ),
                  if (!_checked) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.termsGateContinueHint,
                      key: const Key('terms-hint'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
