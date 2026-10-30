import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'badge_disc.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// The badges earned on this phone, then the ones still to earn.
/// Figma: B1 My badges (650:233). Never a count.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.earned, required this.badges});

  /// Badge ids, first earned first.
  final List<String> earned;

  /// Every badge the pack can award.
  final Map<String, BadgeInfo> badges;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final white = AuraColors.white;
    final toEarn = [
      for (final id in badges.keys)
        if (!earned.contains(id)) id,
    ];
    return AuraPage(
      play: true,
      top: PlayHeader(title: l.kidMyBadges),
      body: Column(
        spacing: 12,
        children: [
          const SizedBox(height: 6),
          if (earned.isEmpty)
            PlayLine(l.kidNoBadgesYet)
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final id in earned)
                  _Earned(id: id, name: badges[id]?.name ?? id),
              ],
            ),
          if (toEarn.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l.kidNextToEarn.toUpperCase(),
              style: AuraText.eyebrow.copyWith(color: white),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 16,
              children: [
                for (final id in toEarn)
                  SizedBox(
                    width: 100,
                    child: Column(
                      spacing: 6,
                      children: [
                        BadgeDisc(
                          art: badgeArt(id),
                          size: 100,
                          look: BadgeLook.ghost,
                        ),
                        Text(
                          badges[id]!.name,
                          style: AuraText.badgeNext.copyWith(color: white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Earned extends StatelessWidget {
  const _Earned({required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: name,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () => context.push(Paths.badge(id)),
      child: SizedBox(
        width: 142,
        child: Column(
          spacing: 8,
          children: [
            BadgeDisc(art: badgeArt(id), size: 130),
            Text(name, textAlign: TextAlign.center, style: AuraText.badgeName),
          ],
        ),
      ),
    ),
  );
}
