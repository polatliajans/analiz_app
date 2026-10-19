import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../data/auth_api.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/notification_settings_section.dart';
import 'glossary_screen.dart';
import 'onboarding_screen.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _select(WidgetRef ref, Locale locale) async {
    await ref.read(localeProvider.notifier).confirm(locale);

    final token = ref.read(authProvider).token;
    if (token == null) return;
    try {
      await AuthApi().updateLocale(token, locale.languageCode);
    } catch (_) {
      // Best effort: the app language is already saved locally.
    }
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.couldNotOpenLink;
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDisclaimer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.financialDisclaimer),
        content: Text(l10n.financialDisclaimerText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(localeProvider).locale;
    final options = <(Locale, String)>[
      (const Locale('en'), l10n.languageNameEn),
      (const Locale('tr'), l10n.languageNameTr),
      (const Locale('es'), l10n.languageNameEs),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<Locale>(
            groupValue: selected,
            onChanged: (l) {
              if (l != null) _select(ref, l);
            },
            child: Column(
              children: [
                for (final (locale, name) in options)
                  RadioListTile<Locale>(value: locale, title: Text(name)),
              ],
            ),
          ),
          const Divider(),
          const NotificationSettingsSection(),
          ListTile(
            title: Text(l10n.replayIntro),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(replay: true),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.glossaryTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openGlossary(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.legalAboutSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(
              context,
              LegalLinks.page(LegalLinks.privacyPath, selected.languageCode),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(
              context,
              LegalLinks.page(LegalLinks.termsPath, selected.languageCode),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: Text(l10n.deleteAccountPage),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(
              context,
              LegalLinks.page(
                LegalLinks.deleteAccountPath,
                selected.languageCode,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: Text(l10n.support),
            subtitle: const Text(LegalLinks.supportEmail),
            onTap: () => _open(context, LegalLinks.supportMailto),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(l10n.financialDisclaimer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDisclaimer(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            subtitle: Text(
              ref
                  .watch(_packageInfoProvider)
                  .maybeWhen(
                    data: (p) => '${p.version} (${p.buildNumber})',
                    orElse: () => '',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
