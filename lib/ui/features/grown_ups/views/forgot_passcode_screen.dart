import 'package:flutter/material.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import 'parts.dart';

/// ForgotPass (653:132): email a sign-in link to the account's address,
/// then "check your email". Signing in again from that link is what lets
/// GPass choose a new passcode (see [GrownUpRepository.passcodeResetReady]).
class ForgotPasscodeScreen extends StatefulWidget {
  const ForgotPasscodeScreen({
    super.key,
    required this.account,
    required this.repo,
  });

  final AccountRepository account;
  final GrownUpRepository repo;

  /// `p•••@gmail.com`: enough to recognise, not enough to read off a
  /// child's shoulder.
  static String mask(String email) {
    final at = email.indexOf('@');
    if (at < 1) return email;
    return '${email[0]}•••${email.substring(at)}';
  }

  @override
  State<ForgotPasscodeScreen> createState() => _ForgotPasscodeScreenState();
}

class _ForgotPasscodeScreenState extends State<ForgotPasscodeScreen> {
  bool _sent = false;
  bool _busy = false;
  Object? _error;

  Future<String?> _email() async {
    final me = (await widget.repo.members()).where((m) => m.you);
    return me.isEmpty || me.first.email.isEmpty ? null : me.first.email;
  }

  Future<void> _send(String email) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.account.sendEmailLink(email);
      await widget.repo.startPasscodeReset(widget.account.bearer);
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Loaded<String?>(
      load: _email,
      fallback: Paths.grownUpsPass,
      builder: (context, email, _) {
        final masked = email == null ? null : ForgotPasscodeScreen.mask(email);
        return AuraPage(
          top: const AuraTopBar(fallback: Paths.grownUpsPass),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraHeading(
                title: _sent ? l.guForgotSentTitle : l.guForgotTitle,
                subtitle: masked == null
                    ? l.guForgotNoEmail
                    : _sent
                    ? l.guForgotSentBody(masked)
                    : l.guForgotBody(masked),
              ),
              if (_error != null) ErrorNote(_error!),
            ],
          ),
          bottom: email == null
              ? null
              : _sent
              ? AuraLink(
                  label: l.guForgotResend,
                  onPressed: _busy ? null : () => _send(email),
                )
              : AuraButton(
                  label: l.guForgotSend,
                  color: AuraButtonColor.blue,
                  onPressed: _busy ? null : () => _send(email),
                ),
        );
      },
    );
  }
}
