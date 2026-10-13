import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/binance_klines_api.dart';
import '../data/chart_signal_api.dart';
import '../models/coin.dart';

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
