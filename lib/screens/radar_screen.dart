import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const _terms = <(String?, String)>[
    (null, 'Tümü'),
    ('short', 'Kısa'),
    ('medium', 'Orta'),
    ('long', 'Uzun'),
  ];

  static String _termLabel(String term) {
    switch (term) {
      case 'short':
        return 'Kısa vade';
      case 'medium':
        return 'Orta vade';
      case 'long':
        return 'Uzun vade';
      default:
        return term;
    }
  }

  static String _ago(DateTime t) {
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    final radarAsync = ref.watch(radarProvider(_term));

    return Scaffold(
      appBar: AppBar(title: const Text('Radar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: _terms
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
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Şu an teknik şartları sağlayan fırsat yok.'),
                  );
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
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Skor 0-100: ne kadar aşırı satımda olduğunu gösterir. Yapay zeka destekli derin analiz için bir fırsata dokunun.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, RadarItem item) {
    return ListTile(
      title: Text(
        '${item.coin.symbol}  ·  ${item.coin.marketType == 'futures' ? 'Futures' : 'Spot'}',
      ),
      subtitle: Text(
        '${_termLabel(item.term)} (${item.timeframe})  ·  RSI ${item.rsi?.toStringAsFixed(1) ?? '-'}  ·  ${_ago(item.detectedAt)}',
      ),
      trailing: Chip(label: Text('${item.technicalScore}')),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ChartScreen(coin: item.coin))),
    );
  }
}
