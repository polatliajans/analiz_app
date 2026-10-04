import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'onboarding_screen.dart';

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
          ListTile(
            title: Text(l10n.replayIntro),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(replay: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
