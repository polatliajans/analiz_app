import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/analysis_record.dart';
import '../../models/coin.dart';
import '../../providers/analysis_history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coin_overview_provider.dart';
import '../../screens/auth_screen.dart';
import '../../utils/overview_format.dart';
import '../../utils/structured_analysis_logic.dart';
import '../analysis_card.dart';
import '../structured_analysis_view.dart';
import 'tab_widgets.dart';

/// Only this coin's records. The server filters by `coin_id`; this also
/// covers a server that ignores the filter and returns the whole history.
List<AnalysisRecord> recordsForCoin(List<AnalysisRecord> all, int coinId) => [
  for (final r in all)
    if (r.coinId == coinId) r,
];

/// One-line description of a record: the structured summary when present,
/// else the first non-empty line of the text.
String recordSummaryLine(AnalysisRecord r) {
  final s = r.structured?.summary;
  if (s != null && s.trim().isNotEmpty) return s.trim();
  for (final line in r.result.split('\n')) {
    final t = line.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

/// "Analizlerim": the signed-in member's analyses of [coin].
class AnalysesTab extends ConsumerWidget {
  final Coin coin;
  const AnalysesTab({super.key, required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final loggedIn = ref.watch(authProvider.select((s) => s.isLoggedIn));
    if (!loggedIn) {
      return TabMessage(
        icon: Icons.lock_outline,
        title: l10n.coAnalysesLoginHint,
        action: FilledButton(
          onPressed: () => openAuthScreen(context),
          child: Text(l10n.logIn),
        ),
      );
    }
    final async = ref.watch(analysisHistoryProvider(coin.id));
    final records = async.value;
    if (records == null) {
      if (async.hasError) {
        return TabError(
          onRetry: () => ref.invalidate(analysisHistoryProvider(coin.id)),
        );
      }
      return const TabSkeleton();
    }
    final mine = recordsForCoin(records, coin.id);
    if (mine.isEmpty) {
      return TabMessage(
        icon: Icons.psychology_alt_outlined,
        title: l10n.coAnalysesEmptyTitle,
        body: l10n.coAnalysesEmptyBody,
      );
    }
    final now = ref.watch(overviewClockProvider)();
    return TabPadding(
      children: [for (final r in mine) CoinAnalysisTile(record: r, now: now)],
    );
  }
}

class CoinAnalysisTile extends StatelessWidget {
  final AnalysisRecord record;
  final DateTime now;
  const CoinAnalysisTile({super.key, required this.record, required this.now});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = recordSummaryLine(record);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAnalysisSheet(
          context,
          result: record.result,
          creditCost: record.creditCost,
          structured: record.structured,
          cached: record.cached,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Pill(
                    text: record.isDeep
                        ? l10n.analysisTypeDeep
                        : l10n.analysisTypeQuick,
                    color: record.isDeep ? scheme.tertiary : scheme.secondary,
                  ),
                  if (record.timeframe != null) ...[
                    const SizedBox(width: 8),
                    Text(record.timeframe!, style: textTheme.labelMedium),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relativeAgo(l10n, record.createdAt, now),
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (showsBiasBadge(record) || record.cached) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (showsBiasBadge(record))
                      BiasBadge(
                        bias: record.structured!.bias!,
                        confidence: record.structured!.confidence,
                        compact: true,
                      ),
                    if (record.cached)
                      Pill(
                        key: const Key('analysis-cached'),
                        text: l10n.coAnalysisCached,
                        icon: Icons.bolt_outlined,
                      ),
                  ],
                ),
              ],
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
