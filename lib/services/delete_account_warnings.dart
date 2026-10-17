/// Which warnings the delete-account dialog must show for a member.
class DeleteAccountWarnings {
  final int credits;
  final bool showProWarning;

  const DeleteAccountWarnings({
    required this.credits,
    required this.showProWarning,
  });

  bool get showCredits => credits > 0;

  /// Members with credits or a Pro subscription must tick an acknowledgement.
  bool get requiresAck => showCredits || showProWarning;

  bool canDelete({required bool acknowledged}) => !requiresAck || acknowledged;
}

DeleteAccountWarnings deleteAccountWarnings({
  required String role,
  required int creditBalance,
}) => DeleteAccountWarnings(
  credits: creditBalance > 0 ? creditBalance : 0,
  showProWarning: role == 'pro',
);
