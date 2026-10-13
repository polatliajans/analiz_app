import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_api.dart';

/// How often the coin picker refreshes prices while it is open.
const tickerRefreshInterval = Duration(seconds: 10);

final tickerApiProvider = Provider<TickerApi>((ref) => TickerApi());

/// Live 24h quotes per market type ('spot' / 'futures'), by symbol. Only
/// alive while the coin picker watches it. A failed refresh keeps the
/// previous quotes (and the server values in the list stay as they are).
class LiveTickersNotifier
    extends Notifier<Map<String, Map<String, TickerQuote>>> {
  @override
  Map<String, Map<String, TickerQuote>> build() => const {};

  Future<void> refresh(Iterable<String> marketTypes) async {
    await Future.wait([
      for (final market in marketTypes.toSet()) _refreshOne(market),
    ]);
  }

  Future<void> _refreshOne(String market) async {
    try {
      final quotes = await ref.read(tickerApiProvider).fetchAll(market);
      if (!ref.mounted || quotes.isEmpty) return;
      state = {...state, market: quotes};
    } catch (_) {
      // Keep the previous / server values.
    }
  }
}

final liveTickersProvider =
    NotifierProvider.autoDispose<
      LiveTickersNotifier,
      Map<String, Map<String, TickerQuote>>
    >(LiveTickersNotifier.new);
