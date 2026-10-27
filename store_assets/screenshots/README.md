# Play Store screenshots

Branded 1080x1920 phone screenshots per listing language: `en/`, `tr/`, `es/`
(`01-home` ... `08-glossary`, same order everywhere).

Pipeline (`sh tool/store_screenshots.sh`):

1. `test/store_screenshots/` renders the real, localized app screens in the dark
   theme with sanitized demo data (no real account) via `flutter test`
   (`STORE_SHOTS=1`), 1080x2400, into `raw/render/<lang>/` (git-ignored).
   No device is involved. `tool/patch_kchart_font.sh` temporarily gives the
   vendored k_chart an explicit Roboto family so chart labels render.
2. `assets/brand/compose_screenshots.js <raw> <out> <lang> gradient` crops the
   system bars, frames the screen on the gradient and adds the caption.
   Captions live in the `CAPTIONS` table of that script.

Captions (en / tr / es)

| Image | en | tr | es |
|---|---|---|---|
| 01-home | Market pulse at a glance | Piyasa nabzı tek bakışta | El pulso del mercado de un vistazo |
| 02-chart | Live charts & indicator signals | Canlı grafikler ve gösterge sinyalleri | Gráficos en vivo y señales de indicadores |
| 03-deep-analysis | Deep analysis in plain language | Derin analiz, sade bir dille | Análisis profundo en lenguaje sencillo |
| 04-coin-summary | Coin data & market structure | Coin verileri ve piyasa yapısı | Datos de la moneda y estructura de mercado |
| 05-market | Derivatives & liquidity insight | Türev ve likidite görünümü | Derivados y liquidez |
| 06-radar | Radar spots oversold setups | Radar aşırı satım fırsatlarını tarar | El radar detecta sobreventas |
| 07-watchlist | Watchlist & price alerts | Takip listesi ve fiyat alarmları | Lista de seguimiento y alertas de precio |
| 08-glossary | Every term, clearly explained | Her terim, açıkça anlatılır | Cada término, bien explicado |

Play rules checked: PNG, no alpha, 1080x1920 (9:16), < 8 MB.
