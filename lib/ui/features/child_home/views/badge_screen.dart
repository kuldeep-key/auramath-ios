import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';
import 'play_moment.dart';
import 'reward_moments.dart';

/// One badge, large, floating, with its name and one short line (the
/// prototype's B2). Its line: the badge's own, else by kind (a habit's
/// line, "Your medal for…", "You walked all of…", First Case's).
class BadgeScreen extends StatelessWidget {
  const BadgeScreen({
    super.key,
    required this.id,
    required this.badge,
    this.world = 'detective',
  });

  final String id;
  final BadgeInfo badge;
  final String world;

  String _line(AppLocalizations l) {
    if (badge.says.isNotEmpty && badge.says != badge.name) return badge.says;
    return BadgeArt.habitLine(l, id) ??
        switch (id.split('.').first) {
          'stop' => l.kidMedalFor(badge.name),
          'land' => l.kidWalkedAll(badge.name),
          _ when id.contains('first_case') => l.kidFirstCaseLine,
          _ => badge.says,
        };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final line = _line(l);
    return PlayMoment(
      gap: 16,
      say: [badge.name, if (line.isNotEmpty) line].join('. '),
      content: [
        Float(
          child: BadgeArt(badgeId: id, world: world, size: 220),
        ),
        Semantics(
          header: true,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            style: AuraText.playTitle.copyWith(color: AuraColors.white),
          ),
        ),
        if (line.isNotEmpty)
          // the prototype's 290 pt line, as padding: the page measures it
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Opacity(opacity: 0.9, child: PlayLine(line)),
          ),
      ],
      bottom: AuraButton(
        label: l.kidBackToBadges,
        color: AuraButtonColor.white,
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Paths.badges),
      ),
    );
  }
}
