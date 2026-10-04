import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/analysis_record.dart';

String formatAnalysisDate(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(dt.toLocal());
}

/// Shows the full text of an analysis in a bottom sheet.
void showAnalysisSheet(
  BuildContext context, {
  required String result,
  required int creditCost,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result),
            const SizedBox(height: 8),
            Text(
              l10n.creditsSpent(creditCost),
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Compact card for a past analysis; tap opens the full text.
class AnalysisCard extends StatelessWidget {
  final AnalysisRecord record;
  final bool showSymbol;

  const AnalysisCard({
    super.key,
    required this.record,
    this.showSymbol = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAnalysisSheet(
          context,
          result: record.result,
          creditCost: record.creditCost,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: record.isDeep
                          ? scheme.tertiaryContainer
                          : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record.isDeep
                          ? l10n.analysisTypeDeep
                          : l10n.analysisTypeQuick,
                      style: textTheme.labelSmall,
                    ),
                  ),
                  if (showSymbol) ...[
                    const SizedBox(width: 8),
                    Text(record.symbol, style: textTheme.labelLarge),
                  ],
                  if (record.timeframe != null) ...[
                    const SizedBox(width: 8),
                    Text(record.timeframe!, style: textTheme.labelMedium),
                  ],
                  const Spacer(),
                  Text(
                    formatAnalysisDate(context, record.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.result,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
