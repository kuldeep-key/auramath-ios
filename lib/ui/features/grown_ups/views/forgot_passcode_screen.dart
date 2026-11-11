import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../setup/views/sign_in_methods.dart';
import 'parts.dart';

/// ForgotPass (653:132): email a sign-in link to the account's address,
/// then "check your email"; or sign in again here with Apple or Google
/// (ACC-11). A fresh sign-in either way is what lets GPass choose a new
/// passcode (see [GrownUpRepository.passcodeResetReady]).
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

  /// Apple or Google, now: marks the reset with the old credential, signs
  /// in, and back to GPass, which then asks for the new passcode. A closed
  /// sheet or a failure leaves things as they were.
  Future<void> _again(Future<bool> Function() signIn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    var signedIn = false;
    try {
      await widget.repo.startPasscodeReset(widget.account.bearer);
      signedIn = await signIn();
      if (signedIn && mounted) context.go(Paths.grownUpsPass);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      // the emailed link may still be on its way: keep its marker
      if (!signedIn && !_sent) await widget.repo.endPasscodeReset();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _apple(AppLocalizations l) async {
    if (!(await widget.account.authConfig()).apple) {
      throw ApiException(l.setupAppleOff, status: 501);
    }
    return widget.account.signInWithApple();
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
              const SizedBox(height: 20),
              Text(l.guForgotOr, style: AuraText.body),
              const SizedBox(height: 12),
              AppleButton(
                onPressed: _busy ? null : () => _again(() => _apple(l)),
              ),
              const SizedBox(height: 12),
              GoogleButton(
                onPressed: _busy
                    ? null
                    : () => _again(widget.account.signInWithGoogle),
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
