import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_moment.dart';

/// The spaced check a few weeks after moving up (SKL-06). Figma: Check
/// (651:165).
// ponytail: the check's own content isn't built yet, so Let's play opens
// the next case; point it at the check when it exists.
class CheckScreen extends StatelessWidget {
  const CheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMoment(
      content: [
        const Art('🎯', size: 96),
        const SizedBox(height: 10),
        Ribbon(text: l.kidQuickCheck),
        PlayLine(l.kidQuickCheckBody),
      ],
      bottom: AuraButton(
        label: l.kidLetsPlay,
        onPressed: () => context.go(Paths.lessonNext),
      ),
    );
  }
}
