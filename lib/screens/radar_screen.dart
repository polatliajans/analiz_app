import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_logic.dart';
import '../ads/banner_ad_slot.dart';
import '../ads/native_ads.dart';
import '../l10n/app_localizations.dart';
import '../models/radar_item.dart';
import '../providers/home_tab_provider.dart';
import '../providers/radar_provider.dart';
import '../providers/selected_coin_provider.dart';
import '../utils/radar_tiers.dart';
import '../widgets/radar/radar_widgets.dart';
import 'guest_benefits_screen.dart';
import 'subscription_screen.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with NativeAdPoolHost<RadarScreen> {
  String? _term;

  @override
  String get nativePlacementKey => AdPlacementKeys.nativeRadar;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(radarAccessProvider);
    final pro = access == RadarAccess.pro;
    // Non-Pro members only ever see (and request) the short term.
    final term = pro ? _term : 'short';
    final radarAsync = ref.watch(radarProvider(term));
    final l10n = AppLocalizations.of(context)!;
    final nativeAds = watchNativeAds();

    final allItems = pro
        ? ref.watch(radarProvider(null)).asData?.value
        : radarAsync.asData?.value;
    final counts = <String?, int>{};
    final hints = <String?, String>{};
    if (allItems != null) {
      if (pro) counts[null] = allItems.length;
      for (final t in radarAllowedTerms(access)) {
        final of = allItems.where((i) => i.term == t);
        counts[t] = of.length;
        final tfs = of.map((i) => i.timeframe).toSet().take(2).toList();
        if (tfs.isNotEmpty) hints[t] = tfs.join(' · ');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.radar),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: l10n.radarInfoTooltip,
            onPressed: () => showRadarInfoSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RadarTermSelector(
                selected: term,
                counts: counts,
                hints: hints,
                showAll: pro,
                locked: pro ? const {} : const {'medium', 'long'},
                onLocked: (_) => _openUpgrade(access),
                onSelected: (t) => setState(() => _term = t),
              ),
            ),
          ),
          Expanded(
            child: radarAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$error', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(radarProvider(term)),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(radarProvider(term).future),
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const RadarEmptyState(),
                          if (!pro) _upsellRow(access),
                        ],
                      )
                    : _buildList(context, items, nativeAds, access),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.radarFooter,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const BannerAdSlot(
            placementKey: AdPlacementKeys.bannerRadar,
            tabIndex: radarTabIndex,
          ),
        ],
      ),
    );
  }

  /// Guests go to the sign-in benefits page, free members to Pro.
  void _openUpgrade(RadarAccess access) {
    if (access == RadarAccess.guest) {
      openGuestBenefits(context);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
    }
  }

  Widget _upsellRow(RadarAccess access) =>
      RadarUpsellRow(access: access, onTap: () => _openUpgrade(access));

  void _open(RadarItem item) {
    ref.read(selectedCoinProvider.notifier).select(item.coin);
    ref.read(homeTabProvider.notifier).select(chartTabIndex);
  }

  Widget _buildList(
    BuildContext context,
    List<RadarItem> items,
    ({NativeAdPool pool, int frequency})? nativeAds,
    RadarAccess access,
  ) {
    final pro = access == RadarAccess.pro;
    var top = items.first;
    for (final i in items) {
      if (i.technicalScore > top.technicalScore) top = i;
    }
    final rest = items.where((i) => !identical(i, top)).toList();
    final n = nativeAds?.frequency ?? 0;
    bool isAd(int i) => nativeAds != null && shouldShowNativeAt(i, n);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: 1 + itemCountWithAds(rest.length, n) + (pro ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return RadarTopPickCard(item: top, pro: pro, onTap: () => _open(top));
        }
        final i = index - 1;
        if (!pro && index == 1 + itemCountWithAds(rest.length, n)) {
          return _upsellRow(access);
        }
        return isAd(i)
            ? NativeAdRow(pool: nativeAds!.pool, slot: nativeSlotNumber(i, n))
            : RadarTile(
                item: rest[contentIndexAt(i, n)],
                pro: pro,
                onTap: () => _open(rest[contentIndexAt(i, n)]),
              );
      },
    );
  }
}
