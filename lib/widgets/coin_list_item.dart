import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/coin.dart';
import '../utils/home_logic.dart';

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final VoidCallback onTap;

  const CoinListItem({super.key, required this.coin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final change = coin.priceChangePercent24h;
    final changeColor = change == null
        ? null
        : trendColor(context, change >= 0 ? 1 : -1);

    return ListTile(
      onTap: onTap,
      title: Text(coin.symbol),
      subtitle: Text(
        l10n.volumeLabel(
          coin.volume24h != null
              ? formatVolumeShort(coin.volume24h!, locale)
              : '-',
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            coin.lastPrice != null
                ? formatCoinPrice(coin.lastPrice!, locale)
                : '-',
          ),
          Text(
            change != null ? formatSignedPct(change, locale) : '-',
            style: TextStyle(color: changeColor),
          ),
        ],
      ),
    );
  }
}
