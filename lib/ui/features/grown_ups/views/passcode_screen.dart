import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../data/services/api.dart';
import '../../../../data/services/device_lock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/code_boxes.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

enum _Mode { enter, choose, confirm }

/// GPass (652:173): Face ID first if the grown-up chose it, then the
/// family passcode. With none set yet, or after "Forgot passcode?" and a
/// fresh sign-in, the same keypad chooses one (typed twice).
class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({
    super.key,
    required this.account,
    required this.family,
    required this.repo,
    required this.deviceLock,
    this.to,
  });

  final AccountRepository account;
  final FamilyRepository family;
  final GrownUpRepository repo;
  final DeviceLock deviceLock;

  /// Where to go once unlocked.
  final String? to;

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  int? _length;
  Object? _loadError;
  DateTime? _lockedUntil;
  bool _reset = false;
  _Mode _mode = _Mode.enter;
  String _typed = '';
  String _beforeCheck = '';
  String? _first;
  String? _message;
  bool _busy = false;
  int _pad = 0;

  AppLocalizations get _l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final status = await widget.family.passcodeStatus();
      final reset = await widget.repo.passcodeResetReady(widget.account.bearer);
      if (!mounted) return;
      setState(() {
        _length = status.length;
        _reset = status.set && reset;
        _mode = !status.set || _reset ? _Mode.choose : _Mode.enter;
        _lockedUntil = status.lockedUntil == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(status.lockedUntil!);
        _message = _lockedMessage();
      });
      if (_mode == _Mode.enter && widget.account.useFaceId) await _faceId();
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  String? _lockedMessage() => _lockedUntil == null
      ? null
      : _l.guPassLocked(TimeOfDay.fromDateTime(_lockedUntil!).format(context));

  Future<void> _faceId() async {
    if (await widget.deviceLock.unlock(_l.guFaceIdReason)) _open();
  }

  void _open() {
    if (!mounted) return;
    widget.account.unlockGrownUps();
    context.go(widget.to ?? Paths.grownUps);
  }

  void _changed(String v) {
    setState(() {
      if (v.isEmpty) _beforeCheck = _typed;
      _typed = v;
      if (v.isNotEmpty) _message = null;
    });
    if (v.length == _length) _submit(v);
  }

  void _checked(int _) {
    if (_beforeCheck.length < _length!) {
      setState(() => _message = _l.guPassShort(_length!));
    }
  }

  /// Clears the boxes and the keypad.
  void _clear({String? message, bool shake = false}) {
    setState(() {
      _typed = '';
      _pad++;
      _message = message;
    });
    if (shake && !MediaQuery.of(context).disableAnimations) {
      _shake.forward(from: 0);
    }
  }

  Future<void> _submit(String code) async {
    switch (_mode) {
      case _Mode.choose:
        _first = code;
        _mode = _Mode.confirm;
        _clear();
      case _Mode.confirm:
        if (code != _first) {
          _mode = _Mode.choose;
          _clear(message: _l.guPassMismatch, shake: true);
          return;
        }
        await _guard(() async {
          await widget.family.setPasscode(code);
          await widget.repo.endPasscodeReset();
          _open();
        }, onFail: () => _mode = _Mode.choose);
      case _Mode.enter:
        await _guard(() async {
          if (await widget.family.checkPasscode(code)) {
            _open();
          } else {
            _clear(message: _l.guPassWrong, shake: true);
          }
        });
    }
  }

  Future<void> _guard(
    Future<void> Function() run, {
    VoidCallback? onFail,
  }) async {
    setState(() => _busy = true);
    try {
      await run();
    } on ApiException catch (e) {
      onFail?.call();
      if (e.status == 429) {
        await _load();
        _clear(message: _lockedMessage() ?? _l.guPassLockedSoon, shake: true);
      } else if (e.status == 404 && _mode == _Mode.enter) {
        // none set after all (a new family): choose one
        _mode = _Mode.choose;
        _clear();
      } else if (e.status == 403 && _reset) {
        _clear(message: _l.guPassResetBlocked);
      } else {
        _clear(message: e.message, shake: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final (title, subtitle) = switch (_mode) {
      _Mode.enter => (l.guPassTitle, l.guPassEnter),
      _Mode.choose => (
        _reset ? l.guPassNewTitle : l.guPassChooseTitle,
        l.guPassChooseBody(_length ?? 4),
      ),
      _Mode.confirm => (l.guPassConfirmTitle, l.guPassConfirmBody),
    };
    final length = _length;
    final page = AuraPage(
      top: const AuraTopBar(fallback: Paths.kids),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuraHeading(title: title, subtitle: subtitle),
          if (_loadError != null)
            ErrorNote(_loadError!, onRetry: _load)
          else if (length == null)
            const Spinner()
          else ...[
            const SizedBox(height: 22),
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  math.sin(_shake.value * math.pi * 6) *
                      10 *
                      (1 - _shake.value),
                  0,
                ),
                child: child,
              ),
              child: CodeBoxes(length: length, value: _typed, obscure: true),
            ),
            const SizedBox(height: 16),
            if (_busy) const Spinner(),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: AuraText.body,
                ),
              ),
            if (_mode == _Mode.enter) ...[
              AuraLink(
                label: l.guPassForgot,
                onPressed: () => context.push(Paths.forgotPasscode),
              ),
              if (widget.account.useFaceId)
                AuraLink(label: l.guUseFaceId, onPressed: _faceId),
            ],
          ],
        ],
      ),
    );
    return Scaffold(
      backgroundColor: AuraColors.white,
      body: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: page,
            ),
          ),
          if (length != null)
            IgnorePointer(
              ignoring: _busy,
              child: Keypad(
                key: ValueKey(_pad),
                maxDigits: length,
                onChanged: _changed,
                onCheck: _checked,
              ),
            ),
        ],
      ),
    );
  }
}
