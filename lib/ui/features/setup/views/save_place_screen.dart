import 'package:flutter/material.dart';

import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../finish_setup.dart';
import 'setup_parts.dart';
import 'sign_in_methods.dart';

/// SavePlace (643:235): make the family account, then save the child.
class SavePlaceScreen extends StatelessWidget {
  const SavePlaceScreen({super.key, required this.deps});

  final Deps deps;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = childName(context, deps.account.draft.name);
    return AuraPage(
      top: setupTopBar(SetupStep.save),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: sentence(l.setupSaveTitle(name)),
            subtitle: l.setupSaveSubtitle,
          ),
          SignInMethods(
            account: deps.account,
            checkEmailPath: Paths.setupCheckEmail,
            busyLabel: sentence(l.setupSaving(name)),
            onSignedIn: () => finishSetup(context, deps),
          ),
        ],
      ),
    );
  }
}
