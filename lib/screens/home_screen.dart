import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/home_data.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/price_alert_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../services/chart_navigation.dart';
import '../utils/home_logic.dart';
import '../widgets/analysis_card.dart';
import '../widgets/home/home_sections.dart';
import '../widgets/home/market_movers_card.dart';
import '../widgets/home/market_pulse_row.dart';
import 'alarms_screen.dart';
import 'auth_screen.dart';
import 'credit_packages_screen.dart';
import 'glossary_screen.dart';
import 'subscription_screen.dart';

/// First tab: a calm overview of the market, the member's own state and
/// shortcuts into the rest of the app.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Debounced inside the notifier (at most once a minute).
    if (state == AppLifecycleState.resumed) {
      ref.read(homeProvider.notifier).refresh();
    }
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openChart({
    int? coinId,
    required String symbol,
    required String marketType,
    String? timeframe,
  }) {
    openChartFor(
      ref,
      coinId: coinId,
      symbol: symbol,
      marketType: marketType,
      timeframe: timeframe,
    );
  }

  Future<void> _openLastAnalysis(HomeLastAnalysis a) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      var records = await ref.read(analysisHistoryProvider(null).future);
      var match = records.where((r) => r.id == a.id).firstOrNull;
      if (match == null) {
        // The cached list may predate this analysis.
        records = await ref.refresh(analysisHistoryProvider(null).future);
        match = records.where((r) => r.id == a.id).firstOrNull;
      }
      if (!mounted) return;
      if (match == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.homeAnalysisOpenFailed)),
        );
        return;
      }
      await showAnalysisSheet(
        navigator.context,
        result: match.result,
        creditCost: match.creditCost,
        structured: match.structured,
        generatedAt: match.createdAt,
        cached: a.cached,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homeAnalysisOpenFailed)),
      );
    }
  }

  String? _staleNote(AppLocalizations l10n, HomeState s, DateTime now) {
    if (!s.isStale(now)) return null;
    final at = s.fetchedAt;
    if (at == null) return l10n.homeStaleNoTime;
    return l10n.homeStaleNote(relativeAgo(l10n, at, now));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(homeProvider);
    final auth = ref.watch(authProvider);
    final isProRole = ref.watch(isProProvider);
    final now = ref.watch(homeClockProvider)();

    // Refresh when this tab becomes visible (debounced in the notifier).
    ref.listen<int>(homeTabProvider, (previous, next) {
      if (next == homeTabIndex && previous != homeTabIndex) {
        ref.read(homeProvider.notifier).refresh();
      }
    });

    final data = state.data;
    final member = auth.member;
    final credits = data?.credits?.balance ?? member?.creditBalance;
    final isPro = data?.credits?.isPro ?? isProRole;

    // Where the user left off: the coin/timeframe the chart tab shows.
    final selected = ref.watch(selectedCoinProvider).value;
    final timeframe = ref.watch(timeframeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final lastSymbol = selected?.symbol ?? prefs.getString(lastCoinSymbolKey);
    final lastMarket =
        selected?.marketType ??
        prefs.getString(lastCoinMarketKey) ??
        defaultMarketType;

    final children = <Widget>[];
    void gap() => children.add(const SizedBox(height: 12));

    if (!state.signedIn && !state.loading) {
      children.add(HomeGuestCard(onLogin: () => openAuthScreen(context)));
    } else {
      children.add(
        HomeHeader(
          name: member?.name,
          credits: credits,
          isPro: isPro,
          staleNote: _staleNote(l10n, state, now),
          onCredits: () => _push(const CreditPackagesScreen()),
          onPro: () => _push(const SubscriptionScreen()),
        ),
      );
    }
    gap();

    if (state.signedIn) {
      children.add(
        HomeQuickActions(
          actions: [
            HomeQuickAction(
              key: const ValueKey('quick-deep'),
              icon: Icons.psychology_outlined,
              label: l10n.homeQuickDeep,
              onTap: () =>
                  ref.read(homeTabProvider.notifier).select(chartTabIndex),
            ),
            HomeQuickAction(
              key: const ValueKey('quick-radar'),
              icon: Icons.radar,
              label: l10n.radar,
              onTap: () =>
                  ref.read(homeTabProvider.notifier).select(radarTabIndex),
            ),
            HomeQuickAction(
              key: const ValueKey('quick-alerts'),
              icon: Icons.notifications_active_outlined,
              label: l10n.homeQuickAlerts,
              onTap: () => _push(const AlarmsScreen()),
            ),
            HomeQuickAction(
              key: const ValueKey('quick-glossary'),
              icon: Icons.menu_book_outlined,
              label: l10n.homeQuickGlossary,
              onTap: () => openGlossary(context),
            ),
          ],
        ),
      );
      gap();
    }

    if (lastSymbol != null) {
      children.add(
        ResumeCard(
          symbol: lastSymbol,
          marketType: lastMarket,
          timeframe: timeframe,
          onTap: () => ref.read(homeTabProvider.notifier).select(chartTabIndex),
        ),
      );
      gap();
    }

    if (state.showSkeleton) {
      children.add(const HomeSkeleton());
    } else if (data == null && state.signedIn) {
      children.add(
        HomeErrorCard(
          onRetry: () => ref.read(homeProvider.notifier).refresh(force: true),
        ),
      );
    } else if (data != null) {
      children
        ..add(MarketPulseRow(market: data.market))
        ..add(const SizedBox(height: 12));
      final mm = data.marketMovers;
      if (mm != null && !mm.isEmpty) {
        children
          ..add(
            MarketMoversCard(
              movers: mm,
              onTap: (m) => _openChart(
                coinId: m.coinId,
                symbol: m.symbol,
                marketType: m.marketType,
              ),
            ),
          )
          ..add(const SizedBox(height: 12));
      }
      children
        ..add(
          MoversCard(
            movers: data.movers,
            onTap: (m) => _openChart(
              coinId: m.coinId,
              symbol: m.symbol,
              marketType: m.marketType,
            ),
            onOpenWatchlist: () =>
                ref.read(homeTabProvider.notifier).select(watchlistTabIndex),
          ),
        )
        ..add(const SizedBox(height: 12))
        ..add(
          RadarCard(
            signals: data.radar,
            now: now,
            onTap: (s) => _openChart(
              coinId: s.coinId,
              symbol: s.symbol,
              marketType: s.marketType,
              timeframe: s.timeframe,
            ),
          ),
        )
        ..add(const SizedBox(height: 12))
        ..add(
          LastAnalysisCard(
            analysis: data.lastAnalysis,
            now: now,
            onOpen: () {
              final a = data.lastAnalysis;
              if (a != null) _openLastAnalysis(a);
            },
            onNew: () =>
                ref.read(homeTabProvider.notifier).select(chartTabIndex),
          ),
        );
      if (data.events.isNotEmpty) {
        children
          ..add(const SizedBox(height: 12))
          ..add(EventsCard(events: data.events, now: now));
      }
    }

    gap();
    children.add(
      LearnCard(
        term: termOfTheDay(now),
        onTap: () => openGlossary(context, termId: termOfTheDay(now).id),
      ),
    );
    if (state.signedIn && !isPro) {
      gap();
      children.add(
        ProPromoCard(onTap: () => _push(const SubscriptionScreen())),
      );
    }
    gap();
    children.add(const HomeFooter());

    // No app bar: the slim top band is part of the list. The status bar /
    // cutout inset is applied here; the bottom one is handled by the shell's
    // navigation bar (or by the padding below when shown on its own).
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
