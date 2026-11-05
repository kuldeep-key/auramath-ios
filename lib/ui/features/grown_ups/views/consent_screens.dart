import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import 'parts.dart';

/// Withdrawing consent (ACC-03), behind its own confirmation like deleting
/// the account (no Figma frame yet). The server stops new lessons and new
/// children at once; nothing is deleted. Back to Rights, which then says
/// so and offers Agree again.
class WithdrawConsentScreen extends StatelessWidget {
  const WithdrawConsentScreen({super.key, required this.family});

  final FamilyRepository family;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guWithdrawTitle,
      body: l.guWithdrawBody,
      action: l.guWithdrawButton,
      fallback: Paths.rights,
      onConfirm: () async {
        await family.withdrawConsent();
        if (context.mounted) popOr(context, Paths.rights);
      },
    );
  }
}

/// Agreeing again after a withdrawal (no Figma frame yet): a new, explicit
/// "I agree" to the notice the server serves now, which lifts the
/// withdrawal.
class AgreeAgainScreen extends StatelessWidget {
  const AgreeAgainScreen({super.key, required this.family});

  final FamilyRepository family;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guAgainTitle,
      body: l.guAgainBody,
      action: l.guAgainButton,
      fallback: Paths.rights,
      onConfirm: () async {
        await family.giveConsent();
        if (context.mounted) popOr(context, Paths.rights);
      },
    );
  }
}
