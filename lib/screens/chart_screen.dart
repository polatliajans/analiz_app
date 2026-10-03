import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_analysis_api.dart';
import '../data/deep_analysis_api.dart';
import '../models/coin.dart';
import '../providers/auth_provider.dart';
import '../providers/chart_data_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/candlestick_chart.dart';

const _timeframes = ['15m', '1h', '4h', '1d'];

const _timeframeMs = {
  '15m': 15 * 60 * 1000,
  '1h': 60 * 60 * 1000,
  '4h': 4 * 60 * 60 * 1000,
  '1d': 24 * 60 * 60 * 1000,
};

class ChartScreen extends ConsumerStatefulWidget {
  final Coin coin;

  const ChartScreen({super.key, required this.coin});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  String _selectedTimeframe = '1h';
  bool _isRequestingAnalysis = false;
  bool _isRequestingDeepAnalysis = false;

  Future<void> _requestAnalysis() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmalısın')),
      );
      return;
    }

    setState(() => _isRequestingAnalysis = true);
    try {
      final result = await AiAnalysisApi().requestAnalysis(
        token: auth.token!,
        coinId: widget.coin.id,
        timeframe: _selectedTimeframe,
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
                '${result.creditCost} kredi harcandı',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analiz alınamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRequestingAnalysis = false);
    }
  }

  Future<void> _requestDeepAnalysis() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmalısın')),
      );
      return;
    }

    setState(() => _isRequestingDeepAnalysis = true);
    try {
      final result = await DeepAnalysisApi().requestAnalysis(
        token: auth.token!,
        coinId: widget.coin.id,
        timeframe: _selectedTimeframe,
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
                '${result.creditCost} kredi harcandı',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Derin analiz alınamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRequestingDeepAnalysis = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = ChartDataParams(coin: widget.coin, timeframe: _selectedTimeframe);
    final chartDataAsync = ref.watch(chartDataProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coin.symbol),
        actions: [_buildWatchlistButton(context, ref)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: _timeframes.map((tf) {
                final selected = tf == _selectedTimeframe;
                return ChoiceChip(
                  label: Text(tf),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTimeframe = tf),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 340,
            child: chartDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bir hata oluştu: $error', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(chartDataProvider(params)),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (chartData) => CandlestickChart(
                candles: chartData.candles,
                signals: chartData.signals,
                timeframeMs: _timeframeMs[_selectedTimeframe]!,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequestingAnalysis ? null : _requestAnalysis,
                    child: _isRequestingAnalysis
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Analiz Yaptır'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequestingDeepAnalysis ? null : _requestDeepAnalysis,
                    child: _isRequestingDeepAnalysis
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Derin Analiz'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistButton(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final isFollowed = watchlistAsync.maybeWhen(
      data: (coins) => coins.any((c) => c.id == widget.coin.id),
      orElse: () => false,
    );

    return IconButton(
      icon: Icon(isFollowed ? Icons.star : Icons.star_border),
      onPressed: () async {
        if (!auth.isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giriş yapmalısın')),
          );
          return;
        }
        try {
          if (isFollowed) {
            await ref.read(watchlistApiProvider).unfollow(auth.token!, widget.coin.id);
          } else {
            await ref.read(watchlistApiProvider).follow(auth.token!, widget.coin.id);
          }
          ref.invalidate(watchlistProvider);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      },
    );
  }
}
