import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import 'play_message.dart';

/// The phone is paired and the child chosen. Figma: PhoneJoined (644:240).
class PhoneJoinedScreen extends StatelessWidget {
  const PhoneJoinedScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMessage(
      art: const EmojiArt('🎉', size: 100),
      title: l.pairYoureIn(name),
      line: l.pairPhoneYours,
      buttons: [
        AuraButton(
          label: l.pairLetsGo,
          onPressed: () => context.go(Paths.home),
        ),
      ],
    );
  }
}
