import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/api.dart';
import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/code_boxes.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/theme/tokens.dart';
import '../setup_paths.dart';
import 'setup_parts.dart';

/// Choose a passcode: not in Figma, built from GPass (652:173). The server
/// says how many digits; the grown-up types it twice. Then the phone is
/// handed over to the child.
class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({
    super.key,
    required this.deps,
    required this.childId,
    required this.name,
  });

  final Deps deps;
  final String childId;
  final String name;

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  ({bool set, int length})? _status;
  String? _first;
  String _typed = '';

  /// A new keypad each round, so it starts empty.
  int _round = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await widget.deps.family.passcodeStatus();
      if (mounted) setState(() => _status = (set: s.set, length: s.length));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _restart(String? error) => setState(() {
    _first = null;
    _typed = '';
    _round++;
    _error = error;
  });

  void _changed(String v) {
    setState(() => _typed = v);
    if (v.length < _status!.length) return;
    final l = AppLocalizations.of(context)!;
    if (_first == null) {
      setState(() {
        _first = v;
        _typed = '';
        _round++;
        _error = null;
      });
    } else if (v != _first) {
      _restart(l.setupPassMismatch);
    } else {
      _save(v);
    }
  }

  Future<void> _save(String passcode) async {
    setState(() => _busy = true);
    try {
      await widget.deps.family.setPasscode(passcode);
      await _handOver();
    } on ApiException catch (e) {
      if (mounted) _restart(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handOver() async {
    await widget.deps.account.chooseChild(widget.childId);
    if (mounted) context.go(Paths.home);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final status = _status;
    final top = AuraTopBar(
      fallback: SetupPaths.withChild(
        Paths.setupLock,
        id: widget.childId,
        name: widget.name,
      ),
    );

    if (status == null || status.set) {
      // loading, failed to load, or a passcode the family already has
      return AuraPage(
        top: top,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status != null)
              AuraHeading(
                title: l.setupPassAlreadySet,
                subtitle: l.setupPassAlreadySetBody,
              )
            else if (_error == null)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ErrorNote(_error!),
          ],
        ),
        bottom: status != null
            ? AuraButton(
                label: l.setupHandOver(widget.name),
                color: AuraButtonColor.blue,
                onPressed: _handOver,
              )
            : _error != null
            ? AuraButton(
                label: l.setupTryAgain,
                color: AuraButtonColor.blue,
                onPressed: _load,
              )
            : null,
      );
    }

    final again = _first != null;
    // Material: the keypad sits outside the page's Scaffold
    return Material(
      color: AuraColors.white,
      child: Column(
        children: [
          Expanded(
            child: AuraPage(
              top: top,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuraHeading(
                    title: again ? l.setupPassAgainTitle : l.setupPassTitle,
                    subtitle: again
                        ? l.setupPassAgainBody(status.length)
                        : l.setupPassBody(status.length),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: codeBoxesHeight,
                    child: CodeBoxes(
                      length: status.length,
                      value: _typed,
                      obscure: true,
                    ),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    ErrorNote(_error!),
                  ],
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _busy,
            child: Keypad(
              key: ValueKey(_round),
              maxDigits: status.length,
              onChanged: _changed,
              // a full passcode goes on by itself; Check with fewer digits
              onCheck: (_) =>
                  setState(() => _error = l.setupPassShort(status.length)),
            ),
          ),
        ],
      ),
    );
  }
}
