import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'reward_moments.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// The badge cabinet (REW-12): the badges the child has earned, first
/// earned first, and nothing else: no outlines, no "next to earn", never a
/// count (rules.yaml `cabinet`). The next stop is on the trail. Tapping a
/// badge opens it ([onOpen] logs `badge_opened`). Figma: B1 My badges
/// (650:233), without its "next to earn" row.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({
    super.key,
    required this.earned,
    required this.badges,
    this.world = 'detective',
    this.onOpen,
  });

  /// Badge ids, first earned first.
  final List<String> earned;

  /// The earned badges' names (and lines), by id.
  final Map<String, BadgeInfo> badges;
  final String world;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      say: earned.isEmpty
          ? '${l.kidBadgeCabinet}. ${l.kidCabinetEmpty}'
          : l.kidBadgeCabinet,
      top: PlayHeader(title: l.kidBadgeCabinet),
      body: Column(
        spacing: 12,
        children: [
          const SizedBox(height: 6),
          if (earned.isEmpty)
            PlayLine(l.kidCabinetEmpty)
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final (i, id) in earned.indexed)
                  Pop(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: i * 60),
                    child: _Earned(
                      id: id,
                      name: badges[id]?.name ?? id,
                      world: world,
                      onOpen: onOpen,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Earned extends StatelessWidget {
  const _Earned({
    required this.id,
    required this.name,
    required this.world,
    this.onOpen,
  });

  final String id;
  final String name;
  final String world;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: name,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () {
        onOpen?.call(id);
        context.push(Paths.badge(id));
      },
      child: SizedBox(
        width: 142,
        child: Column(
          spacing: 8,
          children: [
            BadgeArt(badgeId: id, world: world, size: 130),
            Text(name, textAlign: TextAlign.center, style: AuraText.badgeName),
          ],
        ),
      ),
    ),
  );
}
