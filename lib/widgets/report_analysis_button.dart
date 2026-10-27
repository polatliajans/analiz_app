import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';

/// Lightweight "Report this analysis" action: opens the mail app addressed to
/// support with a prefilled subject (no backend involved). [context] is a
/// short label of what is reported (e.g. "BTCUSDT 1h"), added to the subject.
class ReportAnalysisButton extends StatelessWidget {
  final String? subjectDetail;
  const ReportAnalysisButton({super.key, this.subjectDetail});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final detail = (subjectDetail == null || subjectDetail!.isEmpty)
        ? ''
        : ' - $subjectDetail';
    var ok = false;
    try {
      ok = await launchUrl(
        LegalLinks.supportMailtoWith(
          subject: '${l10n.reportAnalysisSubject}$detail',
          body: l10n.reportAnalysisBody,
        ),
      );
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const Key('report-analysis'),
        onPressed: () => _open(context),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text(AppLocalizations.of(context)!.reportAnalysis),
      ),
    );
  }
}
