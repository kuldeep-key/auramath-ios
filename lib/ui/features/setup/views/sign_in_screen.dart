import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import 'sign_in_methods.dart';

/// SignIn (653:2): back into an existing family account.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, required this.deps});

  final Deps deps;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.welcome),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: l.setupSignInTitle,
            subtitle: l.setupSignInSubtitle,
          ),
          SignInMethods(
            account: deps.account,
            checkEmailPath: Paths.signInCheckEmail,
            emailOpen: true,
            onSignedIn: () async {
              if (context.mounted) context.go(Paths.kids);
            },
          ),
        ],
      ),
    );
  }
}
