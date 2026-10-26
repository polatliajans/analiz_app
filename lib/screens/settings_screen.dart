import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/privacy_options.dart';
import '../config/legal_links.dart';
import '../data/auth_api.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/startup_tab_provider.dart';
import '../providers/theme_provider.dart';
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

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    List<(Locale, String)> options,
    Locale selected,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<Locale>(
            groupValue: Locale(selected.languageCode),
            onChanged: (l) {
              if (l == null) return;
              Navigator.of(ctx).pop();
              _select(ref, l);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (locale, name) in options)
                  RadioListTile<Locale>(value: locale, title: Text(name)),
              ],
            ),
          ),
        ),
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
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              options
                  .firstWhere(
                    (o) => o.$1.languageCode == selected.languageCode,
                    orElse: () => options.first,
                  )
                  .$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref, options, selected),
          ),
          const Divider(height: 1),
          _SegmentedSetting<ThemeMode>(
            title: l10n.themeTitle,
            selected: ref.watch(themeModeProvider),
            onChanged: (v) => ref.read(themeModeProvider.notifier).select(v),
            options: [
              (ThemeMode.dark, Icons.dark_mode_outlined, l10n.themeDark),
              (ThemeMode.light, Icons.light_mode_outlined, l10n.themeLight),
              (
                ThemeMode.system,
                Icons.brightness_auto_outlined,
                l10n.themeSystem,
              ),
            ],
          ),
          _SegmentedSetting<StartupTab>(
            title: l10n.startupPageTitle,
            selected: ref.watch(startupTabProvider),
            onChanged: (v) => ref.read(startupTabProvider.notifier).select(v),
            options: [
              (StartupTab.home, Icons.home_outlined, l10n.tabHome),
              (
                StartupTab.chart,
                Icons.candlestick_chart_outlined,
                l10n.tabChart,
              ),
            ],
          ),
          const Divider(height: 1),
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
          if (ref.watch(privacyOptionsRequiredProvider).value ?? false)
            ListTile(
              leading: const Icon(Icons.ads_click_outlined),
              title: Text(l10n.adPrivacyOptions),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ref.read(privacyOptionsProvider).show(),
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
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l10n.crashReportingTitle),
            subtitle: Text(l10n.crashReportingNote),
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

class _SegmentedSetting<T> extends StatelessWidget {
  const _SegmentedSetting({
    required this.title,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  final String title;
  final T selected;
  final ValueChanged<T> onChanged;
  final List<(T, IconData, String)> options;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final (value, icon, label) in options)
                  ButtonSegment<T>(
                    value: value,
                    icon: Icon(icon, size: 18),
                    label: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}
