import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/app_localizations.dart';
import 'ad_logic.dart';
import 'ads_controller.dart';

/// A small set of native ads reused across the ad slots of one list, so
/// scrolling never requests a new ad per row. Slot `n` uses ad `n % size`;
/// [size] comes from `nativePoolSizeFor` so one ad is never shown twice.
class NativeAdPool extends ChangeNotifier {
  final String unitId;
  final NativeTemplateStyle style;
  final int size;

  final _ads = <int, NativeAd>{};
  final _loaded = <int>{};
  final _requested = <int>{};
  bool _disposed = false;

  NativeAdPool({required this.unitId, required this.style, this.size = 4});

  /// The loaded ad for [slot], or null (then the slot is hidden). Starts
  /// loading it, and the next one, on first use.
  NativeAd? adFor(int slot) {
    final i = slot % size;
    _request(i);
    _request((i + 1) % size);
    return _loaded.contains(i) ? _ads[i] : null;
  }

  void _request(int i) {
    if (_requested.contains(i) || _disposed) return;
    _requested.add(i);
    final ad = NativeAd(
      adUnitId: unitId,
      request: const AdRequest(),
      nativeTemplateStyle: style,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (_disposed) return;
          _loaded.add(i);
          notifyListeners();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ads.remove(i);
          // Failed slots stay hidden for the lifetime of this list.
        },
      ),
    );
    _ads[i] = ad;
    ad.load();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final ad in _ads.values) {
      ad.dispose();
    }
    _ads.clear();
    super.dispose();
  }
}

/// Theme-matched small native template.
NativeTemplateStyle nativeTemplateStyleFor(ThemeData theme) {
  final scheme = theme.colorScheme;
  return NativeTemplateStyle(
    templateType: TemplateType.small,
    mainBackgroundColor: scheme.surface,
    cornerRadius: 12,
    callToActionTextStyle: NativeTemplateTextStyle(
      textColor: scheme.onPrimary,
      backgroundColor: scheme.primary,
      style: NativeTemplateFontStyle.bold,
      size: 14,
    ),
    primaryTextStyle: NativeTemplateTextStyle(
      textColor: scheme.onSurface,
      style: NativeTemplateFontStyle.bold,
      size: 15,
    ),
    secondaryTextStyle: NativeTemplateTextStyle(
      textColor: scheme.onSurfaceVariant,
      size: 13,
    ),
    tertiaryTextStyle: NativeTemplateTextStyle(
      textColor: scheme.onSurfaceVariant,
      size: 12,
    ),
  );
}

/// Owns a [NativeAdPool] for one list while ads are enabled for
/// [placementKey]; disposes it when ads go away (Pro, sign-out, disabled).
mixin NativeAdPoolHost<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  NativeAdPool? _pool;
  String? _poolUnit;
  Brightness? _poolBrightness;

  String get nativePlacementKey;

  @override
  void dispose() {
    _pool?.dispose();
    super.dispose();
  }

  /// Old ads may still be in the tree during this frame; free them after.
  void _retirePool() {
    final old = _pool;
    if (old == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// Call from build. Returns the pool and ad frequency, or null (no ads).
  ({NativeAdPool pool, int frequency})? watchNativeAds() {
    final ready = ref.watch(adsReadyProvider);
    final config = ref.watch(effectiveAdsConfigProvider);
    final unit = ready
        ? activeUnitId(
            config,
            nativePlacementKey,
            AdFormat.native,
            isDebug: kDebugMode,
          )
        : null;
    final theme = Theme.of(context);
    if (unit == null) {
      _retirePool();
      _pool = null;
      _poolUnit = null;
      return null;
    }
    // Never denser than the default, whatever the server asks for.
    final frequency = math.max(
      effectiveFrequency(
        config.placement(nativePlacementKey)?.frequency,
        defaultNativeFrequency,
      ),
      defaultNativeFrequency,
    );
    final size = nativePoolSizeFor(frequency);
    if (_pool == null ||
        _poolUnit != unit ||
        _pool!.size != size ||
        _poolBrightness != theme.brightness) {
      _retirePool();
      _pool = NativeAdPool(
        unitId: unit,
        style: nativeTemplateStyleFor(theme),
        size: size,
      );
      _poolUnit = unit;
      _poolBrightness = theme.brightness;
    }
    return (pool: _pool!, frequency: frequency);
  }
}

/// One native ad row with an "Ad" label; zero height until loaded.
class NativeAdRow extends StatelessWidget {
  final NativeAdPool pool;
  final int slot;

  const NativeAdRow({super.key, required this.pool, required this.slot});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        final ad = pool.adFor(slot);
        if (ad == null) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppLocalizations.of(context)!.adLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(height: 96, child: AdWidget(ad: ad)),
            ],
          ),
        );
      },
    );
  }
}
