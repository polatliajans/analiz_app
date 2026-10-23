import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/coin_overview.dart';
import '../../providers/coin_overview_provider.dart';
import 'tab_widgets.dart';

/// Shared loading / error / stale handling of the tabs fed by the overview
/// endpoint (Summary, Market). Asks the provider for fresh data when the tab
/// is first shown (a no-op while the 3 minute client cache is valid).
class OverviewBody extends ConsumerStatefulWidget {
  final int coinId;
  final Widget Function(BuildContext context, CoinOverview overview) builder;

  const OverviewBody({super.key, required this.coinId, required this.builder});

  @override
  ConsumerState<OverviewBody> createState() => _OverviewBodyState();
}

class _OverviewBodyState extends ConsumerState<OverviewBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(coinOverviewProvider(widget.coinId).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coinOverviewProvider(widget.coinId));
    final notifier = ref.read(coinOverviewProvider(widget.coinId).notifier);
    if (state.isFatalError) return TabError(onRetry: notifier.retry);
    final data = state.data;
    if (data == null) return const TabSkeleton();
    final body = widget.builder(context, data);
    if (!state.isStale) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StaleNote(onRetry: notifier.retry),
        body,
      ],
    );
  }
}

class _StaleNote extends StatelessWidget {
  final VoidCallback onRetry;
  const _StaleNote({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      key: const Key('overview-stale'),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.tabLoadFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
