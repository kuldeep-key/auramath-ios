import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import 'play_message.dart';

/// The case was started on another phone; it carries on here, or the
/// child goes home. The prototype's OtherPhone (rebuilt 16 Nov): it never
/// names the other phone, whose label may name a person (PRV-07).
class CarryOnScreen extends StatelessWidget {
  const CarryOnScreen({super.key, this.device});

  /// The label of the phone the case started on, if known. Not shown: a
  /// label like "Mum's phone" names a person (PRV-07).
  final String? device;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMessage(
      art: const EmojiArt('📱➡️📱'),
      title: l.pairCarryOn,
      line: l.pairStartedElsewhere,
      buttons: [
        AuraButton(
          label: l.pairCarryOnHere,
          onPressed: () => context.go(Paths.lessonCarryOnHere),
        ),
        AuraButton(
          label: l.kidNotNow,
          color: AuraButtonColor.white,
          onPressed: () => context.go(Paths.home),
        ),
      ],
    );
  }
}
