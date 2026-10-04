const _quoteSuffixes = ['FDUSD', 'USDT', 'USDC', 'BUSD', 'TUSD', 'USD'];

const _stableBases = {
  'USDC',
  'FDUSD',
  'TUSD',
  'USDP',
  'DAI',
  'BUSD',
  'USDE',
  'USD1',
  'USDS',
  'PYUSD',
  'AEUR',
  'EUR',
  'EURI',
  'UST',
  'USTC',
  'XUSD',
  'BFUSD',
  'USDT',
};

/// True when the base asset of [symbol] is itself a stablecoin (for example
/// USDCUSDT), so the pair is not useful to analyse.
bool isStablePair(String symbol) {
  final s = symbol.toUpperCase();
  for (final quote in _quoteSuffixes) {
    if (s.endsWith(quote) && s.length > quote.length) {
      return _stableBases.contains(s.substring(0, s.length - quote.length));
    }
  }
  return false;
}
