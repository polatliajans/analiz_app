# App Store screenshots (iPhone 6.9")

Branded 1320x2868 PNG phone screenshots (no alpha) per listing language: `en/`,
`tr/`, `es/` (`01-home` ... `08-glossary`, same order and captions as the Play
set in `../screenshots/`, see its README for the caption table).

iOS specifics: rendered with `proPurchaseAvailableProvider` overridden to
`false` (as on iOS), so the home screen shows the full-width credit card and no
Pro promo card; no Pro prices/CTAs and no Android UI appear. Captions mention
no other platform and no Pro.

Pipeline (`sh tool/store_screenshots_ios.sh`):

1. `STORE_SHOTS=1 STORE_SHOT_PROFILE=ios flutter test test/store_screenshots`
   renders the real localized screens (dark theme, sanitized demo data) at
   440x956 logical @3x = 1320x2868 with Dynamic Island insets (59/34dp) into
   `../screenshots/raw/render_ios/<lang>/` (git-ignored).
2. `tool/compose_screenshots_ios.py <raw> <out> <lang>` (Pillow port of
   `assets/brand/compose_screenshots.js`, captions read from that script) crops
   the status area, frames the screen on the gradient, adds the caption and
   flattens to RGB.

Apple rules checked: PNG, no alpha, 1320x2868 (6.9" Dynamic Island, the single
set App Store Connect scales down). Verified programmatically: 24 files, all
1320x2868 RGB. See docs/release/appstore-screenshots.md in binance_analiz.
