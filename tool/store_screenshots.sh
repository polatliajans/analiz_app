#!/bin/sh
# Rebuilds the Play Store screenshots (en, tr, es) from the current app:
#  1. renders raw 1080x2400 phone screens with demo data (flutter test, no device)
#  2. composes the branded 1080x1920 images (needs node + sharp on NODE_PATH)
# Usage: sh tool/store_screenshots.sh
set -e
cd "$(dirname "$0")/.."
trap 'sh tool/patch_kchart_font.sh restore' EXIT
sh tool/patch_kchart_font.sh patch
STORE_SHOTS=1 flutter test test/store_screenshots
for l in en tr es; do
  node assets/brand/compose_screenshots.js "store_assets/screenshots/raw/render/$l" "store_assets/screenshots/$l" "$l" gradient
done
