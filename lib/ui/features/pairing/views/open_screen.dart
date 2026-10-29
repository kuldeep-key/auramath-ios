import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// The first screen on a fresh phone: a child pairs it, a grown-up sets
/// up or signs in. Figma: Open · Who's here? (644:107).
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
                Portrait(size: 120),
                SizedBox(width: 6),
                Portrait(size: 96, image: 'assets/images/detective_girl.jpg'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(l.pairBrand, style: AuraText.brand),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: Ribbon(text: l.pairWhosUsing),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.pairImAKid,
            onPressed: () => context.push(Paths.pair),
          ),
          const SizedBox(height: 12),
          AuraButton(
            label: l.pairImAGrownUp,
            color: AuraButtonColor.white,
            onPressed: () => context.push(Paths.welcome),
          ),
          const SizedBox(height: 4),
          AuraLink(
            label: l.pairHaveAccount,
            light: true,
            onPressed: () => context.push(Paths.signIn),
          ),
        ],
      ),
    );
  }
}
