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
        TextButton(
          key: const Key('legal-privacy'),
          onPressed: () => _open(context, LegalLinks.privacyPath),
          child: Text(l10n.privacyPolicy),
        ),
        TextButton(
          key: const Key('legal-terms'),
          onPressed: () => _open(context, LegalLinks.termsPath),
          child: Text(l10n.termsOfUse),
        ),
      ],
    );
  }
}
