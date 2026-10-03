import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coin_api.dart';
import '../models/coin.dart';

final coinApiProvider = Provider<CoinApi>((ref) => CoinApi());

final coinListProvider = FutureProvider.family<List<Coin>, String>((
  ref,
  marketType,
) async {
  final api = ref.watch(coinApiProvider);
  return api.fetchCoins(marketType: marketType);
});
