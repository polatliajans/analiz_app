import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/watchlist_api.dart';
import '../models/coin.dart';
import 'auth_provider.dart';

final watchlistApiProvider = Provider<WatchlistApi>((ref) => WatchlistApi());

final watchlistProvider = FutureProvider<List<Coin>>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.token;
  if (token == null) return [];

  return ref.watch(watchlistApiProvider).fetchWatchlist(token);
});
