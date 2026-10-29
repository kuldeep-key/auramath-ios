import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_moment.dart';

/// Every stop on the trail is done; the grown-up sets the next trail.
/// Figma: TrailTop (659:2). Its "Play Quick sums" is left out: Quick sums
/// isn't built this term.
class TrailTopScreen extends StatelessWidget {
  const TrailTopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMoment(
      gap: 10,
      content: [
        const Art('🏔️', size: 110),
        const Portrait(size: 110),
        const SizedBox(height: 16),
        Ribbon(text: l.kidReachedTop),
        PlayLine(l.kidNewTrailSoon),
      ],
      bottom: AuraButton(
        label: l.kidHome,
        icon: Icons.home_outlined,
        color: AuraButtonColor.white,
        onPressed: () => context.go(Paths.home),
      ),
    );
  }
}
