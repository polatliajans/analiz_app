import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/home_tab_provider.dart';
import 'ad_logic.dart';
import 'ads_controller.dart';

/// Anchored adaptive banner placed at the bottom of a screen body (right
/// above the bottom navigation bar). Takes no space until an ad has loaded
/// and collapses again when loading fails or ads are switched off.
///
/// [tabIndex] is the home tab hosting the screen: while shown inside the
/// shell, the banner is requested only once that tab has been opened.
/// Space kept between a banner and whatever sits below it (the nav bar).
const bannerBottomGap = 16.0;

class BannerAdSlot extends ConsumerStatefulWidget {
  final String placementKey;
  final int tabIndex;

  const BannerAdSlot({
    super.key,
    required this.placementKey,
    required this.tabIndex,
  });

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  String? _unitId;
  int? _width;
  bool _seen = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  void _clear() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _loading = false;
    _unitId = null;
  }

  Future<void> _load(String unitId, int width) async {
    _loading = true;
    _unitId = unitId;
    _width = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || _unitId != unitId) return;
    if (size == null) {
      // No suitable size for this width: stay hidden, don't retry.
      _loading = false;
      return;
    }
    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _ad != ad) {
            ad.dispose();
            return;
          }
          setState(() {
            _loading = false;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted && _ad == ad) {
            // Collapse; the same unit/width is not retried in this screen.
            setState(() {
              _ad = null;
              _loaded = false;
              _loading = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(adsReadyProvider);
    final unitId = ready
        ? activeUnitId(
            ref.watch(effectiveAdsConfigProvider),
            widget.placementKey,
            AdFormat.banner,
            isDebug: kDebugMode,
          )
        : null;
    final inShell = ModalRoute.of(context)?.isFirst ?? true;
    final visible = !inShell || ref.watch(homeTabProvider) == widget.tabIndex;
    if (visible) _seen = true;

    if (unitId == null) {
      if (_ad != null || _loading) _clear();
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        final needsLoad =
            _seen && (_unitId != unitId || (_width != width && !_loading));
        if (needsLoad && width > 0) {
          _clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _ad == null && !_loading) _load(unitId, width);
          });
        }
        final ad = _ad;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: ad != null && _loaded
              ? SafeArea(
                  top: false,
                  // Clear gap above the bottom nav bar so a tap meant for a
                  // tab cannot land on the ad.
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: bannerBottomGap),
                    child: SizedBox(
                      width: ad.size.width.toDouble(),
                      height: ad.size.height.toDouble(),
                      child: AdWidget(ad: ad),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}
