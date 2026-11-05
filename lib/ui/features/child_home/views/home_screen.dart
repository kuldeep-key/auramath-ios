import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'play_icon_button.dart';

/// The child's home: their detective, the next case, the trail and the
/// badges. Figma: Home (649:2).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.name, required this.grownUps});

  /// The child's name; null shows the portrait alone.
  final String? name;

  /// Where the lock goes: the picker on a grown-up's phone, sign-in on the
  /// child's own phone.
  final String grownUps;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      top: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const Portrait(size: 52),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name ?? '',
                overflow: TextOverflow.ellipsis,
                style: AuraText.kidName,
              ),
            ),
            PlayIconButton(
              icon: Icons.lock_outline_rounded,
              tooltip: l.kidForGrownUps,
              onPressed: () => context.go(grownUps),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 32,
        children: [
          const Portrait(size: 210),
          Ribbon(text: l.readyForNewCase),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          AuraButton(
            label: l.keepGoing,
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.go(Paths.lessonNext),
          ),
          // Figma's icons don't fit beside the labels in a half-width button
          // on a phone; they show where there is room (iPad).
          LayoutBuilder(
            builder: (context, c) {
              final roomy = c.maxWidth >= 420;
              return Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: AuraButton(
                      label: l.kidMyTrail,
                      icon: roomy ? Icons.route_rounded : null,
                      color: AuraButtonColor.white,
                      onPressed: () => context.push(Paths.trail),
                    ),
                  ),
                  Expanded(
                    child: AuraButton(
                      label: l.kidMyBadges,
                      icon: roomy ? Icons.military_tech_rounded : null,
                      color: AuraButtonColor.white,
                      onPressed: () => context.push(Paths.badges),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
