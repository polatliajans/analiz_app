import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_failure.dart';

/// Shown while a logged-in member has not verified their email yet.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  bool _busy = false;

  /// Runs [action]; on success shows [doneMessage], or, when null, the
  /// "not verified yet" message if the member is still unverified.
  Future<void> _run(Future<void> Function() action, String? doneMessage) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      final message = doneMessage ?? _stillUnverifiedMessage(l10n);
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _stillUnverifiedMessage(AppLocalizations l10n) {
    final member = ref.read(authProvider).member;
    return member != null && !member.emailVerified
        ? l10n.emailNotVerifiedYet
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(authProvider.select((s) => s.member));
    if (member == null || member.emailVerified) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(authProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.verifyEmailBannerText,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () =>
                                  _run(notifier.refreshEmailVerification, null),
                        child: Text(l10n.iHaveVerified),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                notifier.resendVerification,
                                l10n.verificationEmailSent,
                              ),
                        child: Text(l10n.resendEmail),
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
