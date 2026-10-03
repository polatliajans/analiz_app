import 'package:flutter/material.dart';

import '../models/coin.dart';

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final VoidCallback onTap;

  const CoinListItem({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final change = coin.priceChangePercent24h;
    final changeColor = change == null
        ? null
        : (change >= 0 ? Colors.green : Colors.red);

    return ListTile(
      onTap: onTap,
      title: Text(coin.symbol),
      subtitle: Text(
        coin.volume24h != null
            ? 'Hacim: ${coin.volume24h!.toStringAsFixed(2)}'
            : 'Hacim: -',
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
