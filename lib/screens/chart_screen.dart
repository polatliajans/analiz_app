import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_analysis_api.dart';
import '../data/deep_analysis_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/timeframes.dart';
import '../widgets/analysis_card.dart';
import '../widgets/analysis_progress_overlay.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/email_verification_banner.dart';
import 'auth_screen.dart';
import 'coin_picker_sheet.dart';

/// Home chart tab: shows the coin held by [selectedCoinProvider].
class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  Future<void> _runAnalysis(
    Coin coin, {
    required Future<({String result, int creditCost})> Function(
      String token,
      String timeframe,
    )
    request,
    required String Function(AppLocalizations l10n, String details)
    failureMessage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }

    final timeframe = ref.read(timeframeProvider);
    try {
      final r = await runWithAnalysisOverlay(
        context,
        () => request(auth.token!, timeframe),
      );
      await ref.read(authProvider.notifier).refreshMember();
      ref.invalidate(analysisHistoryProvider);
      if (!mounted) return;
      showAnalysisSheet(context, result: r.result, creditCost: r.creditCost);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureMessage(l10n, '$e'))));
    }
  }

  Future<void> _requestAnalysis(Coin coin) => _runAnalysis(
    coin,
    request: (token, timeframe) async {
      final r = await AiAnalysisApi().requestAnalysis(
        token: token,
        coinId: coin.id,
        timeframe: timeframe,
      );
      return (result: r.result, creditCost: r.creditCost);
    },
    failureMessage: (l10n, d) => l10n.analysisFailed(d),
  );

  Future<void> _requestDeepAnalysis(Coin coin) => _runAnalysis(
    coin,
    request: (token, timeframe) async {
      final r = await DeepAnalysisApi().requestAnalysis(
        token: token,
        coinId: coin.id,
        timeframe: timeframe,
      );
      return (result: r.result, creditCost: r.creditCost);
    },
    failureMessage: (l10n, d) => l10n.deepAnalysisFailed(d),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coinAsync = ref.watch(selectedCoinProvider);
    final coin = coinAsync.value;

    if (coin == null) {
      return Scaffold(
        appBar: AppBar(),
        body: coinAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      coinAsync.hasError
                          ? l10n.errorOccurred('${coinAsync.error}')
                          : l10n.noCoinsFound,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(selectedCoinProvider),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
      );
    }

    final timeframe = ref.watch(timeframeProvider);
    final params = ChartDataParams(coin: coin, timeframe: timeframe);
    final chartDataAsync = ref.watch(chartDataProvider(params));
    final lastClose = chartDataAsync.maybeWhen(
      data: (d) => d.candles.isEmpty ? null : d.candles.last.close,
      orElse: () => null,
    );
    final price = lastClose ?? coin.lastPrice;
    final change = coin.priceChangePercent24h;
    final changeColor = change == null
        ? null
        : (change >= 0 ? Colors.green : Colors.red);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showCoinPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(coin.symbol, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    coin.marketType == 'futures' ? 'Futures' : 'Spot',
                    style: textTheme.labelSmall,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [_buildWatchlistButton(context, ref, coin)],
      ),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price != null ? price.toString() : '-',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(width: 12),
                Text(
                  change != null
                      ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'
                      : '-',
                  style: textTheme.titleSmall?.copyWith(color: changeColor),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: chartTimeframes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final tf = chartTimeframes[i];
                return ChoiceChip(
                  label: Text(tf),
                  labelStyle: textTheme.labelMedium,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  selected: tf == timeframe,
                  onSelected: (_) =>
                      ref.read(timeframeProvider.notifier).select(tf),
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: chartDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.errorOccurred('$error'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(chartDataProvider(params)),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (chartData) => CandlestickChart(
                candles: chartData.candles,
                signals: chartData.signals,
                timeframeMs: timeframeMs[timeframe]!,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _requestAnalysis(coin),
                        child: Text(l10n.quickAnalysisButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _requestDeepAnalysis(coin),
                        child: Text(l10n.deepAnalysisButton),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.analysisHistorySection, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                ..._historyItems(context, l10n, coin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historyItems(
    BuildContext context,
    AppLocalizations l10n,
    Coin coin,
  ) {
    final auth = ref.watch(authProvider);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget hint(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: muted)),
    );

    if (!auth.isLoggedIn) return [hint(l10n.analysisHistoryLoginHint)];

    final async = ref.watch(analysisHistoryProvider(coin.id));
    return async.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [hint(l10n.errorOccurred('$e'))],
      data: (records) => records.isEmpty
          ? [hint(l10n.analysisHistoryEmpty)]
          : [for (final r in records) AnalysisCard(record: r)],
    );
  }

  Widget _buildWatchlistButton(BuildContext context, WidgetRef ref, Coin coin) {
    final auth = ref.watch(authProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final isFollowed = watchlistAsync.maybeWhen(
      data: (coins) => coins.any((c) => c.id == coin.id),
      orElse: () => false,
    );

    return IconButton(
      icon: Icon(isFollowed ? Icons.star : Icons.star_border),
      onPressed: () async {
        if (!auth.isLoggedIn) {
          showLoginRequiredSnackBar(context);
          return;
        }
        try {
          if (isFollowed) {
            await ref.read(watchlistApiProvider).unfollow(auth.token!, coin.id);
          } else {
            await ref.read(watchlistApiProvider).follow(auth.token!, coin.id);
          }
          ref.invalidate(watchlistProvider);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$e')));
        }
      },
    );
  }
}
