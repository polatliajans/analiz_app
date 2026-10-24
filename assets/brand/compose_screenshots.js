// Store screenshot composer: raw phone screenshot -> branded 1080x1920 marketing image.
// usage: node compose.js <rawDir> <outDir> <lang>
const fs = require('fs'), path = require('path'), sharp = require('sharp');

const [rawDir, outDir, lang, STYLE = 'dark'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });

const CAPTIONS = {
  '03-deep-analysis': { en: ['Deep analysis in', 'plain language'],  tr: ['Derin analiz,', 'sade bir dille'],      es: ['Análisis profundo', 'en lenguaje sencillo'] },
  '04-coin-summary':  { en: ['Coin data &', 'market structure'],     tr: ['Coin verileri ve', 'piyasa yapısı'],     es: ['Datos de la moneda y', 'estructura de mercado'] },
  '05-market':        { en: ['Derivatives &', 'liquidity insight'],  tr: ['Türev ve likidite', 'görünümü'],         es: ['Derivados y', 'liquidez'] },
  '06-radar':         { en: ['Radar spots', 'oversold setups'],      tr: ['Radar aşırı satım', 'fırsatlarını tarar'], es: ['El radar detecta', 'sobreventas'] },
  '07-watchlist':     { en: ['Watchlist &', 'price alerts'],         tr: ['Takip listesi ve', 'fiyat alarmları'],   es: ['Lista de seguimiento', 'y alertas de precio'] },
  '08-glossary':      { en: ['Every term,', 'clearly explained'],    tr: ['Her terim,', 'açıkça anlatılır'],        es: ['Cada término,', 'bien explicado'] },
  '01-home':     { en: ['Market pulse', 'at a glance'],        tr: ['Piyasa nabzı', 'tek bakışta'],          es: ['El pulso del mercado', 'de un vistazo'] },
  '02-chart':    { en: ['Live charts &', 'indicator signals'], tr: ['Canlı grafikler ve', 'gösterge sinyalleri'], es: ['Gráficos en vivo y', 'señales de indicadores'] },
  '03-deep':     { en: ['Deep analysis in', 'plain language'],  tr: ['Derin analiz,', 'sade bir dille'],      es: ['Análisis profundo', 'en lenguaje sencillo'] },
  '04-radar':    { en: ['Radar spots', 'oversold setups'],      tr: ['Radar aşırı satım', 'fırsatlarını tarar'], es: ['El radar detecta', 'sobreventas'] },
  '05-overview': { en: ['Coin data &', 'market structure'],     tr: ['Coin verileri ve', 'piyasa yapısı'],     es: ['Datos de la moneda y', 'estructura de mercado'] },
  '06-watchlist':{ en: ['Watchlist &', 'price alerts'],         tr: ['Takip listesi ve', 'fiyat alarmları'],   es: ['Lista de seguimiento', 'y alertas de precio'] },
  '07-glossary': { en: ['Every term,', 'clearly explained'],    tr: ['Her terim,', 'açıkça anlatılır'],        es: ['Cada término,', 'bien explicado'] },
  '08-market':   { en: ['Derivatives &', 'liquidity insight'],     tr: ['Türev ve likidite', 'görünümü'],         es: ['Derivados y', 'liquidez'] },
  '08-credits':  { en: ['Simple, transparent', 'credits'],      tr: ['Basit ve şeffaf', 'krediler'],           es: ['Créditos simples', 'y transparentes'] },
};

const W = 1080, H = 1920;
const CROP_TOP = 96, CROP_BOTTOM = 2268;           // remove status bar + system navigation (1080x2400 source)
const PHONE_W = 860, RADIUS = 56, BORDER = 6;
const PHONE_X = Math.round((W - PHONE_W) / 2), PHONE_Y = 380;

const STYLES = {
  dark:     { bg0: '#0b0f17', bg1: '#112038', glow: '#12d6a0', glowOp: 0.26, t1: '#e8edf5', t2: '#3ee0b4', bar: '#12d6a0', border: '#2b3b5c', shadowOp: 0.55 },
  gradient: { bg0: '#0fb88e', bg1: '#2563eb', glow: '#ffffff', glowOp: 0.18, t1: '#ffffff', t2: '#d8fff3', bar: '#ffffff', border: '#e6f2ff', shadowOp: 0.45 },
  light:    { bg0: '#f4f8fd', bg1: '#dbe8f7', glow: '#12d6a0', glowOp: 0.22, t1: '#0b1220', t2: '#0a9f78', bar: '#12d6a0', border: '#0b1220', shadowOp: 0.30 },
};
const ST = STYLES[STYLE] || STYLES.dark;

function bgSvg(cap) {
  const lines = (CAPTIONS[cap.key] || {})[lang] || ['', ''];
  const tspans = lines.map((l, i) => `<text x="${W / 2}" y="${150 + i * 84}" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-weight="700" font-size="78" fill="${i === 1 ? ST.t2 : ST.t1}">${l.replace(/&/g, '&amp;')}</text>`).join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${ST.bg0}"/><stop offset="1" stop-color="${ST.bg1}"/></linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.62" r="0.6"><stop offset="0" stop-color="${ST.glow}" stop-opacity="${ST.glowOp}"/><stop offset="1" stop-color="${ST.glow}" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bg)"/>
  <rect width="${W}" height="${H}" fill="url(#glow)"/>
  ${tspans}
  <rect x="${W / 2 - 60}" y="${150 + 84 + 40}" width="120" height="8" rx="4" fill="${ST.bar}"/>
</svg>`;
}

(async () => {
  const files = fs.readdirSync(rawDir).filter(f => f.endsWith('.png')).sort();
  for (const f of files) {
    const key = f.replace(/\.png$/, '');
    const src = sharp(path.join(rawDir, f));
    const meta = await src.metadata();
    const crop = await src.extract({ left: 0, top: CROP_TOP, width: meta.width, height: Math.min(CROP_BOTTOM, meta.height) - CROP_TOP }).toBuffer();
    const phoneH = Math.round(PHONE_W * ((Math.min(CROP_BOTTOM, meta.height) - CROP_TOP) / meta.width));
    const scaled = await sharp(crop).resize(PHONE_W, phoneH).toBuffer();
    const mask = Buffer.from(`<svg width="${PHONE_W}" height="${phoneH}"><rect width="${PHONE_W}" height="${phoneH}" rx="${RADIUS}" fill="#fff"/></svg>`);
    const rounded = await sharp(scaled).composite([{ input: mask, blend: 'dest-in' }]).png().toBuffer();
    const frame = Buffer.from(`<svg width="${PHONE_W + 2 * BORDER}" height="${phoneH + 2 * BORDER}"><rect x="${BORDER / 2}" y="${BORDER / 2}" width="${PHONE_W + BORDER}" height="${phoneH + BORDER}" rx="${RADIUS + BORDER / 2}" fill="none" stroke="${ST.border}" stroke-width="${BORDER}"/></svg>`);
    const shadow = Buffer.from(`<svg width="${W}" height="${H}"><defs><filter id="b" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="28"/></filter></defs><rect x="${PHONE_X + 10}" y="${PHONE_Y + 30}" width="${PHONE_W}" height="${phoneH}" rx="${RADIUS}" fill="#000" fill-opacity="${ST.shadowOp}" filter="url(#b)"/></svg>`);
    const bg = Buffer.from(bgSvg({ key }));
    const out = await sharp(bg)
      .composite([
        { input: shadow, left: 0, top: 0 },
        { input: rounded, left: PHONE_X, top: PHONE_Y },
        { input: frame, left: PHONE_X - BORDER, top: PHONE_Y - BORDER },
      ])
      .png().toBuffer();
    // the phone bleeds off the bottom edge: crop the canvas to H
    await sharp(out).extract({ left: 0, top: 0, width: W, height: H }).png().toFile(path.join(outDir, `${key}.png`));
    console.log('ok', key, `${W}x${H}`);
  }
})();
