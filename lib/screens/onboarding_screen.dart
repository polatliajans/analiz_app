import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/onboarding_slide.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// In replay mode the screen never touches the "done" flag and simply pops.
  final bool replay;

  const OnboardingScreen({super.key, this.replay = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _fallbackIcons = [
    Icons.radar,
    Icons.candlestick_chart,
    Icons.auto_awesome,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.replay) {
      Navigator.of(context).pop();
    } else {
      ref.read(onboardingDoneProvider.notifier).complete();
    }
  }

  List<OnboardingSlide> _defaultSlides(AppLocalizations l10n) => [
    OnboardingSlide(
      title: l10n.onboardingDefault1Title,
      body: l10n.onboardingDefault1Body,
    ),
    OnboardingSlide(
      title: l10n.onboardingDefault2Title,
      body: l10n.onboardingDefault2Body,
    ),
    OnboardingSlide(
      title: l10n.onboardingDefault3Title,
      body: l10n.onboardingDefault3Body,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slidesAsync = ref.watch(onboardingSlidesProvider);

    return Scaffold(
      body: SafeArea(
        child: slidesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _buildPager(l10n, _defaultSlides(l10n)),
          data: (slides) => _buildPager(l10n, slides ?? _defaultSlides(l10n)),
        ),
      ),
    );
  }

  Widget _buildPager(AppLocalizations l10n, List<OnboardingSlide> slides) {
    final isLast = _page >= slides.length - 1;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextButton(
              onPressed: _finish,
              child: Text(l10n.onboardingSkip),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _SlidePage(
              slide: slides[i],
              fallbackIcon: _fallbackIcons[i % _fallbackIcons.length],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLast
                  ? _finish
                  : () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
              child: Text(isLast ? l10n.onboardingStart : l10n.onboardingNext),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlidePage extends StatelessWidget {
  final OnboardingSlide slide;
  final IconData fallbackIcon;

  const _SlidePage({required this.slide, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Icon(
      fallbackIcon,
      size: 120,
      color: theme.colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 220,
            child: Center(
              child: slide.imageUrl == null
                  ? icon
                  : Image.network(
                      slide.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => icon,
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
