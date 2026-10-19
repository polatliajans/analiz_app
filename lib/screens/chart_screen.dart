import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads_controller.dart';
import '../data/ai_analysis_api.dart';
import '../data/plan_errors.dart';
import '../data/watchlist_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../models/deep_analysis_job.dart';
import '../models/structured_analysis.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/deep_analysis_provider.dart';
import '../providers/live_chart_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/timeframes.dart';
import '../widgets/analysis_card.dart';
import '../widgets/analysis_progress_overlay.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/email_verification_banner.dart';
import '../widgets/insufficient_credit_dialog.dart';
import '../widgets/pro_upsell_sheet.dart';
import 'auth_screen.dart';
import 'coin_picker_sheet.dart';
import 'price_alert_sheet.dart';

/// Home chart tab: shows the coin held by [selectedCoinProvider].
class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen>
    with WidgetsBindingObserver {
  bool _handlingDeepResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Picks up a job that was running when the screen/app was left.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(deepAnalysisProvider.notifier).resume();
      _handleDeepState(ref.read(deepAnalysisProvider));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(deepAnalysisProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.resume();
    } else if (state == AppLifecycleState.paused) {
      notifier.pause();
    }
  }

  void _handleDeepState(DeepAnalysisState s) {
    if (!mounted || _handlingDeepResult) return;
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(deepAnalysisProvider.notifier);
    void say(String text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      notifier.acknowledge();
    }

    switch (s.phase) {
      case DeepAnalysisPhase.completed:
        _showDeepResult(s.job!);
      case DeepAnalysisPhase.failed:
        say(l10n.deepAnalysisFailedRefunded);
      case DeepAnalysisPhase.timedOut:
        say(l10n.deepAnalysisStillRunning);
      case DeepAnalysisPhase.networkLost:
        say(l10n.deepAnalysisCheckLater);
      case DeepAnalysisPhase.error:
        say(s.message ?? l10n.deepAnalysisCheckLater);
      case DeepAnalysisPhase.waiting:
      case DeepAnalysisPhase.idle:
      case DeepAnalysisPhase.starting:
        break;
    }
  }

  Future<void> _showDeepResult(DeepAnalysisJob job) async {
    final analysis = job.analysis;
    final notifier = ref.read(deepAnalysisProvider.notifier);
    if (analysis == null) {
      notifier.acknowledge();
      return;
    }
    _handlingDeepResult = true;
    try {
      await ref.read(authProvider.notifier).refreshMember();
      ref.invalidate(analysisHistoryProvider);
      final ads = ref.read(adsControllerProvider.notifier);
      await ads.recordSuccessfulAnalysis();
      if (!mounted) return;
      notifier.acknowledge();
      await showAnalysisSheet(
        context,
        result: analysis.result,
        creditCost: analysis.creditCost,
        structured: analysis.structured,
        generatedAt: analysis.generatedAt,
      );
      if (!mounted) return;
      await ads.maybeShowInterstitial();
    } finally {
      _handlingDeepResult = false;
    }
  }

  Future<void> _runAnalysis(
    Coin coin, {
    required Future<
      ({String result, int creditCost, StructuredAnalysis? structured})
    >
    Function(String token, String timeframe)
    request,
    required String Function(AppLocalizations l10n, String details)
    failureMessage,
    required ProFeature proFeature,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }

    final gate = ref.read(featureGateProvider);
    final timeframe = gate.effectiveTimeframe(ref.read(timeframeProvider));
    // Locked analyses never reach the server.
    if (proFeature == ProFeature.deepAnalysis && !gate.canUseDeepAnalysis) {
      showProUpsell(context, ProFeature.deepAnalysis);
      return;
    }
    if (gate.isTimeframeLocked(timeframe)) {
      showProUpsell(context, ProFeature.timeframe);
      return;
    }
    try {
      final r = await runWithAnalysisOverlay(
        context,
        () => request(auth.token!, timeframe),
      );
      await ref.read(authProvider.notifier).refreshMember();
      ref.invalidate(analysisHistoryProvider);
      final ads = ref.read(adsControllerProvider.notifier);
      await ads.recordSuccessfulAnalysis();
      if (!mounted) return;
      await showAnalysisSheet(
        context,
        result: r.result,
        creditCost: r.creditCost,
        structured: r.structured,
      );
      // Only after the user closed the result (never while waiting).
      if (!mounted) return;
      await ads.maybeShowInterstitial();
    } catch (e) {
      if (!mounted) return;
      if (e is InsufficientCreditException) {
        showInsufficientCreditDialog(context);
        return;
      }
      if (e is ProRequiredException) {
        // The server's view of the plan wins: resync, then explain.
        ref.read(authProvider.notifier).refreshMember();
        ref.read(appConfigProvider.notifier).refresh();
        showProUpsell(context, proFeature);
        return;
      }
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
      return (result: r.result, creditCost: r.creditCost, structured: null);
    },
    failureMessage: (l10n, d) => l10n.analysisFailed(d),
    proFeature: ProFeature.timeframe,
  );

  Future<void> _requestDeepAnalysis(Coin coin) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }
    if (ref.read(deepAnalysisProvider).isBusy) return;
    final gate = ref.read(featureGateProvider);
    final timeframe = gate.effectiveTimeframe(ref.read(timeframeProvider));
    // Locked analyses never reach the server.
    if (!gate.canUseDeepAnalysis) {
      showProUpsell(context, ProFeature.deepAnalysis);
      return;
    }
    if (gate.isTimeframeLocked(timeframe)) {
      showProUpsell(context, ProFeature.timeframe);
      return;
    }
    try {
      await ref
          .read(deepAnalysisProvider.notifier)
          .start(coinId: coin.id, timeframe: timeframe);
    } catch (e) {
      if (!mounted) return;
      if (e is InsufficientCreditException) {
        showInsufficientCreditDialog(context);
        return;
      }
      if (e is ProRequiredException) {
        // The server's view of the plan wins: resync, then explain.
        ref.read(authProvider.notifier).refreshMember();
        ref.read(appConfigProvider.notifier).refresh();
        showProUpsell(context, ProFeature.deepAnalysis);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deepAnalysisFailed('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(deepAnalysisProvider, (prev, next) {
      if (next.phase == DeepAnalysisPhase.waiting &&
          next.message != null &&
          prev?.message != next.message) {
        // 409: an analysis is already running; we resumed polling it.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message!)));
      }
      if (prev?.phase != next.phase) _handleDeepState(next);
    });
    ref.listen(authProvider, (prev, next) {
      if (!(prev?.isLoggedIn ?? false) && next.isLoggedIn) {
        ref.read(deepAnalysisProvider.notifier).resume();
      }
    });
    final deepBusy = ref.watch(deepAnalysisProvider).isBusy;
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

    final gate = ref.watch(featureGateProvider);
    final timeframe = gate.effectiveTimeframe(ref.watch(timeframeProvider));
    final params = ChartDataParams(coin: coin, timeframe: timeframe);
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
        actions: [
          _buildAlertButton(context, ref, coin, params),
          _buildWatchlistButton(context, ref, coin),
        ],
      ),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _LiveHeader(params: params, coin: coin),
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
                final locked = gate.isTimeframeLocked(tf);
                return ChoiceChip(
                  label: Text(tf),
                  avatar: locked
                      ? const Icon(Icons.lock_outline, size: 14)
                      : null,
                  labelStyle: textTheme.labelMedium,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  selected: tf == timeframe,
                  onSelected: (_) => locked
                      ? showProUpsell(context, ProFeature.timeframe)
                      : ref.read(timeframeProvider.notifier).select(tf),
                );
              },
            ),
          ),
          Expanded(flex: 5, child: _LiveChart(params: params)),
          if (supportsSignals(timeframe) && gate.showStrongSignalsNote)
            _buildStrongSignalsNote(l10n, textTheme),
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
                        onPressed: deepBusy ? null : () => _requestDeepAnalysis(coin),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!gate.canUseDeepAnalysis) ...[
                              const Icon(Icons.lock_outline, size: 16),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                l10n.deepAnalysisButton,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!gate.canUseDeepAnalysis) ...[
                              const SizedBox(width: 6),
                              const ProBadge(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (deepBusy) ...[
                  const SizedBox(height: 12),
                  const _DeepAnalysisWaitingCard(),
                ],
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

  Widget _buildStrongSignalsNote(AppLocalizations l10n, TextTheme textTheme) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: () => showProUpsell(context, ProFeature.strongSignals),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 12, color: muted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.strongSignalsProNote,
                style: textTheme.labelSmall?.copyWith(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

  Widget _buildAlertButton(
    BuildContext context,
    WidgetRef ref,
    Coin coin,
    ChartDataParams params,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hasActive = ref.watch(
      priceAlertsProvider.select(
        (a) => a.value?.activeForCoin(coin.id).isNotEmpty ?? false,
      ),
    );
    return IconButton(
      tooltip: l10n.alertTooltip,
      icon: Icon(hasActive ? Icons.notifications : Icons.notifications_none),
      onPressed: () =>
          openPriceAlertFlow(context, ref, coin: coin, params: params),
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
        final gate = ref.read(featureGateProvider);
        final count = watchlistAsync.value?.length ?? 0;
        if (!isFollowed && gate.watchlistLimitReached(count)) {
          showProUpsell(
            context,
            ProFeature.watchlistLimit,
            count: count,
            limit: gate.watchlistLimit,
          );
          return;
        }
        try {
          if (isFollowed) {
            await ref.read(watchlistApiProvider).unfollow(auth.token!, coin.id);
          } else {
            await ref.read(watchlistApiProvider).follow(auth.token!, coin.id);
          }
          ref.invalidate(watchlistProvider);
        } on WatchlistLimitException catch (e) {
          if (!context.mounted) return;
          ref.read(appConfigProvider.notifier).refresh();
          showProUpsell(
            context,
            ProFeature.watchlistLimit,
            count: e.limit ?? count,
            limit: e.limit,
          );
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

/// Price and 24h change line; rebuilds on live updates without touching the
/// rest of the screen.
class _LiveHeader extends ConsumerWidget {
  final ChartDataParams params;
  final Coin coin;

  const _LiveHeader({required this.params, required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveChartProvider(params));
    final textTheme = Theme.of(context).textTheme;
    final price = live.price ?? coin.lastPrice;
    final change = live.change24h ?? coin.priceChangePercent24h;
    final changeColor = change == null
        ? null
        : (change >= 0 ? Colors.green : Colors.red);
    final priceColor = live.direction > 0
        ? Colors.green
        : (live.direction < 0 ? Colors.red : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          price != null ? price.toString() : '-',
          style: textTheme.titleLarge?.copyWith(color: priceColor),
        ),
        const SizedBox(width: 12),
        Text(
          change != null
              ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'
              : '-',
          style: textTheme.titleSmall?.copyWith(color: changeColor),
        ),
      ],
    );
  }
}

/// The candlestick chart fed by the live controller.
class _LiveChart extends ConsumerWidget {
  final ChartDataParams params;

  const _LiveChart({required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final live = ref.watch(liveChartProvider(params));

    if (live.candles.isEmpty) {
      if (live.error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.errorOccurred('${live.error}'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(liveChartProvider(params).notifier).retry(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      }
      if (live.loading) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    return CandlestickChart(
      candles: live.candles,
      signals: ref.watch(featureGateProvider).visibleSignals(live.signals),
      timeframeMs: timeframeMs[params.timeframe]!,
    );
  }
}

/// Inline, non-blocking status shown while a deep analysis runs in the
/// background; the user can leave the screen.
class _DeepAnalysisWaitingCard extends StatelessWidget {
  const _DeepAnalysisWaitingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.deepAnalysisWaitingTitle,
                    style: textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              l10n.deepAnalysisWaitingBody,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
