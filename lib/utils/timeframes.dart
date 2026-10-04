/// Chart timeframes offered in the UI (Binance kline intervals).
const chartTimeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];

const _minute = 60 * 1000;

/// Candle duration in milliseconds per timeframe.
const timeframeMs = {
  '1m': _minute,
  '5m': 5 * _minute,
  '15m': 15 * _minute,
  '1h': 60 * _minute,
  '4h': 4 * 60 * _minute,
  '1d': 24 * 60 * _minute,
  '1w': 7 * 24 * 60 * _minute,
};

/// The signals endpoint only accepts these timeframes.
const signalTimeframes = ['15m', '1h', '4h', '1d'];

bool supportsSignals(String timeframe) => signalTimeframes.contains(timeframe);
