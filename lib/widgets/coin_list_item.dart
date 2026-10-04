import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/coin.dart';

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final VoidCallback onTap;

  const CoinListItem({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final change = coin.priceChangePercent24h;
    final changeColor = change == null
        ? null
        : (change >= 0 ? Colors.green : Colors.red);

    return ListTile(
      onTap: onTap,
      title: Text(coin.symbol),
      subtitle: Text(
        l10n.volumeLabel(
          coin.volume24h != null ? coin.volume24h!.toStringAsFixed(2) : '-',
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            coin.lastPrice != null ? coin.lastPrice!.toStringAsFixed(8) : '-',
          ),
          Text(
            change != null ? '${change.toStringAsFixed(2)}%' : '-',
            style: TextStyle(color: changeColor),
          ),
        ],
      ),
    );
  }
}
