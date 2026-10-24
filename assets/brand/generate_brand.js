// Brand mark generator: SVG sources + PNG renders (sharp). Mark = ring "C" + three ascending candles + AI spark.
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const OUT = process.argv[2] || path.join(__dirname, 'out');
fs.mkdirSync(OUT, { recursive: true });

const TEAL = '#12d6a0', TEAL2 = '#3ee0b4', CYAN = '#38bdf8', UP = '#19c37d', DOWN = '#ef5b5b', SPARK = '#ffd166';

// Ring C: center (256,256) r=148, open to the right (gap between -38deg and +38deg).
function ringPath(cx, cy, r, gapDeg) {
  const a1 = (gapDeg * Math.PI) / 180;
  const sx = cx + r * Math.cos(a1), sy = cy + r * Math.sin(a1);          // lower-right end
  const ex = cx + r * Math.cos(-a1), ey = cy + r * Math.sin(-a1);        // upper-right end
  return `M ${sx.toFixed(1)} ${sy.toFixed(1)} A ${r} ${r} 0 1 1 ${ex.toFixed(1)} ${ey.toFixed(1)}`;
}

function spark(cx, cy, s, fill) {
  // four-point star
  const k = s * 0.22;
  return `<path d="M ${cx} ${cy - s} Q ${cx + k} ${cy - k} ${cx + s} ${cy} Q ${cx + k} ${cy + k} ${cx} ${cy + s} Q ${cx - k} ${cy + k} ${cx - s} ${cy} Q ${cx - k} ${cy - k} ${cx} ${cy - s} Z" fill="${fill}"/>`;
}

function candle(x, w, wickTop, bodyTop, bodyBottom, wickBottom, color) {
  const cx = x + w / 2;
  return `<line x1="${cx}" y1="${wickTop}" x2="${cx}" y2="${wickBottom}" stroke="${color}" stroke-width="10" stroke-linecap="round"/>
  <rect x="${x}" y="${bodyTop}" width="${w}" height="${bodyBottom - bodyTop}" rx="9" fill="${color}"/>`;
}

// mark in a 512x512 box (content centred); `mono` -> single colour silhouette
function markBody({ mono = null } = {}) {
  const ringStroke = mono || 'url(#ring)';
  const g = mono ? mono : null;
  const c1 = g || UP, c2 = g || DOWN, c3 = g || UP;
  return `
  <path d="${ringPath(256, 256, 150, 40)}" fill="none" stroke="${ringStroke}" stroke-width="42" stroke-linecap="round"/>
  ${candle(176, 38, 268, 290, 340, 356, c1)}
  ${candle(230, 38, 218, 242, 310, 330, c2)}
  ${candle(284, 38, 170, 194, 276, 296, c3)}
  ${spark(390, 126, 38, mono || SPARK)}`;
}

const defs = `
  <defs>
    <linearGradient id="ring" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="${TEAL}"/><stop offset="1" stop-color="${CYAN}"/>
    </linearGradient>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#14213d"/><stop offset="0.55" stop-color="#0b1220"/><stop offset="1" stop-color="#060a12"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.55" r="0.55">
      <stop offset="0" stop-color="${TEAL}" stop-opacity="0.28"/><stop offset="1" stop-color="${TEAL}" stop-opacity="0"/>
    </radialGradient>
  </defs>`;

// full tile (legacy / store icon): background + glow + mark, mark scaled slightly to fill
function tileSvg(size = 512) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 512 512">${defs}
  <rect width="512" height="512" fill="url(#bg)"/>
  <rect width="512" height="512" fill="url(#glow)"/>
  <g transform="translate(256 256) scale(1.0) translate(-256 -256)">${markBody()}</g>
</svg>`;
}

// transparent mark only (website logo, adaptive foreground)
function markSvg(scale = 1, size = 512, mono = null) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 512 512">${mono ? '' : defs}
  <g transform="translate(256 256) scale(${scale}) translate(-256 -256)">${markBody({ mono })}</g>
</svg>`;
}

async function png(svg, file, size) {
  await sharp(Buffer.from(svg)).resize(size, size).png().toFile(path.join(OUT, file));
}

(async () => {
  fs.writeFileSync(path.join(OUT, 'logo-tile.svg'), tileSvg());
  fs.writeFileSync(path.join(OUT, 'logo-mark.svg'), markSvg(1));
  await png(tileSvg(1024), 'icon_legacy.png', 1024);          // flutter_launcher_icons image_path
  await png(tileSvg(512), 'icon_512.png', 512);               // Play Store icon
  // Adaptive foreground: keep the mark inside the 66% safe zone of a 1024 canvas (scale 0.62 of the 512 design)
  await png(markSvg(1.0, 1024), 'icon_foreground.png', 1024);
  await png(markSvg(1.0, 1024, '#ffffff'), 'icon_monochrome.png', 1024);
  // small previews
  await png(tileSvg(96), 'preview_96.png', 96);
  await png(tileSvg(48), 'preview_48.png', 48);
  console.log('done', OUT);
})();

// ---------------------------------------------------------------- feature graphic 1024x500 (+ OG image 1200x630)
function featureSvg(w, h, tagline, markScale, markX) {
  const gridLines = [];
  for (let y = 60; y < h; y += 80) gridLines.push(`<line x1="0" y1="${y}" x2="${w}" y2="${y}" stroke="#ffffff" stroke-opacity="0.045" stroke-width="2"/>`);
  const titleSize = Math.round(w * 0.082), tagSize = Math.round(w * 0.033);
  const tx = Math.round(w * 0.062), ty = Math.round(h * 0.44);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  ${defs}
  <defs>
    <linearGradient id="fbg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0b0f17"/><stop offset="1" stop-color="#101c33"/></linearGradient>
    <radialGradient id="fglow" cx="${(markX + 256 * markScale) / w}" cy="0.52" r="0.5"><stop offset="0" stop-color="${TEAL}" stop-opacity="0.30"/><stop offset="1" stop-color="${TEAL}" stop-opacity="0"/></radialGradient>
  </defs>
  <rect width="${w}" height="${h}" fill="url(#fbg)"/>
  ${gridLines.join('\n  ')}
  <rect width="${w}" height="${h}" fill="url(#fglow)"/>
  <g transform="translate(${markX} ${(h - 512 * markScale) / 2}) scale(${markScale})">${markBody()}</g>
  <text x="${tx}" y="${ty}" font-family="Segoe UI, Arial, sans-serif" font-weight="700" font-size="${titleSize}" fill="#e8edf5">Crypto<tspan fill="${TEAL2}">Analiz</tspan></text>
  ${tagline.map((line, i) => `<text x="${tx}" y="${ty + Math.round(tagSize * (1.9 + i * 1.3))}" font-family="Segoe UI, Arial, sans-serif" font-weight="400" font-size="${tagSize}" fill="#a7b3c6">${line}</text>`).join('')}
  <rect x="${tx}" y="${ty + Math.round(tagSize * (1.9 + tagline.length * 1.3 + 0.2))}" width="${Math.round(w * 0.09)}" height="8" rx="4" fill="${TEAL}"/>
</svg>`;
}

(async () => {
  const taglines = {
    en: ['Crypto signals, radar', '&amp; AI analysis'],
    tr: ['Kripto sinyalleri, radar','ve yapay zekâ analizi'],
    es: ['Señales, radar', 'y análisis con IA'],
  };
  for (const [lang, t] of Object.entries(taglines)) {
    const svg = featureSvg(1024, 500, t, 0.9, 560);
    fs.writeFileSync(path.join(OUT, `feature_graphic_${lang}.svg`), svg);
    await sharp(Buffer.from(svg)).png().toFile(path.join(OUT, `feature_graphic_1024x500_${lang}.png`));
  }
  const og = featureSvg(1200, 630, taglines.en, 1.1, 640);
  await sharp(Buffer.from(og)).png().toFile(path.join(OUT, 'og-image.png'));
  console.log('feature graphics done');
})();
