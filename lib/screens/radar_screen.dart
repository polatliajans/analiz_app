import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/radar_item.dart';
import '../providers/radar_provider.dart';
import 'chart_screen.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  String? _term;

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
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildTile(context, items[index]),
                  ),
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
        ],
      ),
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ChartScreen(coin: item.coin))),
    );
  }
}
