import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// The first screen on a fresh phone: a child pairs it, a grown-up sets
/// up or signs in. Figma: Open · Who's here? (644:107); words and the two
/// floating detectives as the prototype's Open (16 Nov).
class OpenScreen extends StatelessWidget {
  const OpenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Float(child: LookPortrait(lookId: 'look_02', size: 120)),
                SizedBox(width: 6),
                Float(child: LookPortrait(lookId: 'look_04', size: 96)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(l.pairBrand, style: AuraText.brand),
          ),
          const SizedBox(height: 26),
          Ribbon(text: l.pairReadyToPlay),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.pairPlay,
            leading: const Icon(
              Icons.play_arrow_rounded,
              size: 30,
              color: AuraColors.buttonYellowText,
            ),
            onPressed: () => context.push(Paths.pair),
          ),
          const SizedBox(height: 12),
          AuraButton(
            label: l.pairParentsAndCarers,
            leading: const Icon(
              Icons.lock_rounded,
              size: 26,
              color: AuraColors.navy,
            ),
            color: AuraButtonColor.white,
            onPressed: () => context.push(Paths.welcome),
          ),
          const SizedBox(height: 4),
          AuraLink(
            label: l.pairSetUpSignIn,
            light: true,
            onPressed: () => context.push(Paths.signIn),
          ),
        ],
      ),
    );
  }
}
