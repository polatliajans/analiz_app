import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_analysis_api.dart';
import '../data/deep_analysis_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/email_verification_banner.dart';
import 'auth_screen.dart';
import 'coin_picker_sheet.dart';

const _timeframeMs = {
  '15m': 15 * 60 * 1000,
  '1h': 60 * 60 * 1000,
  '4h': 4 * 60 * 60 * 1000,
  '1d': 24 * 60 * 60 * 1000,
};

/// Home chart tab: shows the coin held by [selectedCoinProvider].
class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  bool _isRequestingAnalysis = false;
  bool _isRequestingDeepAnalysis = false;

  Future<void> _requestAnalysis(Coin coin) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }

    setState(() => _isRequestingAnalysis = true);
    try {
      final result = await AiAnalysisApi().requestAnalysis(
        token: auth.token!,
        coinId: coin.id,
        timeframe: ref.read(timeframeProvider),
      );
      await ref.read(authProvider.notifier).refreshMember();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.result),
              const SizedBox(height: 8),
              Text(
                l10n.creditsSpent(result.creditCost),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.analysisFailed('$e'))));
    } finally {
      if (mounted) setState(() => _isRequestingAnalysis = false);
    }
  }

  Future<void> _requestDeepAnalysis(Coin coin) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }

    setState(() => _isRequestingDeepAnalysis = true);
    try {
      final result = await DeepAnalysisApi().requestAnalysis(
        token: auth.token!,
        coinId: coin.id,
        timeframe: ref.read(timeframeProvider),
      );
      await ref.read(authProvider.notifier).refreshMember();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.result),
              const SizedBox(height: 8),
              Text(
                l10n.creditsSpent(result.creditCost),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deepAnalysisFailed('$e'))));
    } finally {
      if (mounted) setState(() => _isRequestingDeepAnalysis = false);
    }
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: chartTimeframes.map((tf) {
                  return ChoiceChip(
                    label: Text(tf),
                    selected: tf == timeframe,
                    onSelected: (_) =>
                        ref.read(timeframeProvider.notifier).select(tf),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
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
                timeframeMs: _timeframeMs[timeframe]!,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequestingAnalysis
                        ? null
                        : () => _requestAnalysis(coin),
                    child: _isRequestingAnalysis
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.quickAnalysisButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequestingDeepAnalysis
                        ? null
                        : () => _requestDeepAnalysis(coin),
                    child: _isRequestingDeepAnalysis
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.deepAnalysisButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistButton(
    BuildContext context,
    WidgetRef ref,
    Coin coin,
  ) {
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
