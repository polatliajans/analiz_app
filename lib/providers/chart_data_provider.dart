import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/binance_klines_api.dart';
import '../data/chart_signal_api.dart';
import '../models/candle.dart';
import '../models/chart_signal.dart';
import '../models/coin.dart';

class ChartData {
  final List<Candle> candles;
  final List<ChartSignal> signals;

  const ChartData({required this.candles, required this.signals});
}

class ChartDataParams {
  final Coin coin;
  final String timeframe;

  const ChartDataParams({required this.coin, required this.timeframe});

  @override
  bool operator ==(Object other) =>
      other is ChartDataParams &&
      other.coin.id == coin.id &&
      other.timeframe == timeframe;

  @override
  int get hashCode => Object.hash(coin.id, timeframe);
}

final binanceKlinesApiProvider = Provider<BinanceKlinesApi>(
  (ref) => BinanceKlinesApi(),
);
final chartSignalApiProvider = Provider<ChartSignalApi>(
  (ref) => ChartSignalApi(),
);

final chartDataProvider = FutureProvider.family<ChartData, ChartDataParams>((
  ref,
  params,
) async {
  final klinesApi = ref.watch(binanceKlinesApiProvider);
  final signalApi = ref.watch(chartSignalApiProvider);

  final results = await Future.wait([
    klinesApi.fetchKlines(
      symbol: params.coin.symbol,
      marketType: params.coin.marketType,
      timeframe: params.timeframe,
    ),
    signalApi.fetchSignals(coinId: params.coin.id, timeframe: params.timeframe),
  ]);

  return ChartData(
    candles: results[0] as List<Candle>,
    signals: results[1] as List<ChartSignal>,
  );
});
