import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chart_signal.dart';
import '../../models/coin.dart';
import '../../providers/chart_data_provider.dart';
import 'alerts_tab.dart';
import 'analyses_tab.dart';
import 'market_tab.dart';
import 'signals_tab.dart';
import 'summary_tab.dart';

/// The five tabs under the chart, in display order.
enum ChartTab { summary, analyses, market, signals, alerts }

String chartTabLabel(AppLocalizations l10n, ChartTab tab) => switch (tab) {
  ChartTab.summary => l10n.chartTabSummary,
  ChartTab.analyses => l10n.chartTabAnalyses,
  ChartTab.market => l10n.chartTabMarket,
  ChartTab.signals => l10n.chartTabSignals,
  ChartTab.alerts => l10n.chartTabAlerts,
};

/// Height of the pinned tab bar (the bar plus its divider).
const chartTabBarExtent = kTextTabBarHeight + 1;

/// Pins the scrollable [TabBar] to the top while the page content scrolls
/// under it.
class ChartTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final List<String> labels;

  const ChartTabBarDelegate({required this.controller, required this.labels});

  @override
  double get minExtent => chartTabBarExtent;

  @override
  double get maxExtent => chartTabBarExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('chart-tab-bar'),
      color: scheme.surface,
      elevation: overlapsContent ? 2 : 0,
      child: Column(
        children: [
          SizedBox(
            height: kTextTabBarHeight,
            child: _EdgeFade(
              color: scheme.surface,
              child: TabBar(
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                // Tighter than the 16dp default so more tabs fit at rest.
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tabs: [for (final l in labels) Tab(text: l)],
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(ChartTabBarDelegate old) =>
      old.controller != controller || !_sameLabels(old.labels, labels);

  static bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Content of the selected tab, placed in the page's single scroll view. Only
/// the selected tab is built (so only it loads data); tabs of different
/// heights just change the page length. Switching tabs rebuilds only this
/// widget, never the chart above it.
class ChartTabsContent extends StatefulWidget {
  final TabController controller;
  final Coin coin;
  final ChartDataParams params;

  /// A signal row was tapped (the chart screen brings the chart into view).
  final ValueChanged<ChartSignal> onSignalSelected;

  const ChartTabsContent({
    super.key,
    required this.controller,
    required this.coin,
    required this.params,
    required this.onSignalSelected,
  });

  @override
  State<ChartTabsContent> createState() => _ChartTabsContentState();
}

class _ChartTabsContentState extends State<ChartTabsContent> {
  String? _selectedSignal;

  Widget _tab(ChartTab tab) {
    switch (tab) {
      case ChartTab.summary:
        return SummaryTab(
          key: ValueKey('summary-${widget.coin.id}'),
          coin: widget.coin,
        );
      case ChartTab.analyses:
        return AnalysesTab(
          key: ValueKey('analyses-${widget.coin.id}'),
          coin: widget.coin,
        );
      case ChartTab.market:
        return MarketTab(
          key: ValueKey('market-${widget.coin.id}'),
          coin: widget.coin,
        );
      case ChartTab.signals:
        return SignalsTab(
          params: widget.params,
          selectedKey: _selectedSignal,
          onSelect: (s) {
            setState(() => _selectedSignal = signalKey(s));
            widget.onSignalSelected(s);
          },
        );
      case ChartTab.alerts:
        return AlertsTab(
          key: ValueKey('alerts-${widget.coin.id}'),
          coin: widget.coin,
          params: widget.params,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final tab = ChartTab.values[widget.controller.index];
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 240),
          child: KeyedSubtree(key: ValueKey(tab), child: _tab(tab)),
        );
      },
    );
  }
}

/// Fades the right edge while the scrollable tab bar has more tabs off
/// screen, so a partly hidden last tab reads as "scroll for more" rather
/// than as cut off.
class _EdgeFade extends StatefulWidget {
  final Color color;
  final Widget child;
  const _EdgeFade({required this.color, required this.child});

  @override
  State<_EdgeFade> createState() => _EdgeFadeState();
}

class _EdgeFadeState extends State<_EdgeFade> {
  bool _more = false;

  void _update(ScrollMetrics m) {
    final more = m.extentAfter > 1;
    if (more == _more) return;
    // Notifications can arrive during layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && more != _more) setState(() => _more = more);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            _update(n.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _update(n.metrics);
              return false;
            },
            child: widget.child,
          ),
        ),
        if (_more)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 28,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const Key('chart-tab-bar-fade'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withValues(alpha: 0), widget.color],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
