import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../deps.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../setup_paths.dart';
import 'setup_parts.dart';

/// Lock (644:20): Face ID for the grown-up area. A passcode is set either
/// way: it is the fallback, and what other phones use.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.deps,
    required this.childId,
    required this.name,
  });

  final Deps deps;
  final String childId;
  final String name;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _error;
  bool _busy = false;

  void _choosePasscode() => context.push(
    SetupPaths.withChild(
      SetupPaths.passcode,
      id: widget.childId,
      name: widget.name,
    ),
  );

  Future<void> _faceId() async {
    final l = AppLocalizations.of(context)!;
    final lock = widget.deps.deviceLock;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = !await lock.available()
          ? l.setupFaceIdMissing
          : !await lock.unlock(l.setupLockTitle)
          ? l.setupFaceIdFailed
          : null;
      if (error == null) await widget.deps.account.setUseFaceId(true);
      if (!mounted) return;
      if (error == null) {
        _choosePasscode();
      } else {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: AuraTopBar(
        fallback: SetupPaths.withChild(
          Paths.setupReady,
          id: widget.childId,
          name: widget.name,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraHeading(title: l.setupLockTitle, subtitle: l.setupLockBody),
          const SizedBox(height: 22),
          const IconTile(
            icon: Icons.face_outlined,
            color: AuraColors.blue,
            background: AuraColors.blueTint,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            ErrorNote(_error!),
          ],
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.setupUseFaceId,
            color: AuraButtonColor.blue,
            onPressed: _busy ? null : _faceId,
          ),
          const SizedBox(height: 12),
          AuraButton(
            label: l.setupUsePasscode,
            color: AuraButtonColor.white,
            onPressed: _busy ? null : _choosePasscode,
          ),
        ],
      ),
    );
  }
}
