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

  static List<(String?, String)> _terms(AppLocalizations l10n) => [
    (null, l10n.termAll),
    ('short', l10n.termShort),
    ('medium', l10n.termMedium),
    ('long', l10n.termLong),
  ];

  static String _termLabel(AppLocalizations l10n, String term) {
    switch (term) {
      case 'short':
        return l10n.termShortLabel;
      case 'medium':
        return l10n.termMediumLabel;
      case 'long':
        return l10n.termLongLabel;
      default:
        return term;
    }
  }

  static String _ago(AppLocalizations l10n, DateTime t) {
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return l10n.agoNow;
    if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
    return l10n.agoDays(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final radarAsync = ref.watch(radarProvider(_term));
    final l10n = AppLocalizations.of(context)!;
    final nativeAds = watchNativeAds();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.radar)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: _terms(l10n)
                    .map(
                      (t) => ChoiceChip(
                        label: Text(t.$2),
                        selected: _term == t.$1,
                        onSelected: (_) => setState(() => _term = t.$1),
                      ),
                    )
                    .toList(),
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
                      onPressed: () => ref.invalidate(radarProvider(_term)),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.radarEmpty));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(radarProvider(_term).future),
                  child: _buildList(context, items, nativeAds),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.radarFooter,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildList(
    BuildContext context,
    List<RadarItem> items,
    ({NativeAdPool pool, int frequency})? nativeAds,
  ) {
    final n = nativeAds?.frequency ?? 0;
    bool isAd(int i) => nativeAds != null && shouldShowNativeAt(i, n);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCountWithAds(items.length, n),
      // The ad row draws its own background instead of dividers.
      separatorBuilder: (_, i) => isAd(i) || isAd(i + 1)
          ? const SizedBox.shrink()
          : const Divider(height: 1),
      itemBuilder: (context, index) => isAd(index)
          ? NativeAdRow(pool: nativeAds!.pool, slot: nativeSlotNumber(index, n))
          : _buildTile(context, items[contentIndexAt(index, n)]),
    );
  }

  Widget _buildTile(BuildContext context, RadarItem item) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      title: Text(
        '${item.coin.symbol}  ·  ${item.coin.marketType == 'futures' ? 'Futures' : 'Spot'}',
      ),
      subtitle: Text(
        '${_termLabel(l10n, item.term)} (${item.timeframe})  ·  RSI ${item.rsi?.toStringAsFixed(1) ?? '-'}  ·  ${_ago(l10n, item.detectedAt)}',
      ),
      trailing: Chip(label: Text('${item.technicalScore}')),
      onTap: () {
        ref.read(selectedCoinProvider.notifier).select(item.coin);
        ref.read(homeTabProvider.notifier).select(chartTabIndex);
      },
    );
  }
}
