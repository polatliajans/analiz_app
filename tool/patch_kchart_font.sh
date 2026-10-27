#!/bin/sh
# Screenshot capture only: flutter test renders family-less text with the
# Ahem test font, so k_chart's axis labels turn into boxes. This adds an
# explicit Roboto family (what Android uses by default anyway) to the
# vendored k_chart, for the duration of the capture. Usage: patch|restore
cd "$(dirname "$0")/.." || exit 1
case "$1" in
  patch)
    sed -i "s/TextStyle(fontSize: 10.0, color: color)/TextStyle(fontFamily: 'Roboto', fontSize: 10.0, color: color)/" \
      packages/k_chart/lib/renderer/base_chart_painter.dart packages/k_chart/lib/renderer/base_chart_renderer.dart
    sed -i "s/style: const TextStyle(/style: const TextStyle(fontFamily: 'Roboto',/" packages/k_chart/lib/renderer/chart_painter.dart
    ;;
  restore)
    git checkout -- packages/k_chart
    ;;
esac
