import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// One-time explanation shown before the system notification permission
/// dialog. Returns true when the member agrees to continue.
Future<bool> showNotificationRationale(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.notifRationaleTitle),
      content: Text(l10n.notifRationaleBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.notifRationaleLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.notifRationaleAllow),
        ),
      ],
    ),
  );
  return result ?? false;
}
