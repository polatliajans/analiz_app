// Content of the "Technical terms glossary" page.
//
// The text is bulk reference material, so it lives here as per-locale maps
// instead of ARB keys (only the page chrome - title, search hint, links - is in
// the ARB files). Every term must have a name and a description in all of
// [glossaryLocales]; test/glossary_test.dart enforces this.

/// Locales the glossary content is written in. Anything else falls back to
/// [glossaryFallbackLocale].
const glossaryLocales = ['tr', 'en', 'es'];
const glossaryFallbackLocale = 'en';

enum GlossaryCategory {
  trend,
  momentum,
  volatility,
  levels,
  volume,
  derivatives,
  market,
  concepts,
}

/// Localized category titles.
const glossaryCategoryTitles = <GlossaryCategory, Map<String, String>>{
  GlossaryCategory.trend: {
    'tr': 'Trend & ortalamalar',
    'en': 'Trend & averages',
    'es': 'Tendencia y medias',
  },
  GlossaryCategory.momentum: {
    'tr': 'Momentum',
    'en': 'Momentum',
    'es': 'Momentum',
  },
  GlossaryCategory.volatility: {
    'tr': 'Oynaklık',
    'en': 'Volatility',
    'es': 'Volatilidad',
  },
  GlossaryCategory.levels: {'tr': 'Seviyeler', 'en': 'Levels', 'es': 'Niveles'},
  GlossaryCategory.volume: {
    'tr': 'Hacim & akış',
    'en': 'Volume & flow',
    'es': 'Volumen y flujo',
  },
  GlossaryCategory.derivatives: {
    'tr': 'Türev piyasa',
    'en': 'Derivatives market',
    'es': 'Mercado de derivados',
  },
  GlossaryCategory.market: {
    'tr': 'Piyasa & temel',
    'en': 'Market & fundamentals',
    'es': 'Mercado y fundamentales',
  },
  GlossaryCategory.concepts: {
    'tr': 'Analiz kavramları',
    'en': 'Analysis concepts',
    'es': 'Conceptos de análisis',
  },
};

class GlossaryEntry {
  final String name;
  final String text;
  const GlossaryEntry(this.name, this.text);
}

class GlossaryTerm {
  /// Stable id, usable as a deep-link anchor (e.g. `rsi`, `funding`).
  final String id;
  final GlossaryCategory category;

  /// Extra searchable names (abbreviations, long forms, other languages).
  final List<String> aliases;
  final Map<String, GlossaryEntry> entries;

  const GlossaryTerm(this.id, this.category, this.aliases, this.entries);

  GlossaryEntry entry(String languageCode) =>
      entries[languageCode] ?? entries[glossaryFallbackLocale]!;
}

const glossaryTerms = <GlossaryTerm>[
  // ---------------------------------------------------------------- Trend
  GlossaryTerm(
    'trend',
    GlossaryCategory.trend,
    ['uptrend', 'downtrend', 'sideways', 'yatay', 'yön', 'tendencia'],
    {
      'tr': GlossaryEntry(
        'Trend',
        'Fiyatın belirli bir dönemde ağırlıklı olarak hangi yöne gittiği. Yükselen tepe ve dipler yukarı, düşen tepe ve dipler aşağı trend; belirgin bir yön yoksa piyasa yatay kabul edilir.',
      ),
      'en': GlossaryEntry(
        'Trend',
        'The direction price has mostly been moving over a given period. Rising highs and lows mean an uptrend, falling highs and lows a downtrend; with no clear direction the market is called sideways.',
      ),
      'es': GlossaryEntry(
        'Tendencia',
        'La dirección en la que se ha movido el precio durante un periodo. Máximos y mínimos crecientes indican tendencia alcista, decrecientes bajista; sin dirección clara el mercado se llama lateral.',
      ),
    },
  ),
  GlossaryTerm(
    'ema',
    GlossaryCategory.trend,
    [
      'EMA',
      'Exponential Moving Average',
      'Üstel Hareketli Ortalama',
      'Media móvil exponencial',
      'EMA 20',
      'EMA 50',
      'EMA 200',
    ],
    {
      'tr': GlossaryEntry(
        'EMA (Üstel Hareketli Ortalama)',
        'Son fiyatlara daha fazla ağırlık veren hareketli ortalama; SMA\'ya göre yeni gelişmelere daha hızlı tepki verir. Fiyat EMA\'nın üzerindeyse eğilim genelde yukarı, altındaysa aşağı yönlü okunur (ör. EMA 20, 50, 200).',
      ),
      'en': GlossaryEntry(
        'EMA (Exponential Moving Average)',
        'A moving average that gives more weight to recent prices, so it reacts faster than an SMA. Price above the EMA is usually read as an upward bias and below it as a downward bias (e.g. EMA 20, 50, 200).',
      ),
      'es': GlossaryEntry(
        'EMA (Media móvil exponencial)',
        'Media móvil que da más peso a los precios recientes, por lo que reacciona más rápido que una SMA. Precio por encima de la EMA suele leerse como sesgo alcista y por debajo como bajista (p. ej. EMA 20, 50, 200).',
      ),
    },
  ),
  GlossaryTerm(
    'sma',
    GlossaryCategory.trend,
    [
      'SMA',
      'Simple Moving Average',
      'Basit Hareketli Ortalama',
      'Media móvil simple',
      'MA',
      'moving average',
    ],
    {
      'tr': GlossaryEntry(
        'SMA (Basit Hareketli Ortalama)',
        'Son N mumun kapanışlarının düz ortalaması; fiyattaki gürültüyü yumuşatır. N ne kadar büyükse çizgi o kadar yavaş ve uzun vadeli bir eğilimi gösterir (ör. SMA 50, SMA 200).',
      ),
      'en': GlossaryEntry(
        'SMA (Simple Moving Average)',
        'The plain average of the last N closing prices, which smooths out noise. The larger N is, the slower the line and the longer-term the trend it shows (e.g. SMA 50, SMA 200).',
      ),
      'es': GlossaryEntry(
        'SMA (Media móvil simple)',
        'El promedio simple de los últimos N cierres, que suaviza el ruido. Cuanto mayor es N, más lenta es la línea y más largo plazo es la tendencia que muestra (p. ej. SMA 50, SMA 200).',
      ),
    },
  ),
  GlossaryTerm(
    'adx',
    GlossaryCategory.trend,
    [
      'ADX',
      'Average Directional Index',
      'Ortalama Yönsel Endeks',
      'Índice direccional medio',
      'trend gücü',
    ],
    {
      'tr': GlossaryEntry(
        'ADX (Ortalama Yönsel Endeks)',
        'Trendin yönünü değil gücünü ölçen 0-100 arası gösterge. Yaklaşık 20\'nin altı zayıf/yatay, 25\'in üstü belirgin, 40-50\'nin üstü çok güçlü trend olarak yorumlanır.',
      ),
      'en': GlossaryEntry(
        'ADX (Average Directional Index)',
        'A 0-100 gauge of trend strength, not direction. Below roughly 20 is usually a weak or sideways market, above 25 a clear trend, and above 40-50 a very strong one.',
      ),
      'es': GlossaryEntry(
        'ADX (Índice direccional medio)',
        'Indicador de 0 a 100 que mide la fuerza de la tendencia, no su dirección. Por debajo de ~20 suele indicar mercado débil o lateral, por encima de 25 una tendencia clara y por encima de 40-50 una muy fuerte.',
      ),
    },
  ),
  GlossaryTerm(
    'di',
    GlossaryCategory.trend,
    [
      '+DI',
      '-DI',
      'DI',
      'DMI',
      'Directional Indicator',
      'Directional Movement',
      'Yönsel Gösterge',
    ],
    {
      'tr': GlossaryEntry(
        '+DI / -DI (Yönsel Göstergeler)',
        'Yukarı ve aşağı yöndeki hareketin gücünü ayrı ayrı gösteren, ADX\'in bileşeni olan iki çizgi. +DI, -DI\'ın üzerindeyse alıcılar, altındaysa satıcılar baskın sayılır; aradaki fark açıldıkça yön daha belirgindir.',
      ),
      'en': GlossaryEntry(
        '+DI / -DI (Directional Indicators)',
        'Two lines, the building blocks of ADX, that show the strength of upward and downward movement separately. +DI above -DI suggests buyers dominate, below suggests sellers; the wider the gap, the clearer the direction.',
      ),
      'es': GlossaryEntry(
        '+DI / -DI (Indicadores direccionales)',
        'Dos líneas, componentes del ADX, que muestran por separado la fuerza del movimiento alcista y bajista. Si +DI está sobre -DI dominan los compradores, si está debajo los vendedores; cuanto mayor la brecha, más clara la dirección.',
      ),
    },
  ),
  GlossaryTerm(
    'donchian',
    GlossaryCategory.trend,
    [
      'Donchian',
      'Donchian Channel',
      'Donchian Kanalı',
      'Canal de Donchian',
      'kanal',
      'breakout',
    ],
    {
      'tr': GlossaryEntry(
        'Donchian Kanalı',
        'Son N mumun en yüksek ve en düşük fiyatından oluşan kanal (ör. 20 mum). Fiyatın üst banda yaklaşması güçlü yükselişi, alt banda yaklaşması güçlü düşüşü gösterir; kanalın daralması düşük oynaklık demektir.',
      ),
      'en': GlossaryEntry(
        'Donchian Channel',
        'A channel drawn from the highest high and lowest low of the last N candles (e.g. 20). Price near the upper band shows strong upside, near the lower band strong downside; a narrowing channel means low volatility.',
      ),
      'es': GlossaryEntry(
        'Canal de Donchian',
        'Canal formado por el máximo más alto y el mínimo más bajo de las últimas N velas (p. ej. 20). El precio cerca de la banda superior muestra fuerza alcista, cerca de la inferior fuerza bajista; un canal que se estrecha indica baja volatilidad.',
      ),
    },
  ),

  // ------------------------------------------------------------- Momentum
  GlossaryTerm(
    'rsi',
    GlossaryCategory.momentum,
    [
      'RSI',
      'Relative Strength Index',
      'Göreli Güç Endeksi',
      'Índice de fuerza relativa',
    ],
    {
      'tr': GlossaryEntry(
        'RSI (Göreli Güç Endeksi)',
        'Son fiyat hareketlerinin hızını ve büyüklüğünü 0-100 arasında ölçen momentum göstergesi. Genelde 70 üstü aşırı alım, 30 altı aşırı satım bölgesi, 50 civarı dengeli kabul edilir; güçlü trendlerde uzun süre bu bölgelerde kalabilir.',
      ),
      'en': GlossaryEntry(
        'RSI (Relative Strength Index)',
        'A 0-100 momentum gauge of the speed and size of recent price moves. Above 70 is commonly called overbought, below 30 oversold, and around 50 balanced; in strong trends it can stay in those zones for a long time.',
      ),
      'es': GlossaryEntry(
        'RSI (Índice de fuerza relativa)',
        'Indicador de momentum de 0 a 100 que mide la velocidad y magnitud de los movimientos recientes. Por encima de 70 se suele hablar de sobrecompra, por debajo de 30 de sobreventa y cerca de 50 de equilibrio; en tendencias fuertes puede permanecer mucho tiempo en esas zonas.',
      ),
    },
  ),
  GlossaryTerm(
    'stochrsi',
    GlossaryCategory.momentum,
    ['StochRSI', 'Stochastic RSI', 'Stokastik RSI', 'RSI estocástico'],
    {
      'tr': GlossaryEntry(
        'StochRSI',
        'RSI değerine stokastik formülün uygulandığı, 0-1 (veya 0-100) arası hızlı bir osilatör. 0,8 (80) üstü aşırı alım, 0,2 (20) altı aşırı satım olarak okunur; RSI\'dan daha sık dalgalandığı için gürültülüdür.',
      ),
      'en': GlossaryEntry(
        'StochRSI',
        'A fast 0-1 (or 0-100) oscillator that applies the stochastic formula to RSI values. Above 0.8 (80) reads as overbought and below 0.2 (20) as oversold; it swings more often than RSI, so it is noisier.',
      ),
      'es': GlossaryEntry(
        'StochRSI',
        'Oscilador rápido de 0 a 1 (o 0 a 100) que aplica la fórmula estocástica a los valores del RSI. Por encima de 0,8 (80) se lee como sobrecompra y por debajo de 0,2 (20) como sobreventa; oscila más que el RSI, por lo que es más ruidoso.',
      ),
    },
  ),
  GlossaryTerm(
    'williamsr',
    GlossaryCategory.momentum,
    ['Williams %R', 'Williams R', '%R', 'WillR'],
    {
      'tr': GlossaryEntry(
        'Williams %R',
        'Fiyatın son N mumluk aralığın neresinde olduğunu -100 ile 0 arasında gösteren osilatör. -20\'nin üstü aşırı alım, -80\'in altı aşırı satım bölgesi olarak yorumlanır.',
      ),
      'en': GlossaryEntry(
        'Williams %R',
        'An oscillator between -100 and 0 showing where price sits within the range of the last N candles. Above -20 is read as overbought and below -80 as oversold.',
      ),
      'es': GlossaryEntry(
        'Williams %R',
        'Oscilador entre -100 y 0 que muestra dónde se sitúa el precio dentro del rango de las últimas N velas. Por encima de -20 se lee como sobrecompra y por debajo de -80 como sobreventa.',
      ),
    },
  ),
  GlossaryTerm(
    'macd',
    GlossaryCategory.momentum,
    [
      'MACD',
      'MACD histogram',
      'Histogram',
      'Histograma',
      'sinyal çizgisi',
      'signal line',
      'Moving Average Convergence Divergence',
    ],
    {
      'tr': GlossaryEntry(
        'MACD ve histogram',
        'İki EMA (genelde 12 ve 26) arasındaki farktan oluşan momentum göstergesi; 9 periyotluk sinyal çizgisiyle birlikte okunur. Histogram bu ikisi arasındaki farktır: sıfırın üstünde ve büyüyorsa yükseliş, altında ve büyüyorsa düşüş momentumu güçleniyor demektir.',
      ),
      'en': GlossaryEntry(
        'MACD & histogram',
        'A momentum indicator built from the difference between two EMAs (usually 12 and 26), read together with a 9-period signal line. The histogram is the gap between the two: above zero and growing means rising upside momentum, below zero and growing means rising downside momentum.',
      ),
      'es': GlossaryEntry(
        'MACD e histograma',
        'Indicador de momentum basado en la diferencia entre dos EMA (normalmente 12 y 26), que se lee junto a una línea de señal de 9 periodos. El histograma es la diferencia entre ambas: sobre cero y creciendo indica más momentum alcista, bajo cero y creciendo más momentum bajista.',
      ),
    },
  ),

  // ----------------------------------------------------------- Volatility
  GlossaryTerm(
    'atr',
    GlossaryCategory.volatility,
    [
      'ATR',
      'Average True Range',
      'Ortalama Gerçek Aralık',
      'Rango verdadero medio',
      'oynaklık',
    ],
    {
      'tr': GlossaryEntry(
        'ATR (Ortalama Gerçek Aralık)',
        'Son mumlardaki ortalama fiyat aralığını, yani oynaklığı fiyat birimiyle ölçer; yön göstermez. ATR 500 ise fiyat mum başına ortalama yaklaşık 500 birim hareket ediyor demektir; stop mesafesi ve pozisyon boyutunu ölçmekte kullanılır.',
      ),
      'en': GlossaryEntry(
        'ATR (Average True Range)',
        'Measures the average price range of recent candles, i.e. volatility, in price units; it does not show direction. An ATR of 500 means price moves about 500 units per candle on average; it is used to size stop distances and positions.',
      ),
      'es': GlossaryEntry(
        'ATR (Rango verdadero medio)',
        'Mide el rango medio de precio de las velas recientes, es decir la volatilidad, en unidades de precio; no indica dirección. Un ATR de 500 significa que el precio se mueve unas 500 unidades por vela de media; se usa para dimensionar distancias de stop y posiciones.',
      ),
    },
  ),
  GlossaryTerm(
    'atrpercentile',
    GlossaryCategory.volatility,
    [
      'ATR percentile',
      'ATR yüzdelik',
      'ATR yüzdelik sırası',
      'Percentil del ATR',
      'volatility percentile',
    ],
    {
      'tr': GlossaryEntry(
        'ATR yüzdelik sırası',
        'Güncel ATR\'nin kendi geçmiş değerleri içindeki yerini 0-100 arasında gösterir. 90 ise oynaklık geçmişin yaklaşık %90\'ından yüksektir (olağandışı hareketli), 10 ise piyasa sakindir.',
      ),
      'en': GlossaryEntry(
        'ATR percentile',
        'Shows where the current ATR sits within its own history on a 0-100 scale. A reading of 90 means volatility is higher than about 90% of past readings (unusually active); 10 means the market is quiet.',
      ),
      'es': GlossaryEntry(
        'Percentil del ATR',
        'Muestra dónde se sitúa el ATR actual dentro de su propio historial en una escala de 0 a 100. Un valor de 90 indica que la volatilidad supera a cerca del 90% de las lecturas pasadas (inusualmente activa); 10 indica un mercado tranquilo.',
      ),
    },
  ),
  GlossaryTerm(
    'bollinger',
    GlossaryCategory.volatility,
    [
      'Bollinger',
      'Bollinger Bands',
      'Bollinger bantları',
      '%B',
      'percent B',
      'BB',
      'Bandas de Bollinger',
    ],
    {
      'tr': GlossaryEntry(
        'Bollinger bantları ve %B',
        'Hareketli ortalamanın (genelde 20) etrafında ±2 standart sapma ile çizilen bantlar; oynaklık arttıkça genişler. %B fiyatın bant içindeki yerini verir: 0 alt bandı, 0,5 orta çizgiyi, 1 üst bandı gösterir; 1\'in üstü veya 0\'ın altı bant dışı kapanıştır.',
      ),
      'en': GlossaryEntry(
        'Bollinger Bands & %B',
        'Bands drawn ±2 standard deviations around a moving average (usually 20), widening as volatility rises. %B gives price\'s position within the bands: 0 is the lower band, 0.5 the middle line, 1 the upper band; above 1 or below 0 means price is outside the bands.',
      ),
      'es': GlossaryEntry(
        'Bandas de Bollinger y %B',
        'Bandas trazadas a ±2 desviaciones estándar de una media móvil (normalmente de 20), que se ensanchan al subir la volatilidad. El %B indica la posición del precio dentro de las bandas: 0 es la banda inferior, 0,5 la línea central y 1 la superior; por encima de 1 o por debajo de 0 el precio está fuera de las bandas.',
      ),
    },
  ),

  // --------------------------------------------------------------- Levels
  GlossaryTerm(
    'support',
    GlossaryCategory.levels,
    ['Support', 'Soporte', 'destek', 'taban'],
    {
      'tr': GlossaryEntry(
        'Destek',
        'Fiyatın geçmişte düşüşte durup toparlandığı, alıcıların toplandığı varsayılan seviye. Fiyat bu seviyeye yaklaşınca tepki verebilir; seviyenin altında kapanış zayıflığa işaret eder.',
      ),
      'en': GlossaryEntry(
        'Support',
        'A price level where a decline has previously stalled and recovered, assumed to attract buyers. Price may react when it approaches it; a close below the level points to weakness.',
      ),
      'es': GlossaryEntry(
        'Soporte',
        'Nivel de precio donde una caída se ha detenido y recuperado antes, y donde se supone que entran compradores. El precio puede reaccionar al acercarse; un cierre por debajo del nivel indica debilidad.',
      ),
    },
  ),
  GlossaryTerm(
    'resistance',
    GlossaryCategory.levels,
    ['Resistance', 'Resistencia', 'direnç', 'tavan'],
    {
      'tr': GlossaryEntry(
        'Direnç',
        'Fiyatın geçmişte yükselişte durup geri döndüğü, satıcıların toplandığı varsayılan seviye. Fiyat bu seviyeye yaklaşınca tepki verebilir; seviyenin üzerinde kapanış güçlülüğe işaret eder.',
      ),
      'en': GlossaryEntry(
        'Resistance',
        'A price level where a rise has previously stalled and turned back, assumed to attract sellers. Price may react when it approaches it; a close above the level points to strength.',
      ),
      'es': GlossaryEntry(
        'Resistencia',
        'Nivel de precio donde una subida se ha detenido y revertido antes, y donde se supone que entran vendedores. El precio puede reaccionar al acercarse; un cierre por encima del nivel indica fortaleza.',
      ),
    },
  ),
  GlossaryTerm(
    'touches',
    GlossaryCategory.levels,
    ['touch', 'touches', 'pivot', 'temas', 'temas sayısı', 'toques', 'swing'],
    {
      'tr': GlossaryEntry(
        'Temas sayısı / pivot',
        'Pivot, fiyattaki yerel bir tepe veya dip noktasıdır. Temas sayısı, bir seviyenin bu pivotlarla kaç kez test edildiğini gösterir; sayı arttıkça seviye daha çok dikkate alınır, ancak çok test edilen seviyeler de sonunda kırılabilir.',
      ),
      'en': GlossaryEntry(
        'Touch count / pivot',
        'A pivot is a local high or low in price. The touch count shows how many times a level has been tested by such pivots; more touches make a level more widely watched, though a heavily tested level can still eventually break.',
      ),
      'es': GlossaryEntry(
        'Número de toques / pivote',
        'Un pivote es un máximo o mínimo local del precio. El número de toques indica cuántas veces se ha probado un nivel con esos pivotes; más toques hacen que el nivel sea más observado, aunque un nivel muy probado también puede acabar rompiéndose.',
      ),
    },
  ),
  GlossaryTerm(
    'invalidation',
    GlossaryCategory.levels,
    [
      'invalidation',
      'stop',
      'stop loss',
      'stop-loss',
      'geçersiz kılma',
      'invalidación',
      'SL',
    ],
    {
      'tr': GlossaryEntry(
        'Geçersiz kılma / Stop',
        'Fiyat bu seviyeyi aşarsa analizdeki senaryonun artık geçerli sayılmadığı seviye. Stop ise zararı sınırlamak için konan emir seviyesidir; bu seviyeler bilgi amaçlıdır, yatırım tavsiyesi değildir.',
      ),
      'en': GlossaryEntry(
        'Invalidation / Stop',
        'The level beyond which the analysis scenario is no longer considered valid. A stop is the order level used to limit a loss; these levels are informational and not investment advice.',
      ),
      'es': GlossaryEntry(
        'Invalidación / Stop',
        'El nivel que, si se supera, hace que el escenario del análisis deje de considerarse válido. El stop es el nivel de orden que se usa para limitar una pérdida; estos niveles son informativos y no constituyen consejo de inversión.',
      ),
    },
  ),
  GlossaryTerm(
    'target',
    GlossaryCategory.levels,
    ['target', 'take profit', 'TP', 'hedef', 'objetivo'],
    {
      'tr': GlossaryEntry(
        'Hedef',
        'Bir senaryoda fiyatın ulaşabileceği varsayılan seviye; genelde bir önceki direnç/destek veya ölçülü bir hareketten türetilir. Hedefe ulaşılacağının garantisi yoktur.',
      ),
      'en': GlossaryEntry(
        'Target',
        'The level price could reach in a given scenario, usually derived from a prior resistance/support or a measured move. There is no guarantee that a target will be reached.',
      ),
      'es': GlossaryEntry(
        'Objetivo',
        'El nivel que el precio podría alcanzar en un escenario, normalmente derivado de una resistencia/soporte previa o de un movimiento medido. No hay garantía de que se alcance.',
      ),
    },
  ),

  // --------------------------------------------------------------- Volume
  GlossaryTerm(
    'volume',
    GlossaryCategory.volume,
    ['Volume', 'Volumen', 'hacim', 'işlem hacmi'],
    {
      'tr': GlossaryEntry(
        'Hacim',
        'Belirli bir sürede alınıp satılan toplam varlık miktarı veya tutarı. Fiyat hareketine yüksek hacim eşlik ediyorsa hareket daha fazla katılımla gerçekleşmiş demektir.',
      ),
      'en': GlossaryEntry(
        'Volume',
        'The total amount of an asset bought and sold in a given period. A price move accompanied by high volume was made with broader participation.',
      ),
      'es': GlossaryEntry(
        'Volumen',
        'La cantidad total de un activo comprada y vendida en un periodo. Un movimiento de precio acompañado de volumen alto se ha producido con mayor participación.',
      ),
    },
  ),
  GlossaryTerm(
    'relvolume',
    GlossaryCategory.volume,
    ['Relative volume', 'RVOL', 'Göreli hacim', 'Volumen relativo'],
    {
      'tr': GlossaryEntry(
        'Göreli hacim',
        'Güncel hacmin yakın geçmişteki ortalama hacme oranı. 1,0 ortalama, 2,0 ortalamanın iki katı demektir; yüksek değer olağandışı bir ilgiye işaret eder.',
      ),
      'en': GlossaryEntry(
        'Relative volume',
        'Current volume divided by its recent average. 1.0 is average and 2.0 is twice the average; a high value points to unusual interest.',
      ),
      'es': GlossaryEntry(
        'Volumen relativo',
        'El volumen actual dividido por su promedio reciente. 1,0 es el promedio y 2,0 el doble del promedio; un valor alto indica un interés inusual.',
      ),
    },
  ),
  GlossaryTerm(
    'takerratio',
    GlossaryCategory.volume,
    [
      'Taker',
      'Taker buy/sell ratio',
      'taker buy sell',
      'Taker alış/satış oranı',
      'alış satış oranı',
      'Ratio taker compra/venta',
      'order flow',
    ],
    {
      'tr': GlossaryEntry(
        'Taker alış/satış oranı',
        'Piyasa emriyle (taker) yapılan alımların satımlara oranı. 1\'in üstü alıcıların, altı satıcıların daha agresif olduğunu gösterir.',
      ),
      'en': GlossaryEntry(
        'Taker buy/sell ratio',
        'The ratio of buys to sells executed with market orders (takers). Above 1 means buyers are more aggressive, below 1 means sellers are.',
      ),
      'es': GlossaryEntry(
        'Ratio taker compra/venta',
        'La proporción entre compras y ventas ejecutadas con órdenes de mercado (takers). Por encima de 1 los compradores son más agresivos, por debajo lo son los vendedores.',
      ),
    },
  ),

  // ---------------------------------------------------------- Derivatives
  GlossaryTerm(
    'futures',
    GlossaryCategory.derivatives,
    [
      'Futures',
      'Perpetual',
      'perp',
      'vadeli işlem',
      'vadeli',
      'kaldıraç',
      'leverage',
      'Futuros',
      'swap perpetuo',
    ],
    {
      'tr': GlossaryEntry(
        'Vadeli işlem (Futures)',
        'Varlığın kendisini almadan, fiyatı üzerinden kaldıraçlı alım-satım yapılan türev sözleşme. Kripto\'da en yaygını vadesiz (perpetual) sözleşmedir; kaldıraç hem kazancı hem kaybı büyütür.',
      ),
      'en': GlossaryEntry(
        'Futures',
        'A derivative contract that lets you trade an asset\'s price, often with leverage, without owning the asset. In crypto the most common type is the perpetual contract; leverage magnifies both gains and losses.',
      ),
      'es': GlossaryEntry(
        'Futuros',
        'Contrato derivado que permite operar el precio de un activo, a menudo con apalancamiento, sin poseerlo. En cripto el más común es el contrato perpetuo; el apalancamiento amplifica tanto las ganancias como las pérdidas.',
      ),
    },
  ),
  GlossaryTerm(
    'funding',
    GlossaryCategory.derivatives,
    [
      'Funding rate',
      'Funding',
      'Fonlama oranı',
      'fonlama',
      'Tasa de financiación',
      'financiación',
    ],
    {
      'tr': GlossaryEntry(
        'Fonlama oranı (Funding rate)',
        'Vadesiz sözleşmelerde long ve short taraflar arasında periyodik (genelde 8 saatte bir) ödenen ücret. Pozitif oran longların shortlara ödediği, yani long ağırlığı olduğu; negatif oran tersi anlamına gelir. Çok uç değerler kalabalık pozisyonlanmaya işaret edebilir.',
      ),
      'en': GlossaryEntry(
        'Funding rate',
        'A periodic fee (often every 8 hours) paid between long and short traders on perpetual contracts. A positive rate means longs pay shorts, i.e. positioning leans long; a negative rate means the opposite. Very extreme values can point to crowded positioning.',
      ),
      'es': GlossaryEntry(
        'Tasa de financiación (funding)',
        'Comisión periódica (a menudo cada 8 horas) que se pagan entre largos y cortos en los contratos perpetuos. Una tasa positiva significa que los largos pagan a los cortos, es decir, el posicionamiento se inclina a largo; una negativa, lo contrario. Valores muy extremos pueden indicar posicionamiento saturado.',
      ),
    },
  ),
  GlossaryTerm(
    'openinterest',
    GlossaryCategory.derivatives,
    [
      'Open interest',
      'OI',
      'Açık pozisyon',
      'Açık pozisyon (OI)',
      'Interés abierto',
    ],
    {
      'tr': GlossaryEntry(
        'Açık pozisyon (OI)',
        'Henüz kapatılmamış tüm vadeli sözleşmelerin toplam değeri veya adedi. Fiyatla birlikte artan OI yeni para girişine, düşen OI pozisyonların kapandığına işaret eder; tek başına yön göstermez.',
      ),
      'en': GlossaryEntry(
        'Open interest (OI)',
        'The total value or number of futures contracts that are still open. OI rising along with price suggests new money entering, falling OI suggests positions are being closed; on its own it does not show direction.',
      ),
      'es': GlossaryEntry(
        'Interés abierto (OI)',
        'El valor o número total de contratos de futuros que siguen abiertos. Un OI que sube junto al precio sugiere entrada de dinero nuevo, uno que baja sugiere cierre de posiciones; por sí solo no indica dirección.',
      ),
    },
  ),
  GlossaryTerm(
    'longshort',
    GlossaryCategory.derivatives,
    [
      'Long/Short ratio',
      'Long Short',
      'L/S',
      'Long/Short oranı',
      'ratio long/short',
    ],
    {
      'tr': GlossaryEntry(
        'Long/Short oranı',
        'Long pozisyonların short pozisyonlara oranı. 1\'in üstü long, altı short ağırlığını gösterir; aşırı tek yönlü kalabalık, ters yönde sert bir hareketin yakıtı da olabilir.',
      ),
      'en': GlossaryEntry(
        'Long/Short ratio',
        'The ratio of long positions to short positions. Above 1 means longs dominate, below 1 shorts; an extremely one-sided crowd can also fuel a sharp move the other way.',
      ),
      'es': GlossaryEntry(
        'Ratio Long/Short',
        'La proporción de posiciones largas frente a cortas. Por encima de 1 dominan los largos, por debajo los cortos; una multitud muy unilateral también puede alimentar un movimiento brusco en sentido contrario.',
      ),
    },
  ),
  GlossaryTerm(
    'liquidation',
    GlossaryCategory.derivatives,
    ['Liquidation', 'Likidasyon', 'liquidations', 'Liquidación', 'margin call'],
    {
      'tr': GlossaryEntry(
        'Likidasyon',
        'Teminatı yetersiz kalan kaldıraçlı bir pozisyonun borsa tarafından zorla kapatılması. Yoğun likidasyonlar kısa sürede sert fiyat hareketlerine yol açabilir.',
      ),
      'en': GlossaryEntry(
        'Liquidation',
        'The forced closing of a leveraged position by the exchange when its margin is no longer sufficient. Heavy liquidations can cause sharp price moves in a short time.',
      ),
      'es': GlossaryEntry(
        'Liquidación',
        'El cierre forzoso de una posición apalancada por parte del exchange cuando su margen ya no es suficiente. Liquidaciones masivas pueden provocar movimientos bruscos de precio en poco tiempo.',
      ),
    },
  ),
  GlossaryTerm(
    'squeeze',
    GlossaryCategory.derivatives,
    ['Squeeze', 'short squeeze', 'long squeeze', 'sıkışma', 'estrujón'],
    {
      'tr': GlossaryEntry(
        'Squeeze',
        'Karşı taraftaki pozisyonları kapanmaya zorlayan hızlı fiyat hareketi. Short squeeze\'de yükselen fiyat shortları zararla kapattırır ve bu alımlar yükselişi hızlandırır; long squeeze bunun tersidir.',
      ),
      'en': GlossaryEntry(
        'Squeeze',
        'A fast price move that forces traders on the other side to close their positions. In a short squeeze, rising price makes shorts close at a loss and their buying speeds up the rally; a long squeeze is the reverse.',
      ),
      'es': GlossaryEntry(
        'Squeeze',
        'Movimiento rápido de precio que obliga a los operadores del lado contrario a cerrar posiciones. En un short squeeze, la subida obliga a los cortos a cerrar con pérdidas y sus compras aceleran el alza; el long squeeze es lo opuesto.',
      ),
    },
  ),
  GlossaryTerm(
    'basis',
    GlossaryCategory.derivatives,
    [
      'Basis',
      'Basis (vadeli-spot farkı)',
      'contango',
      'backwardation',
      'prim',
      'base',
    ],
    {
      'tr': GlossaryEntry(
        'Basis',
        'Vadeli işlem fiyatı ile spot fiyat arasındaki fark (genelde yüzde olarak). Pozitif basis (contango) vadelinin spotun üzerinde, negatif basis (backwardation) altında olduğunu gösterir.',
      ),
      'en': GlossaryEntry(
        'Basis',
        'The difference between the futures price and the spot price, usually shown as a percentage. A positive basis (contango) means futures trade above spot; a negative basis (backwardation) means below.',
      ),
      'es': GlossaryEntry(
        'Basis',
        'La diferencia entre el precio de los futuros y el precio spot, normalmente en porcentaje. Un basis positivo (contango) significa que los futuros cotizan por encima del spot; uno negativo (backwardation), por debajo.',
      ),
    },
  ),

  // --------------------------------------------------------------- Market
  GlossaryTerm(
    'marketcap',
    GlossaryCategory.market,
    [
      'Market cap',
      'Piyasa değeri',
      'MCap',
      'capitalización',
      'Capitalización de mercado',
    ],
    {
      'tr': GlossaryEntry(
        'Piyasa değeri',
        'Fiyat ile dolaşımdaki arzın çarpımı. Bir coin\'in göreli büyüklüğünü gösterir; büyük piyasa değerli coinler genelde daha likit ve daha az oynaktır.',
      ),
      'en': GlossaryEntry(
        'Market cap',
        'Price multiplied by circulating supply. It shows a coin\'s relative size; large-cap coins are generally more liquid and less volatile.',
      ),
      'es': GlossaryEntry(
        'Capitalización de mercado',
        'El precio multiplicado por el suministro circulante. Muestra el tamaño relativo de una moneda; las de gran capitalización suelen ser más líquidas y menos volátiles.',
      ),
    },
  ),
  GlossaryTerm(
    'rank',
    GlossaryCategory.market,
    [
      'Rank',
      'Sıralama',
      'Sıralama (rank)',
      'market cap rank',
      'Clasificación',
      'ranking',
    ],
    {
      'tr': GlossaryEntry(
        'Sıralama (rank)',
        'Coin\'in piyasa değerine göre sıralamadaki yeri; 1 en büyüktür. Sıra numarası küçüldükçe coin genelde daha büyük ve daha likittir.',
      ),
      'en': GlossaryEntry(
        'Rank',
        'A coin\'s position when all coins are ordered by market cap; 1 is the largest. A lower rank number generally means a larger, more liquid asset.',
      ),
      'es': GlossaryEntry(
        'Ranking',
        'La posición de una moneda al ordenar todas por capitalización; 1 es la mayor. Un número de ranking menor suele indicar un activo más grande y líquido.',
      ),
    },
  ),
  GlossaryTerm(
    'volmcap',
    GlossaryCategory.market,
    [
      'Volume / market cap',
      'Hacim/piyasa değeri',
      'Hacim piyasa değeri',
      'turnover',
      'Volumen / capitalización',
    ],
    {
      'tr': GlossaryEntry(
        'Hacim / piyasa değeri',
        '24 saatlik işlem hacminin piyasa değerine oranı; coin\'in ne kadar el değiştirdiğini gösterir. Yüksek oran yüksek aktiviteyi, çok düşük oran ilginin azlığını gösterebilir; normal aralık coin büyüklüğüne göre değişir.',
      ),
      'en': GlossaryEntry(
        'Volume / market cap',
        '24-hour trading volume divided by market cap; it shows how actively a coin changes hands. A high ratio can mean heavy activity and a very low one little interest; the normal range depends on the coin\'s size.',
      ),
      'es': GlossaryEntry(
        'Volumen / capitalización',
        'Volumen de 24 horas dividido por la capitalización de mercado; muestra lo activamente que cambia de manos una moneda. Una proporción alta puede indicar mucha actividad y una muy baja poco interés; el rango normal depende del tamaño de la moneda.',
      ),
    },
  ),
  GlossaryTerm(
    'fdv',
    GlossaryCategory.market,
    [
      'FDV',
      'Fully Diluted Valuation',
      'Tam seyreltilmiş değer',
      'Valoración totalmente diluida',
      'FDMC',
    ],
    {
      'tr': GlossaryEntry(
        'FDV (Tam seyreltilmiş değer)',
        'Maksimum arzın tamamı dolaşıma girseydi oluşacak piyasa değeri (fiyat × maks. arz). FDV piyasa değerinden çok büyükse ileride dolaşıma girecek çok sayıda coin var, yani seyrelme riski var demektir.',
      ),
      'en': GlossaryEntry(
        'FDV (Fully Diluted Valuation)',
        'The market cap if the entire maximum supply were in circulation (price × max supply). If FDV is far above market cap, many coins are yet to enter circulation, meaning dilution risk.',
      ),
      'es': GlossaryEntry(
        'FDV (Valoración totalmente diluida)',
        'La capitalización que habría si todo el suministro máximo estuviera en circulación (precio × suministro máx.). Si el FDV es muy superior a la capitalización, quedan muchas monedas por entrar en circulación, lo que implica riesgo de dilución.',
      ),
    },
  ),
  GlossaryTerm(
    'supply',
    GlossaryCategory.market,
    [
      'Circulating supply',
      'Max supply',
      'Total supply',
      'Dolaşım arzı',
      'Maks. arz',
      'Maksimum arz',
      'Suministro circulante',
      'arz',
    ],
    {
      'tr': GlossaryEntry(
        'Dolaşım arzı / maks. arz',
        'Dolaşım arzı piyasada fiilen işlem gören coin miktarıdır; maksimum arz ise ulaşılabilecek en yüksek miktardır (bazı coinlerde sınır yoktur). İkisi arasındaki fark ne kadar büyükse ileride yeni arz girişi o kadar fazladır.',
      ),
      'en': GlossaryEntry(
        'Circulating / max supply',
        'Circulating supply is the amount of a coin actually trading in the market; max supply is the highest amount that can ever exist (some coins have no cap). The bigger the gap between them, the more new supply is still to come.',
      ),
      'es': GlossaryEntry(
        'Suministro circulante / máximo',
        'El suministro circulante es la cantidad de una moneda que realmente cotiza en el mercado; el máximo es la mayor cantidad que podrá existir (algunas monedas no tienen límite). Cuanto mayor la diferencia, más suministro nuevo queda por llegar.',
      ),
    },
  ),
  GlossaryTerm(
    'btcdominance',
    GlossaryCategory.market,
    [
      'BTC dominance',
      'BTC.D',
      'BTC dominansı',
      'dominans',
      'Dominancia de BTC',
    ],
    {
      'tr': GlossaryEntry(
        'BTC dominansı',
        'Bitcoin\'in toplam kripto piyasa değerindeki yüzde payı. Yükselirken para BTC\'ye yöneliyor, düşerken altcoinlere yayılıyor şeklinde yorumlanır; tek başına kesin bir sinyal değildir.',
      ),
      'en': GlossaryEntry(
        'BTC dominance',
        'Bitcoin\'s percentage share of the total crypto market cap. Rising is often read as money moving into BTC, falling as money spreading to altcoins; on its own it is not a definitive signal.',
      ),
      'es': GlossaryEntry(
        'Dominancia de BTC',
        'El porcentaje de Bitcoin sobre la capitalización total del mercado cripto. Si sube se suele leer como dinero que va hacia BTC, y si baja como dinero que se reparte hacia las altcoins; por sí sola no es una señal definitiva.',
      ),
    },
  ),
  GlossaryTerm(
    'feargreed',
    GlossaryCategory.market,
    [
      'Fear & Greed',
      'Fear and Greed Index',
      'Korku ve Açgözlülük',
      'Korku & Açgözlülük endeksi',
      'FNG',
      'Índice de miedo y codicia',
      'sentiment',
      'duyarlılık',
    ],
    {
      'tr': GlossaryEntry(
        'Korku & Açgözlülük endeksi',
        'Piyasa duyarlılığını 0-100 arasında özetleyen endeks. Düşük değerler korkuyu, yüksek değerler açgözlülüğü gösterir; yaklaşık 25 altı aşırı korku, 75 üstü aşırı açgözlülük olarak okunur.',
      ),
      'en': GlossaryEntry(
        'Fear & Greed Index',
        'An index summarizing market sentiment on a 0-100 scale. Low values show fear and high values greed; below roughly 25 is read as extreme fear and above 75 as extreme greed.',
      ),
      'es': GlossaryEntry(
        'Índice de miedo y codicia',
        'Índice que resume el sentimiento del mercado en una escala de 0 a 100. Los valores bajos indican miedo y los altos codicia; por debajo de ~25 se lee como miedo extremo y por encima de 75 como codicia extrema.',
      ),
    },
  ),
  GlossaryTerm(
    'correlation',
    GlossaryCategory.market,
    ['Correlation', 'Korelasyon', 'Correlación', 'ilişki'],
    {
      'tr': GlossaryEntry(
        'Korelasyon',
        'İki varlığın birlikte ne kadar hareket ettiğini -1 ile +1 arasında gösterir. +1\'e yakın değer birlikte hareketi, 0 ilişkisizliği, -1\'e yakın değer zıt yönlü hareketi ifade eder.',
      ),
      'en': GlossaryEntry(
        'Correlation',
        'Shows how closely two assets move together, from -1 to +1. Near +1 they move together, near 0 they are unrelated, and near -1 they move in opposite directions.',
      ),
      'es': GlossaryEntry(
        'Correlación',
        'Muestra lo parecido que es el movimiento de dos activos, de -1 a +1. Cerca de +1 se mueven juntos, cerca de 0 no tienen relación y cerca de -1 se mueven en sentido opuesto.',
      ),
    },
  ),
  GlossaryTerm(
    'beta',
    GlossaryCategory.market,
    ['Beta', 'Beta (β)', 'β', 'sensibilidad'],
    {
      'tr': GlossaryEntry(
        'Beta',
        'Bir varlığın referans varlığın (genelde BTC) hareketine duyarlılığı. Beta 1 ise aynı oranda, 1\'den büyükse referanstan daha sert, 1\'den küçükse daha yumuşak hareket etmesi beklenir.',
      ),
      'en': GlossaryEntry(
        'Beta',
        'An asset\'s sensitivity to the moves of a reference asset (usually BTC). A beta of 1 means it tends to move by the same proportion, above 1 more sharply, below 1 more mildly.',
      ),
      'es': GlossaryEntry(
        'Beta',
        'La sensibilidad de un activo a los movimientos de un activo de referencia (normalmente BTC). Una beta de 1 indica que tiende a moverse en la misma proporción, mayor de 1 de forma más brusca y menor de 1 de forma más suave.',
      ),
    },
  ),

  // ------------------------------------------------------------- Concepts
  GlossaryTerm(
    'riskreward',
    GlossaryCategory.concepts,
    [
      'Risk/Reward',
      'Risk/Ödül',
      'R',
      'R/R',
      'RR',
      'Riesgo/Beneficio',
      'risk ödül',
    ],
    {
      'tr': GlossaryEntry(
        'Risk/Ödül (R)',
        'Hedefe olan potansiyel mesafenin, geçersiz kılma seviyesine olan riske oranı. 2R, potansiyel kazancın riskin iki katı olduğunu gösterir; gerçekleşme olasılığını değil, yalnızca bu oranı anlatır.',
      ),
      'en': GlossaryEntry(
        'Risk/Reward (R)',
        'The distance to the target divided by the distance to the invalidation level. 2R means the potential gain is twice the risk; it describes only this ratio, not the probability of it playing out.',
      ),
      'es': GlossaryEntry(
        'Riesgo/Beneficio (R)',
        'La distancia al objetivo dividida por la distancia al nivel de invalidación. 2R significa que la ganancia potencial es el doble del riesgo; describe solo esta proporción, no la probabilidad de que ocurra.',
      ),
    },
  ),
  GlossaryTerm(
    'scenario',
    GlossaryCategory.concepts,
    ['Scenario', 'Senaryo', 'Escenario', 'bull case', 'base case', 'bear case'],
    {
      'tr': GlossaryEntry(
        'Senaryo',
        'Fiyatın izleyebileceği olası yollar (ör. boğa, temel, ayı) ve her birinin koşulları. Kesin bir tahmin değil, farklı durumlara hazırlıklı olmak için kullanılan bir çerçevedir.',
      ),
      'en': GlossaryEntry(
        'Scenario',
        'The possible paths price could take (e.g. bull, base, bear) and the conditions for each. It is not a firm forecast but a framework for being prepared for different outcomes.',
      ),
      'es': GlossaryEntry(
        'Escenario',
        'Los posibles caminos que podría seguir el precio (p. ej. alcista, base, bajista) y las condiciones de cada uno. No es una previsión firme sino un marco para estar preparado ante distintos resultados.',
      ),
    },
  ),
  GlossaryTerm(
    'confidence',
    GlossaryCategory.concepts,
    [
      'Confidence',
      'Confidence score',
      'Güven skoru',
      'güven',
      'Confianza',
      'Puntuación de confianza',
    ],
    {
      'tr': GlossaryEntry(
        'Güven skoru',
        'Analizin kendi sinyallerinin ne kadar uyumlu olduğunu 0-100 arasında gösteren değer. Gerçekleşme olasılığı garantisi değildir; yüksek skor bile sonucun kesin olduğu anlamına gelmez.',
      ),
      'en': GlossaryEntry(
        'Confidence score',
        'A 0-100 value showing how well the analysis\'s own signals agree with each other. It is not a guarantee of probability; even a high score does not mean the outcome is certain.',
      ),
      'es': GlossaryEntry(
        'Puntuación de confianza',
        'Valor de 0 a 100 que muestra cuánto coinciden entre sí las señales del propio análisis. No es una garantía de probabilidad; incluso una puntuación alta no significa que el resultado sea seguro.',
      ),
    },
  ),
  GlossaryTerm(
    'candle',
    GlossaryCategory.concepts,
    [
      'Forming candle',
      'Closed candle',
      'open candle',
      'mum',
      'oluşan mum',
      'kapanmış mum',
      'açık mum',
      'Vela abierta',
      'Vela cerrada',
      'candlestick',
    ],
    {
      'tr': GlossaryEntry(
        'Oluşan (açık) mum ve kapanmış mum',
        'Kapanmış mum tamamlanmış ve artık değişmeyen veridir; oluşan (açık) mum henüz devam eder ve kapanışa kadar değişir. Açık mumdaki gösterge değerleri yanıltıcı olabilir, bu yüzden teyit için çoğunlukla kapanmış mumlara bakılır.',
      ),
      'en': GlossaryEntry(
        'Forming (open) vs closed candle',
        'A closed candle is complete and no longer changes; a forming (open) candle is still in progress and changes until it closes. Indicator values on an open candle can be misleading, so confirmation is usually taken from closed candles.',
      ),
      'es': GlossaryEntry(
        'Vela en formación (abierta) y vela cerrada',
        'Una vela cerrada está completa y ya no cambia; una vela en formación (abierta) sigue en curso y cambia hasta su cierre. Los valores de los indicadores en una vela abierta pueden engañar, por lo que la confirmación suele tomarse de velas cerradas.',
      ),
    },
  ),
  GlossaryTerm(
    'timeframe',
    GlossaryCategory.concepts,
    [
      'Timeframe',
      'Horizon',
      'Zaman dilimi',
      'horizon',
      'ufuk',
      'Marco temporal',
      'Horizonte',
      'interval',
    ],
    {
      'tr': GlossaryEntry(
        'Zaman dilimi / horizon',
        'Her mumun temsil ettiği süre (15 dk, 1 saat, 1 gün gibi) ve analizin baktığı ufuk. Kısa zaman dilimleri daha fazla gürültü, uzun zaman dilimleri daha yavaş ama daha belirgin eğilimler gösterir.',
      ),
      'en': GlossaryEntry(
        'Timeframe / horizon',
        'The period each candle represents (15 min, 1 hour, 1 day, etc.) and the span the analysis looks over. Short timeframes show more noise; longer ones show slower but clearer trends.',
      ),
      'es': GlossaryEntry(
        'Marco temporal / horizonte',
        'El periodo que representa cada vela (15 min, 1 hora, 1 día, etc.) y el plazo que cubre el análisis. Los marcos cortos muestran más ruido; los largos muestran tendencias más lentas pero más claras.',
      ),
    },
  ),
  GlossaryTerm(
    'bullbear',
    GlossaryCategory.concepts,
    [
      'Bull',
      'Bear',
      'Bullish',
      'Bearish',
      'Boğa',
      'Ayı',
      'Boğa/Ayı',
      'Alcista',
      'Bajista',
    ],
    {
      'tr': GlossaryEntry(
        'Boğa / Ayı',
        'Boğa (bullish), fiyatların yükseleceği beklentisini veya yükselen piyasayı; ayı (bearish), düşeceği beklentisini veya düşen piyasayı anlatır. Analizdeki yön etiketi, mevcut verilerin hangi tarafı desteklediğini özetler.',
      ),
      'en': GlossaryEntry(
        'Bull / Bear',
        'Bullish describes an expectation of rising prices or a rising market; bearish describes an expectation of falling prices or a falling market. The direction label in an analysis summarizes which side the current data supports.',
      ),
      'es': GlossaryEntry(
        'Alcista / Bajista (toro / oso)',
        'Alcista (bullish) describe la expectativa de subida de precios o un mercado al alza; bajista (bearish), la expectativa de caída o un mercado a la baja. La etiqueta de dirección de un análisis resume qué lado respaldan los datos actuales.',
      ),
    },
  ),
  GlossaryTerm(
    'overbought',
    GlossaryCategory.concepts,
    [
      'Overbought',
      'Oversold',
      'Aşırı alım',
      'Aşırı satım',
      'aşırı alım/aşırı satım',
      'Sobrecompra',
      'Sobreventa',
    ],
    {
      'tr': GlossaryEntry(
        'Aşırı alım / aşırı satım',
        'Göstergelerin fiyatın kısa sürede çok hızlı yükseldiğini (aşırı alım) veya düştüğünü (aşırı satım) gösterdiği durum. Bir geri çekilme ihtimalini hatırlatır ama güçlü trendlerde fiyat bu bölgede uzun süre kalabilir.',
      ),
      'en': GlossaryEntry(
        'Overbought / oversold',
        'A state where indicators show price has risen very quickly (overbought) or fallen very quickly (oversold). It signals that a pullback is possible, but in strong trends price can stay in these zones for a long time.',
      ),
      'es': GlossaryEntry(
        'Sobrecompra / sobreventa',
        'Estado en el que los indicadores muestran que el precio ha subido muy rápido (sobrecompra) o caído muy rápido (sobreventa). Recuerda que es posible un retroceso, pero en tendencias fuertes el precio puede permanecer mucho tiempo en estas zonas.',
      ),
    },
  ),
  GlossaryTerm(
    'regime',
    GlossaryCategory.concepts,
    ['Regime', 'Market regime', 'Rejim', 'Piyasa rejimi', 'Régimen'],
    {
      'tr': GlossaryEntry(
        'Rejim',
        'Piyasanın içinde bulunduğu genel durum: örneğin trendli veya yatay, düşük veya yüksek oynaklık. Aynı gösterge farklı rejimlerde farklı anlam taşıdığı için yorumlar önce rejimi dikkate alır.',
      ),
      'en': GlossaryEntry(
        'Regime',
        'The overall state the market is in, for example trending or sideways, low or high volatility. Because the same indicator means different things in different regimes, interpretation starts with the regime.',
      ),
      'es': GlossaryEntry(
        'Régimen',
        'El estado general en que se encuentra el mercado, por ejemplo con tendencia o lateral, de baja o alta volatilidad. Como un mismo indicador significa cosas distintas en regímenes distintos, la interpretación empieza por el régimen.',
      ),
    },
  ),
  GlossaryTerm(
    'baserate',
    GlossaryCategory.concepts,
    [
      'Base rate',
      'Taban oranı',
      'Tasa base',
      'historical frequency',
      'tarihsel oran',
    ],
    {
      'tr': GlossaryEntry(
        'Taban oranı (base rate)',
        'Benzer durumlarda bir sonucun tarihsel olarak ne sıklıkla gerçekleştiği. Belirli bir senaryoyu değerlendirmeden önceki başlangıç noktasıdır; geçmiş oran gelecekte de aynı olacağını garanti etmez.',
      ),
      'en': GlossaryEntry(
        'Base rate',
        'How often an outcome has historically occurred in similar situations. It is the starting point before judging a specific scenario; a past rate does not guarantee the same in the future.',
      ),
      'es': GlossaryEntry(
        'Tasa base (base rate)',
        'Con qué frecuencia ha ocurrido históricamente un resultado en situaciones similares. Es el punto de partida antes de juzgar un escenario concreto; una tasa pasada no garantiza lo mismo en el futuro.',
      ),
    },
  ),
];
