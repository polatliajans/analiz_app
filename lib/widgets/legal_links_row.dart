import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';

/// "Privacy Policy · Terms of Use" links (App Store requires both to be
/// reachable on the login and subscription screens).
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key});

  Future<void> _open(BuildContext context, String path) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context)!.couldNotOpenLink;
    final lang = Localizations.localeOf(context).languageCode;
    var ok = false;
    try {
      ok = await launchUrl(
        LegalLinks.page(path, lang),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LinkText(
          key: const Key('legal-privacy'),
          label: l10n.privacyPolicy,
          onTap: () => _open(context, LegalLinks.privacyPath),
        ),
        _LinkText(
          key: const Key('legal-terms'),
          label: l10n.termsOfUse,
          onTap: () => _open(context, LegalLinks.termsPath),
        ),
      ],
    );
  }
}

/// Underlined text link with a 48dp-high tap target.
class _LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkText({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
