import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/candle.dart';

/// Upper bound for the candle list while live updates keep appending.
const maxLiveCandles = 1000;

/// Event delivered by a [KlineStream].
sealed class LiveEvent {
  const LiveEvent();
}

/// One kline (candle) snapshot from the stream (`k` object of a kline event).
class KlineUpdate extends LiveEvent {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final bool isClosed;

  const KlineUpdate({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isClosed,
  });

  Candle toCandle() => Candle(
    openTime: openTime,
    open: open,
    high: high,
    low: low,
    close: close,
  );
}

/// 24h mini ticker: last price and the price 24h ago.
class TickerUpdate extends LiveEvent {
  final double lastPrice;
  final double openPrice24h;

  const TickerUpdate({required this.lastPrice, required this.openPrice24h});

  /// 24h change in percent, or null when the open price is unusable.
  double? get changePercent =>
      openPrice24h > 0 ? (lastPrice - openPrice24h) / openPrice24h * 100 : null;
}

/// Returns the event payload: the `data` of a combined-stream envelope, or
/// the message itself for a bare event. Null if it is not a JSON object.
Map<String, dynamic>? _payload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : decoded;
  } catch (_) {
    return null;
  }
}

/// Parses a Binance kline message (combined envelope or bare). Returns null
/// for other event types or malformed input.
KlineUpdate? parseKlineMessage(String raw) {
  final data = _payload(raw);
  if (data == null || data['e'] != 'kline') return null;
  final k = data['k'];
  if (k is! Map<String, dynamic>) return null;
  try {
    return KlineUpdate(
      openTime: (k['t'] as num).toInt(),
      open: double.parse('${k['o']}'),
      high: double.parse('${k['h']}'),
      low: double.parse('${k['l']}'),
      close: double.parse('${k['c']}'),
      isClosed: k['x'] == true,
    );
  } catch (_) {
    return null;
  }
}

/// Parses a Binance `24hrMiniTicker` message (combined envelope or bare).
TickerUpdate? parseMiniTickerMessage(String raw) {
  final data = _payload(raw);
  if (data == null || data['e'] != '24hrMiniTicker') return null;
  final last = double.tryParse('${data['c']}');
  final open = double.tryParse('${data['o']}');
  if (last == null || open == null) return null;
  return TickerUpdate(lastPrice: last, openPrice24h: open);
}

/// Parses any supported stream message.
LiveEvent? parseLiveMessage(String raw) =>
    parseKlineMessage(raw) ?? parseMiniTickerMessage(raw);

/// Returns a new candle list with [update] applied: same open time replaces
/// that candle, a newer one is appended (oldest dropped past
/// [maxLiveCandles]), an older unknown one is ignored.
List<Candle> applyKlineUpdate(List<Candle> candles, KlineUpdate update) {
  final candle = update.toCandle();
  if (candles.isEmpty) return [candle];

  final lastTime = candles.last.openTime;
  if (update.openTime > lastTime) {
    final out = [...candles, candle];
    if (out.length > maxLiveCandles) {
      out.removeRange(0, out.length - maxLiveCandles);
    }
    return out;
  }

  for (var i = candles.length - 1; i >= 0; i--) {
    final t = candles[i].openTime;
    if (t == update.openTime) {
      final out = [...candles];
      out[i] = candle;
      return out;
    }
    if (t < update.openTime) break;
  }
  return candles;
}

/// Reconnect delay for the zero-based [attempt]: 1, 2, 4, 8, then 15 s max.
Duration nextBackoff(int attempt) {
  final a = attempt.clamp(0, 10);
  final seconds = math.min(1 << a, 15);
  return Duration(seconds: seconds);
}

/// Combined stream (kline + mini ticker) URL for one symbol.
Uri klineStreamUri({
  required String marketType,
  required String symbol,
  required String timeframe,
}) {
  final s = symbol.toLowerCase();
  final streams = '$s@kline_$timeframe/$s@miniTicker';
  final base = marketType == 'futures'
      ? 'wss://fstream.binance.com/stream'
      : 'wss://stream.binance.com:9443/stream';
  return Uri.parse('$base?streams=$streams');
}

/// Source of live events. Listening opens the connection, cancelling closes
/// it. Errors/done signal a lost connection (the consumer reconnects).
abstract class KlineStream {
  Stream<LiveEvent> connect({
    required String marketType,
    required String symbol,
    required String timeframe,
  });
}

class WebSocketKlineStream implements KlineStream {
  const WebSocketKlineStream();

  @override
  Stream<LiveEvent> connect({
    required String marketType,
    required String symbol,
    required String timeframe,
  }) {
    late final StreamController<LiveEvent> controller;
    WebSocketChannel? channel;
    StreamSubscription<dynamic>? sub;

    Future<void> open() async {
      try {
        final ch = WebSocketChannel.connect(
          klineStreamUri(
            marketType: marketType,
            symbol: symbol,
            timeframe: timeframe,
          ),
        );
        channel = ch;
        await ch.ready;
        if (controller.isClosed) return;
        sub = ch.stream.listen(
          (message) {
            if (message is! String) return;
            final event = parseLiveMessage(message);
            if (event != null && !controller.isClosed) controller.add(event);
          },
          onError: (Object e, StackTrace st) {
            if (!controller.isClosed) controller.addError(e, st);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
      }
    }

    controller = StreamController<LiveEvent>(
      onListen: open,
      onCancel: () async {
        await sub?.cancel();
        try {
          await channel?.sink.close();
        } catch (_) {}
      },
    );
    return controller.stream;
  }
}
