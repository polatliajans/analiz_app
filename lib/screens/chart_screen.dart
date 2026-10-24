import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_analysis_flow.dart';
import '../ads/ad_analysis_messages.dart';
import '../ads/ads_controller.dart';
import '../data/ai_analysis_api.dart';
import '../data/plan_errors.dart';
import '../data/watchlist_api.dart';
import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../models/deep_analysis_job.dart';
import '../models/chart_signal.dart';
import '../models/structured_analysis.dart';
import '../providers/ad_analysis_provider.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/coin_overview_provider.dart';
import '../providers/deep_analysis_provider.dart';
import '../providers/live_chart_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../providers/watchlist_provider.dart';
import '../utils/feature_gate.dart';
import '../utils/timeframes.dart';
import '../widgets/analysis_card.dart';
import '../widgets/analysis_progress_overlay.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/chart_tabs/chart_tabs.dart';
import '../widgets/chart_tabs/tab_widgets.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _handlingDeepResult = false;

  /// Drives the sticky tab bar and the tab content below the chart.
  late final TabController _tabs = TabController(
    length: ChartTab.values.length,
    vsync: this,
  );

  /// Top of the page (header, timeframes, chart); signal taps scroll here.
  final _chartKey = GlobalKey();

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
    _tabs.dispose();
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
        cached: job.cached,
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
      await _presentQuickResult(
        result: r.result,
        creditCost: r.creditCost,
        structured: r.structured,
      );
    } catch (e) {
      if (!mounted) return;
      if (e is InsufficientCreditException) {
        final watchAd = await showInsufficientCreditDialog(context);
        if (watchAd && mounted) await _runAdAnalysis(coin);
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

  /// Shared result presentation of every quick analysis (credit- or
  /// ad-funded): history, balance, result sheet.
  Future<void> _presentQuickResult({
    required String result,
    required int creditCost,
    required StructuredAnalysis? structured,
    bool showInterstitial = true,
  }) async {
    await ref.read(authProvider.notifier).refreshMember();
    ref.invalidate(analysisHistoryProvider);
    final ads = ref.read(adsControllerProvider.notifier);
    await ads.recordSuccessfulAnalysis();
    if (!mounted) return;
    await showAnalysisSheet(
      context,
      result: result,
      creditCost: creditCost,
      structured: structured,
    );
    // Only after the user closed the result (never while waiting). No
    // interstitial after an analysis the member already paid for with an ad.
    if (!mounted || !showInterstitial) return;
    await ads.maybeShowInterstitial();
  }

  /// Quick analysis funded by one rewarded ad (Free members, insufficient
  /// credit): ad -> server verification -> analysis with `ad_session_id`.
  Future<void> _runAdAnalysis(Coin coin) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      showLoginRequiredSnackBar(context);
      return;
    }
    final gate = ref.read(featureGateProvider);
    final timeframe = gate.effectiveTimeframe(ref.read(timeframeProvider));
    if (gate.isTimeframeLocked(timeframe)) {
      showProUpsell(context, ProFeature.timeframe);
      return;
    }
    void Function()? closeOverlay;
    final flow = AdAnalysisFlow(
      api: ref.read(adAnalysisApiProvider),
      ads: AdsControllerAdService(ref.read(adsControllerProvider.notifier)),
      token: auth.token!,
      analyze: (sessionId) => AiAnalysisApi().requestAnalysis(
        token: auth.token!,
        coinId: coin.id,
        timeframe: timeframe,
        adSessionId: sessionId,
      ),
      onPhase: (phase) {
        // The progress overlay covers verification + the analysis request
        // (it cannot be shown over the full-screen ad itself).
        if (phase == AdFlowPhase.verifying && mounted) {
          closeOverlay = startAnalysisOverlay(context);
        }
      },
    );
    final AdFlowResult result;
    try {
      result = await flow.run();
    } finally {
      closeOverlay?.call();
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));

    switch (result.outcome) {
      case AdFlowOutcome.success:
        final r = result.analysis!;
        await _presentQuickResult(
          result: r.result,
          creditCost: r.creditCost,
          structured: null,
          showInterstitial: false,
        );
      case AdFlowOutcome.hasCredit:
        // Credit arrived in the meantime: just run the normal analysis.
        await ref.read(authProvider.notifier).refreshMember();
        if (mounted) await _requestAnalysis(coin);
      case AdFlowOutcome.cancelled:
        break;
      case AdFlowOutcome.failed:
        final e = result.error;
        if (e is InsufficientCreditException) {
          await showInsufficientCreditDialog(context);
        } else if (e is ProRequiredException) {
          ref.read(authProvider.notifier).refreshMember();
          ref.read(appConfigProvider.notifier).refresh();
          showProUpsell(context, ProFeature.timeframe);
        } else {
          say(l10n.analysisFailed('$e'));
        }
      default:
        final text = adFlowMessage(l10n, result.outcome);
        if (text != null) say(text);
        if (result.outcome == AdFlowOutcome.capReached ||
            result.outcome == AdFlowOutcome.notFree ||
            result.outcome == AdFlowOutcome.disabled) {
          ref.read(appConfigProvider.notifier).refresh();
        }
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
        // Deep analysis always costs credits: no ad option.
        showInsufficientCreditDialog(context, kind: AnalysisKind.deep);
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
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      280.0,
      420.0,
    );

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
      body: RefreshIndicator(
        onRefresh: () => _refreshPage(coin, params),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                key: _chartKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          selected: tf == timeframe,
                          onSelected: (_) => locked
                              ? showProUpsell(context, ProFeature.timeframe)
                              : ref.read(timeframeProvider.notifier).select(tf),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    key: const Key('chart-area'),
                    height: chartHeight,
                    child: _LiveChart(params: params),
                  ),
                  if (supportsSignals(timeframe) && gate.showStrongSignalsNote)
                    _buildStrongSignalsNote(l10n, textTheme),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnalysisButtons(context, l10n, coin, gate, deepBusy),
                    if (deepBusy) ...[
                      const SizedBox(height: 12),
                      const _DeepAnalysisWaitingCard(),
                    ],
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: ChartTabBarDelegate(
                controller: _tabs,
                labels: [
                  for (final t in ChartTab.values) chartTabLabel(l10n, t),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: ChartTabsContent(
                controller: _tabs,
                coin: coin,
                params: params,
                onSignalSelected: _revealChart,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 16 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh: reloads what the active tab shows.
  Future<void> _refreshPage(Coin coin, ChartDataParams params) async {
    switch (ChartTab.values[_tabs.index]) {
      case ChartTab.summary:
      case ChartTab.market:
        await ref
            .read(coinOverviewProvider(coin.id).notifier)
            .load(force: true);
      case ChartTab.analyses:
        if (ref.read(authProvider).isLoggedIn) {
          ref.invalidate(analysisHistoryProvider(coin.id));
          try {
            await ref.read(analysisHistoryProvider(coin.id).future);
          } catch (_) {}
        }
      case ChartTab.signals:
        ref.read(liveChartProvider(params).notifier).retry();
      case ChartTab.alerts:
        if (ref.read(authProvider).isLoggedIn) {
          ref.invalidate(priceAlertsProvider);
          try {
            await ref.read(priceAlertsProvider.future);
          } catch (_) {}
        }
    }
  }

  /// A signal row was tapped: bring the chart back into view.
  void _revealChart(ChartSignal signal) {
    final ctx = _chartKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// "Quick analysis - N credits" / "Deep analysis - N credits" buttons.
  Widget _buildAnalysisButtons(
    BuildContext context,
    AppLocalizations l10n,
    Coin coin,
    FeatureGate gate,
    bool deepBusy,
  ) {
    final plan = ref.watch(appConfigProvider.select((c) => c.plan));
    final large = isLargeText(context);
    const compact = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
    final quick = Semantics(
      label: l10n.quickAnalysisButtonCost(plan.quickAnalysisCost),
      excludeSemantics: true,
      button: true,
      child: ElevatedButton(
        key: const Key('quick-analysis-button'),
        style: compact,
        onPressed: () => _requestAnalysis(coin),
        child: _AnalysisButtonLabel(
          label: l10n.quickAnalysisShort,
          cost: plan.quickAnalysisCost,
          stacked: large,
        ),
      ),
    );
    final locked = !gate.canUseDeepAnalysis;
    final deep = Semantics(
      label: l10n.deepAnalysisButtonCost(plan.deepAnalysisCost),
      excludeSemantics: true,
      button: true,
      child: ElevatedButton(
        key: const Key('deep-analysis-button'),
        style: compact,
        onPressed: deepBusy ? null : () => _requestDeepAnalysis(coin),
        child: _AnalysisButtonLabel(
          label: l10n.deepAnalysisShort,
          cost: plan.deepAnalysisCost,
          stacked: large,
          locked: locked,
        ),
      ),
    );
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [quick, const SizedBox(height: 8), deep],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: quick),
          const SizedBox(width: 12),
          Expanded(child: deep),
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
        : trendColor(context, change >= 0 ? 1 : -1);
    final priceColor = live.direction == 0
        ? null
        : trendColor(context, live.direction > 0 ? 1 : -1);

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

/// Label of an analysis button: the (short) name and the credit cost in a
/// trailing pill. One line at normal text scale (scaled down if a language
/// is too long); wraps at large text scale.
class _AnalysisButtonLabel extends StatelessWidget {
  final String label;
  final int cost;
  final bool stacked;
  final bool locked;

  const _AnalysisButtonLabel({
    required this.label,
    required this.cost,
    required this.stacked,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = Container(
      key: const Key('analysis-cost-pill'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.toll_outlined, size: 13, color: scheme.primary),
          const SizedBox(width: 3),
          Text(
            '$cost',
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
    final text = Text(
      label,
      maxLines: stacked ? 2 : 1,
      softWrap: stacked,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final children = <Widget>[
      if (stacked) Flexible(child: text) else text,
      const SizedBox(width: 6),
      pill,
      if (locked) ...[const SizedBox(width: 4), const ProBadge()],
    ];
    final row = Row(mainAxisSize: MainAxisSize.min, children: children);
    return stacked ? row : FittedBox(fit: BoxFit.scaleDown, child: row);
  }
}
