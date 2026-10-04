import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/analysis_history_provider.dart';
import '../widgets/analysis_card.dart';

/// All of the member's past analyses, newest first.
class AnalysisHistoryScreen extends ConsumerWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(analysisHistoryProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisHistoryTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorOccurred('$error'), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(analysisHistoryProvider(null)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(child: Text(l10n.analysisHistoryEmpty));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(analysisHistoryProvider(null).future),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: records.length,
              itemBuilder: (_, i) =>
                  AnalysisCard(record: records[i], showSymbol: true),
            ),
          );
        },
      ),
    );
  }
}
