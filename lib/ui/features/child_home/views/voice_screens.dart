import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'play_moment.dart';

/// The phone is muted: the words stay on screen either way. Figma: Sound
/// (650:149). Pops with the contract's `prompt_answered` choice
/// (`sound_on` or `read_myself`) for the lesson to log.
class SoundScreen extends StatelessWidget {
  const SoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Notice(
      icon: Icons.volume_off_rounded,
      iconColor: AuraColors.blue,
      tint: AuraColors.blueTint,
      title: l.kidSoundOff,
      body: l.kidSoundOffBody,
      buttons: [
        AuraButton(
          label: l.kidSoundOn,
          icon: Icons.volume_up_rounded,
          color: AuraButtonColor.blue,
          onPressed: () => _leave(context, 'sound_on'),
        ),
        AuraButton(
          label: l.kidIllRead,
          color: AuraButtonColor.white,
          onPressed: () => _leave(context, 'read_myself'),
        ),
      ],
    );
  }
}

/// No voice installed, or the voice service failed (not muted: that is
/// [SoundScreen]). Figma: NoVoice (659:39).
class NoVoiceScreen extends StatelessWidget {
  const NoVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Notice(
      icon: Icons.record_voice_over_outlined,
      iconColor: AuraColors.yellowInk,
      tint: AuraColors.yellowTint,
      title: l.kidVoiceResting,
      body: l.kidVoiceRestingBody,
      buttons: [
        AuraButton(
          label: l.kidOkLetsGo,
          color: AuraButtonColor.blue,
          onPressed: () => _leave(context, null),
        ),
      ],
    );
  }
}

/// Back to the lesson underneath; home when opened with nothing under it.
void _leave(BuildContext context, String? choice) =>
    context.canPop() ? context.pop(choice) : context.go(Paths.home);

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.body,
    required this.buttons,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String body;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => AuraPage(
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 18,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, size: 64, color: iconColor),
        ),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AuraText.heading,
          ),
        ),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AuraText.play.copyWith(color: AuraColors.mute),
        ),
        const SizedBox(height: 2),
        SizedBox(width: double.infinity, child: ButtonStack(buttons)),
      ],
    ),
  );
}
