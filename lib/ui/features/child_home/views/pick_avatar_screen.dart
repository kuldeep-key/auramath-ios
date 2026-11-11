import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/avatar.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// The child picks their detective (ACC-12), on their own phone or a
/// shared one: the six gender-neutral avatars, then "That's me!", which
/// [onSave]s it (the server keeps it, so every phone shows it). DRAFT for
/// Design: no Figma frame; built from the play screens' parts.
class PickAvatarScreen extends StatefulWidget {
  const PickAvatarScreen({
    super.key,
    required this.current,
    required this.onSave,
  });

  /// The avatar the child has now, if any.
  final String? current;

  /// Saves the pick; throws when it can't be (offline, refused).
  final Future<void> Function(String avatar) onSave;

  @override
  State<PickAvatarScreen> createState() => _PickAvatarScreenState();
}

class _PickAvatarScreenState extends State<PickAvatarScreen> {
  late String? _picked = widget.current;
  bool _saving = false;
  bool _failed = false;

  /// The server says this phone may not set it (BE-20's 403: a sibling who
  /// has never had a lesson on this shared phone): a grown-up sets it.
  bool _askGrownUp = false;

  Future<void> _save() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(picked);
      if (mounted) context.go(Paths.home);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => e.status == 403 ? _askGrownUp = true : _failed = true);
      }
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMoment(
      top: Align(
        alignment: Alignment.centerLeft,
        child: PlayIconButton(
          icon: Icons.home_outlined,
          tooltip: l.kidHome,
          onPressed: () => context.go(Paths.home),
        ),
      ),
      content: [
        AvatarDisc(avatar: _picked, size: 140),
        Ribbon(text: l.kidPickAvatar),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.navy, width: 3),
          ),
          child: AvatarPicker(
            selected: _picked,
            onPick: (id) => setState(() => _picked = id),
          ),
        ),
        if (_askGrownUp)
          PlayLine(l.kidPickAvatarAskGrownUp)
        else if (_failed)
          PlayLine(l.kidPickAvatarFailed),
      ],
      bottom: ButtonStack([
        AuraButton(
          key: const Key('avatarSave'),
          label: l.kidPickAvatarSave,
          onPressed: _picked == null || _saving || _askGrownUp ? null : _save,
        ),
      ]),
    );
  }
}
