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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (widget.busyLabel != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
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

/// Apple's own Sign in with Apple button (ACC-02, D-38: official buttons
/// for store review), from `sign_in_with_apple`: the black style, Apple's
/// logo and its "Continue with Apple" title, drawn by the package to the
/// HIG. Taller than its 44 pt default and with the app's corners, which
/// the HIG allows, so it lines up with the other options.
class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SignInWithAppleButton(
    key: const Key('appleSignIn'),
    text: AppLocalizations.of(context)!.setupContinueApple,
    height: 56,
    borderRadius: BorderRadius.circular(AuraRadii.small),
    onPressed: onPressed,
  );
}

/// Google's "Continue with Google" button built to its branding
/// guidelines (ACC-02, D-38; the Flutter plugin ships no button on
/// iOS or Android): the light theme, a #FFFFFF fill with a 1 px #747775
/// stroke, the standard full-colour "G" unchanged, then the label in
/// Roboto Medium, #1F1F1F, the logo 12 from the left edge and 10 from the
/// label. Scaled up evenly from the 40 dp spec to the other options'
/// height, in the pill shape.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  /// The spec's 40 dp button, scaled to 56.
  static const _scale = 56 / 40;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.setupContinueGoogle;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        // the spec's disabled state: the whole button at 38%
        opacity: enabled ? 1 : 0.38,
        child: Material(
          key: const Key('googleSignIn'),
          color: const Color(0xFFFFFFFF),
          shape: const StadiumBorder(
            side: BorderSide(color: Color(0xFF747775)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 40 * _scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12 * _scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_g.png',
                      width: 20 * _scale,
                      height: 20 * _scale,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 10 * _scale),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 14 * _scale,
                          height: 20 / 14,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
