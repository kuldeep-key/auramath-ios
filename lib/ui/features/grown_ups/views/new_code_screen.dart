import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/code_boxes.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// NewCode (653:89): a six-digit code to type on the child's phone. It
/// counts down to the server's expiry; once stopped, get a new one.
class NewCodeScreen extends StatefulWidget {
  const NewCodeScreen({
    super.key,
    required this.family,
    required this.repo,
    this.now = DateTime.now,
  });

  final FamilyRepository family;
  final GrownUpRepository repo;
  final DateTime Function() now;

  @override
  State<NewCodeScreen> createState() => _NewCodeScreenState();
}

class _NewCodeScreenState extends State<NewCodeScreen> {
  ({String code, DateTime expiresAt})? _code;
  List<Child> _children = const [];
  Object? _error;
  bool _renewed = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _get();
    widget.family.children().then(
      (c) => mounted ? setState(() => _children = c) : null,
      // the button falls back to "your child's phone"
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _get() async {
    final renew = _code != null;
    setState(() {
      _error = null;
      _code = null;
    });
    try {
      final code = await widget.repo.pairingCode();
      if (!mounted) return;
      setState(() {
        _code = code;
        _renewed = renew;
      });
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = _code;
    final left = code?.expiresAt.difference(widget.now());
    final expired = left != null && left <= Duration.zero;
    if (expired) _tick?.cancel();
    final mmss = left == null || expired
        ? ''
        : '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.family),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(
            title: _renewed ? l.guCodeNewTitle : l.guCodeTitle,
            subtitle: _renewed ? l.guCodeNewBody : null,
          ),
          if (_error != null)
            ErrorNote(_error!, onRetry: _get)
          else if (code == null)
            const Spinner()
          else ...[
            const SizedBox(height: 16),
            Opacity(
              opacity: expired ? 0.4 : 1,
              // a fixed height: CodeBoxes' LayoutBuilder has no intrinsic
              // size, which AuraPage's body asks for
              child: SizedBox(
                height: 60,
                child: CodeBoxes(length: code.code.length, value: code.code),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              liveRegion: expired,
              child: Text(
                expired ? l.guCodeExpired : l.guCodeLeft(mmss),
                textAlign: TextAlign.center,
                style: AuraText.body.copyWith(color: AuraColors.mute),
              ),
            ),
          ],
        ],
      ),
      bottom: expired || _error != null
          ? AuraButton(
              label: l.guCodeAgain,
              color: AuraButtonColor.blue,
              onPressed: _get,
            )
          : AuraButton(
              label: _children.length == 1
                  ? l.guCodeTypeOn(_children.single.name)
                  : l.guCodeTypeOnChild,
              color: AuraButtonColor.blue,
              onPressed: code == null
                  ? null
                  : () => popOr(context, Paths.family),
            ),
    );
  }
}
