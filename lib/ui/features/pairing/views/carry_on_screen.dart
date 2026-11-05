import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import 'play_message.dart';

/// The case was started on another phone; it carries on here.
/// Figma: OtherPhone · Carry on here? (653:24).
class CarryOnScreen extends StatelessWidget {
  const CarryOnScreen({super.key, this.device});

  /// The label of the phone the case started on, if known.
  final String? device;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final from = device;
    return PlayMessage(
      art: const EmojiArt('📱➡️📱'),
      title: l.pairCarryOn,
      line: from == null || from.isEmpty
          ? l.pairStartedElsewhere
          : l.pairStartedOn(from),
      buttons: [
        AuraButton(
          label: l.pairCarryOnHere,
          onPressed: () => context.go(Paths.lessonCarryOnHere),
        ),
      ],
    );
  }
}
