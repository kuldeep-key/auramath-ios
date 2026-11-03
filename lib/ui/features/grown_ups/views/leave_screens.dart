import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/repositories/session_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import 'parts.dart';

/// SignOut (659:105). A paired child phone stays paired, but no child's
/// lessons stay on the phone (DEV-06): unsent work is sent first, and while
/// it can't be, the grown-up stays signed in and is told why.
class SignOutScreen extends StatelessWidget {
  const SignOutScreen({
    super.key,
    required this.account,
    required this.sessions,
  });

  final AccountRepository account;
  final SessionRepository sessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ConfirmScreen(
      title: l.guSignOutTitle,
      body: l.guSignOutBody,
      action: l.guSignOut,
      fallback: Paths.settings,
      onConfirm: () async {
        await sessions.sendAllThenForget();
        await account.chooseChild(null);
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
    required this.sessions,
  });

  final AccountRepository account;
  final GrownUpRepository repo;
  final SessionRepository sessions;

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
        // the chosen child and their lessons went with the family
        await sessions.forget();
        await account.chooseChild(null);
        await account.signOut();
        if (context.mounted) context.go(Paths.open);
      },
    );
  }
}
