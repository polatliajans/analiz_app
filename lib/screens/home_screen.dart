import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/native_home_slot.dart';
import '../l10n/app_localizations.dart';
import '../models/home_data.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/guest_market_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/price_alert_provider.dart';
import '../services/chart_navigation.dart';
import '../utils/home_logic.dart';
import '../widgets/analysis_card.dart';
import '../widgets/home/home_sections.dart';
import '../widgets/home/market_movers_card.dart';
import '../widgets/home/market_pulse_row.dart';
import 'alarms_screen.dart';
import 'auth_screen.dart';
import 'guest_benefits_screen.dart';
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
  Timer? _autoRefresh;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final every = ref.read(homeAutoRefreshProvider);
    if (every != null) {
      _autoRefresh = Timer.periodic(every, (_) {
        // Only while the app is in the foreground and this tab is the visible one.
        if (!mounted || !_appResumed) return;
        if (ref.read(homeTabProvider) != homeTabIndex) return;
        if (!ref.read(authProvider).isLoggedIn) {
          ref.invalidate(guestHomeProvider);
          return;
        }
        ref.read(homeProvider.notifier).refresh();
      });
    }
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    // Debounced inside the notifier (at most once every 30 seconds).
    if (_appResumed) {
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

  void _openBenefits() => openGuestBenefits(context);

  /// The data-driven sections, in the same order for members and guests.
  /// For guests the member-only ones (last analysis) are replaced
  /// by locked cards that lead to the benefits page.
  void _addDataSections(
    List<Widget> children,
    AppLocalizations l10n,
    HomeData data,
    DateTime now, {
    required bool guest,
  }) {
    const gap = SizedBox(height: 12);
    void open(m) => _openChart(
      coinId: m.coinId,
      symbol: m.symbol,
      marketType: m.marketType,
    );
    children
      ..add(MarketPulseRow(market: data.market))
      ..add(gap);
    final mm = data.marketMovers;
    if (mm != null && !mm.isEmpty) {
      children
        ..add(MarketMoversCard(movers: mm, onTap: open))
        ..add(gap);
    }
    children
      ..add(const HomeNativeAdSlot())
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
      ..add(gap)
      ..add(
        guest
            ? HomeLockedCard(
                key: const ValueKey('locked-analysis'),
                title: l10n.homeAnalysisTitle,
                icon: Icons.psychology_outlined,
                message: l10n.homeLockedAnalysis,
                onTap: _openBenefits,
              )
            : LastAnalysisCard(
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
        ..add(gap)
        ..add(EventsCard(events: data.events, now: now));
    }
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

    final isGuest = !state.signedIn && !state.loading;
    final children = <Widget>[];
    void gap() => children.add(const SizedBox(height: 12));

    if (isGuest) {
      children.add(
        HomeGuestCard(
          onLogin: () => openAuthScreen(context),
          onBenefits: _openBenefits,
        ),
      );
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
      if (state.signedIn && !isPro) {
        // Free members: a visible way to the Pro page, right below the band.
        gap();
        children.add(
          ProPromoCard(
            key: const ValueKey('home-pro-promo'),
            onTap: () => _push(const SubscriptionScreen()),
          ),
        );
      }
    }
    gap();

    if (isGuest || state.signedIn) {
      children.add(
        HomeQuickActions(
          actions: [
            HomeQuickAction(
              key: const ValueKey('quick-deep'),
              icon: Icons.psychology_outlined,
              label: l10n.homeQuickDeep,
              locked: isGuest,
              onTap: isGuest
                  ? _openBenefits
                  : () => ref
                        .read(homeTabProvider.notifier)
                        .select(chartTabIndex),
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
              locked: isGuest,
              onTap: isGuest
                  ? _openBenefits
                  : () => _push(const AlarmsScreen()),
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

    if (isGuest) {
      ref
          .watch(guestHomeProvider)
          .when(
            loading: () => children.add(const HomeSkeleton()),
            error: (_, _) => children.add(
              HomeErrorCard(onRetry: () => ref.invalidate(guestHomeProvider)),
            ),
            data: (d) => _addDataSections(
              children,
              l10n,
              d ?? HomeData.empty,
              now,
              guest: true,
            ),
          );
    } else if (state.showSkeleton) {
      children.add(const HomeSkeleton());
    } else if (data == null && state.signedIn) {
      children.add(
        HomeErrorCard(
          onRetry: () => ref.read(homeProvider.notifier).refresh(force: true),
        ),
      );
    } else if (data != null) {
      _addDataSections(children, l10n, data, now, guest: false);
    }

    gap();
    children.add(
      LearnCard(
        term: termOfTheDay(now),
        onTap: () => openGlossary(context, termId: termOfTheDay(now).id),
      ),
    );
    gap();
    children.add(const HomeFooter());

    // No app bar: the slim top band is part of the list. The status bar /
    // cutout inset is applied here; the bottom one is handled by the shell's
    // navigation bar (or by the padding below when shown on its own).
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () {
            if (isGuest) {
              ref.invalidate(guestHomeProvider);
              return ref
                  .read(guestHomeProvider.future)
                  .then((_) {}, onError: (_) {});
            }
            return ref.read(homeProvider.notifier).refresh(force: true);
          },
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
