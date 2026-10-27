import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/platform_info.dart';

/// "Continue with Apple" button following Apple's HIG: solid black on light
/// themes, solid white on dark themes, Apple logo, same size as its siblings.
/// Renders nothing off iOS (Sign in with Apple is only offered on iOS) unless
/// [forceVisible] is set (tests).
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool forceVisible;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.forceVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!forceVisible && !isIOS) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Colors.white : Colors.black;
    final fg = dark ? Colors.black : Colors.white;
    return FilledButton.icon(
      key: const Key('apple-sign-in'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
        disabledForegroundColor: fg.withValues(alpha: 0.6),
      ),
      icon: const Icon(Icons.apple, size: 24),
      label: Text(AppLocalizations.of(context)!.continueWithApple),
    );
  }
}
