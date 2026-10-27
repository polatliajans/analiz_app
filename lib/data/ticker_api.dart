import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/coin.dart';
import 'binance_hosts.dart';

/// Last price and 24h change of one symbol from the Binance 24h ticker.
class TickerQuote {
  final double lastPrice;
  final double changePercent;

  /// 24h turnover in the quote currency (0 when the feed did not send it).
  final double quoteVolume;

  const TickerQuote({
    required this.lastPrice,
    required this.changePercent,
    this.quoteVolume = 0,
  });
}

/// Parses the bulk 24h ticker array into a symbol -> quote map. Malformed
/// rows are skipped; an unusable payload yields an empty map.
Map<String, TickerQuote> parseTickerMap(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return const {};
  }
  if (decoded is! List) return const {};

  final out = <String, TickerQuote>{};
  for (final row in decoded) {
    if (row is! Map) continue;
    final symbol = row['symbol'];
    final price = double.tryParse('${row['lastPrice']}');
    final change = double.tryParse('${row['priceChangePercent']}');
    if (symbol is! String || price == null || change == null) continue;
    out[symbol] = TickerQuote(
      lastPrice: price,
      changePercent: change,
      quoteVolume: double.tryParse('${row['quoteVolume']}') ?? 0,
    );
  }
  return out;
}

/// Overwrites price and 24h change of [coin] with [quote] (volume and other
/// fields are kept). Returns [coin] itself when there is no quote.
Coin applyQuote(Coin coin, TickerQuote? quote) => quote == null
    ? coin
    : coin.copyWith(
        lastPrice: quote.lastPrice,
        priceChangePercent24h: quote.changePercent,
      );

/// [applyQuote] for a whole list, looking quotes up by symbol.
List<Coin> applyTickers(List<Coin> coins, Map<String, TickerQuote> quotes) {
  if (quotes.isEmpty) return coins;
  return [for (final c in coins) applyQuote(c, quotes[c.symbol])];
}

class TickerApi {
  final http.Client? client;
  final BinanceHostState? hostState;
  TickerApi({this.client, this.hostState});

  /// Fetches the bulk 24h ticker of a market. Throws on network/HTTP errors.
  /// Spot falls back to Binance's market-data-only host when blocked.
  Future<Map<String, TickerQuote>> fetchAll(String marketType) async {
    final http.Response response;
    if (marketType == 'futures') {
      final c = client ?? http.Client();
      try {
        response = await c
            .get(Uri.https('fapi.binance.com', '/fapi/v1/ticker/24hr'))
            .timeout(const Duration(seconds: 10));
      } finally {
        if (client == null) c.close();
      }
    } else {
      response = await getSpotResilient(
        '/api/v3/ticker/24hr',
        const {},
        client: client,
        state: hostState,
      );
    }
    if (response.statusCode != 200) {
      throw Exception('ticker ${response.statusCode}');
    }
    return compute(parseTickerMap, response.body);
  }
}
