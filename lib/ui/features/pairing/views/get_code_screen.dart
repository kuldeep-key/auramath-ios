import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/code_boxes.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_message.dart';

/// The child types the grown-up's six-digit code to pair this phone.
/// Figma: GetCode · Type your code (644:147).
class GetCodeScreen extends StatefulWidget {
  const GetCodeScreen({super.key, required this.account, required this.family});

  final AccountRepository account;
  final FamilyRepository family;

  @override
  State<GetCodeScreen> createState() => _GetCodeScreenState();
}

class _GetCodeScreenState extends State<GetCodeScreen> {
  static const _length = 6;

  /// What the boxes show.
  String _typed = '';

  /// The keypad's last non-empty value. Its `onCheck` hands over an int,
  /// which would drop a leading zero, so the code comes from here.
  String _last = '';
  bool _busy = false;

  /// Offline or a server failure, with the code to send again.
  String? _error;
  String? _retryCode;

  /// The child came back from CodeWrong's "Grown-up: new code".
  bool _askNew = false;

  /// A wrong code (the prototype's GetCode·CodeWrong): the boxes shake
  /// and "That code didn't work." shows under them; the child types again
  /// here. Too many tries still opens its own screen.
  int _shake = 0;
  bool _wrongNow = false;

  void _changed(String v) {
    if (v.isNotEmpty) _last = v;
    setState(() {
      _typed = v;
      if (v.isNotEmpty) {
        _error = null;
        _wrongNow = false;
      }
    });
  }

  Future<void> _check(String _) async {
    final code = _last;
    // a short code can't be right: don't spend one of the server's tries
    if (code.length < _length) return _wrongHere();
    await _redeem(code);
  }

  Future<void> _redeem(String code) async {
    final l = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    setState(() {
      _busy = true;
      _typed = code;
      _error = null;
      _askNew = false;
    });
    try {
      await widget.account.redeemPairing(code, label: l.pairPhoneLabel);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _typed = '';
      });
      if (e.status == 400) return _wrongHere();
      if (e.status == 429) return _wrong(tooMany: true);
      setState(() {
        _error = failureText(l, e);
        _retryCode = code;
      });
      return;
    }

    // Paired. The router may already have moved this phone on (a paired
    // phone can't stay on /pair), so navigate with the router, not this
    // screen's context.
    List<Child>? children;
    try {
      children = await widget.family.children();
    } on ApiException {
      // WhichChild loads the children again and shows this failure there,
      // with its own Try again.
    }
    final only = children?.length == 1 ? children!.single : null;
    router.go(
      only == null
          ? Paths.pairWhichChild
          : Uri(
              path: Paths.pairIsThisYou,
              queryParameters: {'id': only.id, 'name': only.name},
            ).toString(),
    );
  }

  void _wrongHere() {
    AuraHaptics.wrong();
    AuraSound.wrong();
    setState(() {
      _typed = '';
      _last = '';
      _askNew = false;
      _wrongNow = true;
      _shake++;
    });
  }

  Future<void> _wrong({required bool tooMany}) async {
    final askNew = await context.push<bool>(
      Uri(
        path: Paths.pairWrong,
        queryParameters: tooMany ? {'tooMany': '1'} : null,
      ).toString(),
    );
    if (mounted) setState(() => _askNew = askNew ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final white = AuraText.play;
    // the pad's own 26 pt foot covers most of the home indicator
    final foot = math.max(0.0, MediaQuery.paddingOf(context).bottom - 26);
    return Scaffold(
      backgroundColor: AuraColors.keypadBg,
      body: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: AuraPage(
                play: true,
                // all in `top`: CodeBoxes measures itself with a
                // LayoutBuilder, which the page's body can't hold
                top: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuraTopBar(light: true, fallback: Paths.open),
                    Center(child: Ribbon(text: l.pairTypeCode)),
                    const SizedBox(height: 10),
                    Text(
                      l.pairCodeWhere,
                      textAlign: TextAlign.center,
                      style: white.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 18),
                    CodeBoxes(
                      length: _length,
                      value: _typed,
                      light: true,
                      shake: _shake,
                    ),
                    const SizedBox(height: 10),
                    // `#gcm`: keeps its 24 pt even when empty
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 24),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _wrongNow ? l.pairCodeDidntWork : '',
                          textAlign: TextAlign.center,
                          style: white.copyWith(fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_busy)
                      Center(
                        child: CircularProgressIndicator(
                          color: AuraColors.white,
                          semanticsLabel: l.pairChecking,
                        ),
                      )
                    else if (_error != null)
                      LoadError(
                        message: _error!,
                        retryLabel: l.pairTryAgain,
                        light: true,
                        onRetry: () => _redeem(_retryCode!),
                      )
                    else if (_askNew)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l.pairAskForNewCode,
                          textAlign: TextAlign.center,
                          style: white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: foot),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AbsorbPointer(
                  absorbing: _busy,
                  child: Keypad(
                    maxDigits: _length,
                    onChanged: _changed,
                    onCheck: _check,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
