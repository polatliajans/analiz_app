# App Store screenshots (iPhone 6.9")

Branded 1320x2868 PNG phone screenshots (no alpha) per listing language: `en/`,
`tr/`, `es/` (`01-home` ... `09-pro`, same order and captions as the Play
set in `../screenshots/`, see its README for the caption table).

iOS specifics: Pro purchase is available on iOS (same as Android), so the home
screen shows the Pro promo card next to the credit card (no provider override).
`09-pro` is the Pro / subscription screen with iOS wording and demo plan data
(price `$9.99`, auto-renew note, App Store terms, manage / restore, legal
links; scrolled to the plan card). It exists only in the iOS set. No Android UI
appears and captions mention no other platform.

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
set App Store Connect scales down). Verified programmatically: 27 files, all
1320x2868 RGB. See docs/release/appstore-screenshots.md in binance_analiz.
