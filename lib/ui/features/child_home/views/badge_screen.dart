import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';
import 'play_moment.dart';

/// One badge, large, and what the child did to earn it. Figma: B2 Badge
/// close-up (651:2).
class BadgeScreen extends StatelessWidget {
  const BadgeScreen({super.key, required this.id, required this.badge});

  final String id;
  final BadgeInfo badge;

  @override
  Widget build(BuildContext context) => PlayMoment(
    content: [
      BadgeDisc(art: badgeArt(id), size: 220, look: BadgeLook.blue),
      const SizedBox(height: 8),
      Semantics(
        header: true,
        child: Text(
          badge.name,
          textAlign: TextAlign.center,
          style: AuraText.heading.copyWith(color: AuraColors.white),
        ),
      ),
      PlayLine(badge.says),
    ],
    bottom: AuraButton(
      label: AppLocalizations.of(context)!.kidBackToBadges,
      color: AuraButtonColor.white,
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(Paths.badges),
    ),
  );
}
