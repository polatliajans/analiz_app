#!/bin/sh
# Rebuilds the App Store screenshots (en, tr, es) at 1320x2868 (iPhone 6.9"):
#  1. renders raw 1320x2868 screens (440x956 logical @3x, Pro purchase available
#     like on iOS, plus the 09-pro screen) with flutter test, STORE_SHOT_PROFILE=ios
#  2. composes branded PNGs without alpha (Pillow; no node/sharp needed)
# Usage: sh tool/store_screenshots_ios.sh
set -e
cd "$(dirname "$0")/.."
trap 'sh tool/patch_kchart_font.sh restore' EXIT
sh tool/patch_kchart_font.sh patch
STORE_SHOTS=1 STORE_SHOT_PROFILE=ios flutter test test/store_screenshots
for l in en tr es; do
  python tool/compose_screenshots_ios.py "store_assets/screenshots/raw/render_ios/$l" "store_assets/screenshots_ios/$l" "$l"
done
