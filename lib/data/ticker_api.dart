import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/coin.dart';

/// Last price and 24h change of one symbol from the Binance 24h ticker.
class TickerQuote {
  final double lastPrice;
  final double changePercent;

  const TickerQuote({required this.lastPrice, required this.changePercent});
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
    out[symbol] = TickerQuote(lastPrice: price, changePercent: change);
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
  /// Fetches the bulk 24h ticker of a market. Throws on network/HTTP errors.
  Future<Map<String, TickerQuote>> fetchAll(String marketType) async {
    final url = marketType == 'futures'
        ? 'https://fapi.binance.com/fapi/v1/ticker/24hr'
        : 'https://api.binance.com/api/v3/ticker/24hr';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('ticker ${response.statusCode}');
    }
    return compute(parseTickerMap, response.body);
  }
}
