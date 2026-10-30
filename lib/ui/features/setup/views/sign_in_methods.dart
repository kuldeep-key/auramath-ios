import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_text_field.dart';
import '../../../core/theme/tokens.dart';
import '../setup_paths.dart';
import 'setup_parts.dart';

/// Apple, Google and an emailed link: SavePlace (643:235) and SignIn
/// (653:2). Every door shows, whatever the server can open; a closed one
/// says so on tap rather than hiding.
class SignInMethods extends StatefulWidget {
  const SignInMethods({
    super.key,
    required this.account,
    required this.checkEmailPath,
    required this.onSignedIn,
    this.emailOpen = false,
    this.busyLabel,
  });

  final AccountRepository account;

  /// Where "Email me a link" goes next (setup's or sign-in's CheckEmail).
  final String checkEmailPath;

  /// After Apple or Google: finish setup, or go to the children.
  final Future<void> Function() onSignedIn;

  /// SignIn shows the email field at once; SavePlace behind "Use my email".
  final bool emailOpen;

  /// What the wait is for ("Saving Aarav's place…").
  final String? busyLabel;

  @override
  State<SignInMethods> createState() => _SignInMethodsState();
}

class _SignInMethodsState extends State<SignInMethods> {
  late bool _emailOpen = widget.emailOpen;
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apple() => _run(() async {
    final l = AppLocalizations.of(context)!;
    if (!(await widget.account.authConfig()).apple) {
      throw ApiException(l.setupAppleOff, status: 501);
    }
    if (await widget.account.signInWithApple()) await widget.onSignedIn();
  });

  Future<void> _google() => _run(() async {
    if (await widget.account.signInWithGoogle()) await widget.onSignedIn();
  });

  Future<void> _sendLink() => _run(() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      throw ApiException(AppLocalizations.of(context)!.setupEmailInvalid);
    }
    final devLink = await widget.account.sendEmailLink(email);
    if (!mounted) return;
    await context.push(
      SetupPaths.checkEmail(
        widget.checkEmailPath,
        email: email,
        dev: devLink == null ? null : linkToken(devLink),
      ),
    );
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final busy = _busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppleButton(onPressed: busy ? null : _apple),
        const SizedBox(height: 12),
        GoogleButton(onPressed: busy ? null : _google),
        const SizedBox(height: 12),
        if (!_emailOpen)
          AuraButton(
            label: l.setupUseEmail,
            icon: Icons.mail_outline_rounded,
            color: AuraButtonColor.white,
            onPressed: busy ? null : () => setState(() => _emailOpen = true),
          )
        else ...[
          AuraTextField(
            label: l.setupEmailLabel,
            controller: _email,
            autofocus: !widget.emailOpen,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onSubmitted: busy ? null : (_) => _sendLink(),
          ),
          const SizedBox(height: 12),
          AuraButton(
            label: l.setupEmailMeLink,
            color: AuraButtonColor.blue,
            onPressed: busy ? null : _sendLink,
          ),
        ],
        if (busy)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (widget.busyLabel != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.busyLabel!, style: AuraText.body),
                  ),
                ],
              ],
            ),
          ),
        if (_error != null) ErrorNote(_error!),
      ],
    );
  }
}

/// "Continue with Apple" in the app's own button (Apple allows a custom
/// style): Apple's logo artwork, logo and title in the same colour, on
/// white, as large as every other option (HIG, Sign in with Apple).
class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AuraButton(
    label: AppLocalizations.of(context)!.setupContinueApple,
    color: AuraButtonColor.white,
    onPressed: onPressed,
    leading: const ExcludeSemantics(
      child: SizedBox(
        // the logo's own proportions (25:31), sized to the label
        width: 22 * 25 / 31,
        height: 22,
        child: CustomPaint(painter: AppleLogoPainter(color: AuraColors.navy)),
      ),
    ),
  );
}

/// "Continue with Google" in the app's own button (Google allows a custom
/// button): the official full-colour "G", unchanged, on white.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AuraButton(
    label: AppLocalizations.of(context)!.setupContinueGoogle,
    color: AuraButtonColor.white,
    onPressed: onPressed,
    leading: Image.asset(
      'assets/images/google_g.png',
      width: 22,
      height: 22,
      excludeFromSemantics: true,
    ),
  );
}
