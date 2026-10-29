import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import 'parts.dart';

/// SignOut (659:105). A paired child phone stays paired.
class SignOutScreen extends StatelessWidget {
  const SignOutScreen({super.key, required this.account});

  final AccountRepository account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guSignOutTitle,
      body: l.guSignOutBody,
      action: l.guSignOut,
      fallback: Paths.settings,
      onConfirm: () async {
        await account.signOut();
        if (context.mounted) context.go(Paths.open);
      },
    );
  }
}

/// Deleting the family account (ACC-09; Apple requires it in the app).
/// Not designed in Figma: built as the other confirmations.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({
    super.key,
    required this.account,
    required this.repo,
  });

  final AccountRepository account;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guDeleteTitle,
      body: l.guDeleteBody,
      action: l.guDeleteButton,
      fallback: Paths.rights,
      onConfirm: () async {
        await repo.erase();
        // the chosen child went with the family
        await account.chooseChild(null);
        await account.signOut();
        if (context.mounted) context.go(Paths.open);
      },
    );
  }
}
