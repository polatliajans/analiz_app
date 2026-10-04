import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_prompt_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_failure.dart';
import 'email_auth_screen.dart';

/// Opens the sign-in screen on top of the current route (no guest option).
Future<void> openAuthScreen(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AuthScreen(showGuest: false)));
}

/// Shows the "log in required" snackbar with a "Log in" action.
void showLoginRequiredSnackBar(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.mustLogIn),
      action: SnackBarAction(
        label: l10n.logIn,
        onPressed: () => navigator.push(
          MaterialPageRoute(builder: (_) => const AuthScreen(showGuest: false)),
        ),
      ),
    ),
  );
}

class AuthScreen extends ConsumerStatefulWidget {
  /// First-run flow: shows "Continue as guest". When false the screen was
  /// opened on top of another route and closes itself after signing in.
  final bool showGuest;

  const AuthScreen({super.key, this.showGuest = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
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
      if (!widget.showGuest) navigator.pop();
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
    if (!widget.showGuest) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loading = _busy || ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: widget.showGuest ? null : AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.authWelcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.authWelcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: loading ? null : _email,
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.continueWithEmail),
                ),
                if (widget.showGuest) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => ref
                              .read(authPromptDoneProvider.notifier)
                              .complete(),
                    child: Text(l10n.continueAsGuest),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
