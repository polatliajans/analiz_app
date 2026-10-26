import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_logic.dart';
import 'ads_controller.dart';
import 'native_ads.dart';

/// Single native ad on the home screen (`native_home`). Takes no space
/// until an ad has loaded, and collapses (gap included) when the placement is disabled,
/// the user is Pro, or loading fails.
class HomeNativeAdSlot extends ConsumerStatefulWidget {
  const HomeNativeAdSlot({super.key});

  @override
  ConsumerState<HomeNativeAdSlot> createState() => _HomeNativeAdSlotState();
}

class _HomeNativeAdSlotState extends ConsumerState<HomeNativeAdSlot> {
  NativeAdPool? _pool;
  String? _unit;
  Brightness? _brightness;

  @override
  void dispose() {
    _pool?.dispose();
    super.dispose();
  }

  /// Old ads may still be in the tree during this frame; free them after.
  void _retire() {
    final old = _pool;
    _pool = null;
    _unit = null;
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(adsReadyProvider);
    final unit = ready
        ? activeUnitId(
            ref.watch(effectiveAdsConfigProvider),
            AdPlacementKeys.nativeHome,
            AdFormat.native,
            isDebug: kDebugMode,
          )
        : null;
    final theme = Theme.of(context);
    if (unit == null) {
      _retire();
      return const SizedBox.shrink();
    }
    if (_pool == null || _unit != unit || _brightness != theme.brightness) {
      _retire();
      _pool = NativeAdPool(
        unitId: unit,
        style: nativeTemplateStyleFor(theme),
        size: 1,
      );
      _unit = unit;
      _brightness = theme.brightness;
    }
    return NativeAdRow(pool: _pool!, slot: 0, bottomGap: 12);
  }
}
