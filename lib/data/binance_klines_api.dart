import 'dart:convert';
import 'package:http/http.dart' as http;

import '../l10n/app_l10n.dart';
import '../models/candle.dart';
import 'binance_hosts.dart';

class ChartDataException implements Exception {
  final String message;
  ChartDataException(this.message);

  @override
  String toString() => message;
}

class BinanceKlinesApi {
  /// Test seam; null uses a fresh client per call.
  final http.Client? client;
  final BinanceHostState? hostState;
  const BinanceKlinesApi({this.client, this.hostState});

  Future<List<Candle>> fetchKlines({
    required String symbol,
    required String marketType,
    required String timeframe,
    int limit = 300,
  }) async {
    final query = {'symbol': symbol, 'interval': timeframe, 'limit': '$limit'};

    final http.Response response;
    try {
      if (marketType == 'futures') {
        // Futures has no market-data-only host: no fallback.
        final c = client ?? http.Client();
        try {
          response = await c
              .get(Uri.https('fapi.binance.com', '/fapi/v1/klines', query))
              .timeout(const Duration(seconds: 10));
        } finally {
          if (client == null) c.close();
        }
      } else {
        response = await getSpotResilient(
          '/api/v3/klines',
          query,
          client: client,
          state: hostState,
        );
      }
    } catch (e) {
      throw ChartDataException(AppL10n.current.errorCandlesFailed('$e'));
    }

    if (response.statusCode != 200) {
      throw ChartDataException(
        AppL10n.current.errorBinance(response.statusCode),
      );
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((row) => Candle.fromKline(row as List<dynamic>)).toList();
  }
}
