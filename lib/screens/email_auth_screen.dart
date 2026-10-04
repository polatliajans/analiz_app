import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_failure.dart';

/// Email + password log in / sign up. Pops with `true` on success.
class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;

  bool get _isSignUp => _tabController.index == 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      _toast(authErrorMessage(l10n, AuthErrorKind.invalidEmail));
      return;
    }
    if (_isSignUp && password.length < 8) {
      _toast(l10n.passwordTooShort);
      return;
    }

    final auth = ref.read(authProvider.notifier);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final signUp = _isSignUp;
    setState(() => _busy = true);
    try {
      if (signUp) {
        await auth.registerWithEmail(email, password);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.verificationEmailSent)),
        );
      } else {
        await auth.signInWithEmail(email, password);
      }
      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _toast(authErrorMessage(l10n, AuthErrorKind.invalidEmail));
      return;
    }
    final auth = ref.read(authProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await auth.sendPasswordReset(email);
      messenger.showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.continueWithEmail),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.logIn),
            Tab(text: l10n.signUp),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? l10n.signUp : l10n.logIn),
            ),
            if (!_isSignUp)
              TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: Text(l10n.forgotPassword),
              ),
          ],
        ),
      ),
    );
  }
}
