import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/api.dart';
import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../setup_paths.dart';
import 'setup_parts.dart';

/// Where an emailed link lands: `/auth/verify?m=<token>`. Mid-setup (the
/// grown-up agreed on Data) the token goes back to setup's CheckEmail,
/// which signs in and saves the child: once signed in, the router moves a
/// grown-up off this address. Otherwise it signs in here and goes on to
/// the children.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, required this.deps, required this.token});

  final Deps deps;
  final String? token;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.setupLinkMissing);
      return;
    }
    if (widget.deps.account.draft.agreed) {
      context.go(SetupPaths.checkEmail(Paths.setupCheckEmail, token: token));
      return;
    }
    try {
      await widget.deps.account.verifyEmailLink(token);
      if (mounted) context.go(Paths.kids);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.signIn),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.setupCheckTitle),
          if (_error == null)
            Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.setupVerifying, style: AuraText.body)),
              ],
            )
          else
            ErrorNote(_error!),
        ],
      ),
      bottom: _error == null
          ? null
          : AuraButton(
              label: l.setupBackToSignIn,
              color: AuraButtonColor.blue,
              onPressed: () => context.go(Paths.signIn),
            ),
    );
  }
}
