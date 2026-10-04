import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                l10n.chooseLanguage,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: RadioGroup<Locale>(
                  groupValue: selected,
                  onChanged: (l) {
                    if (l != null) ref.read(localeProvider.notifier).preview(l);
                  },
                  child: ListView(
                    children: [
                      for (final (locale, name) in options)
                        RadioListTile<Locale>(value: locale, title: Text(name)),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => ref
                    .read(localeProvider.notifier)
                    .confirm(ref.read(localeProvider).locale),
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
