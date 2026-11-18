import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/theme/tokens.dart';
import 'reward_moments.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';
import '../../../core/parts/max_width.dart';

/// The badge cabinet (REW-12): the badges the child has earned, first
/// earned first, and nothing else: no outlines, no "next to earn", never a
/// count (rules.yaml `cabinet`). The next stop is on the trail. Tapping a
/// badge opens the case it came from ([cases], while the casebook is on,
/// REW-15), else the badge alone ([onOpen] logs `badge_opened`). The prototype's B1: two
/// columns, each badge popping in 60 ms after the one before; with none
/// yet, the tutor and "Your badges will live here."
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({
    super.key,
    required this.earned,
    required this.badges,
    this.world = 'detective',
    this.onOpen,
    this.cases = const {},
    this.tutorId,
    this.tutorKind = 'grown_up_teacher',
  });

  /// Badge ids, first earned first.
  final List<String> earned;

  /// The earned badges' names (and lines), by id.
  final Map<String, BadgeInfo> badges;
  final String world;
  final ValueChanged<String>? onOpen;

  /// REW-12: the case each badge came from (its `problemId`), by badge id;
  /// empty while the casebook is off, so every badge opens alone.
  final Map<String, String> cases;

  /// The child's tutor, standing in the empty cabinet.
  final String? tutorId;
  final String tutorKind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      for (final (i, id) in earned.indexed)
        Pop(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: i * 60),
          child: _Earned(
            id: id,
            name: badges[id]?.name ?? id,
            world: world,
            problemId: cases[id],
            onOpen: onOpen,
          ),
        ),
    ];
    return AuraPage(
      play: true,
      say: earned.isEmpty
          ? '${l.kidBadgeCabinet}. ${l.kidCabinetEmpty}'
          : l.kidBadgeCabinet,
      top: PlayHeader(title: l.kidBadgeCabinet),
      body: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: earned.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  if (tutorId != null)
                    TutorFigure(
                      tutorId: tutorId!,
                      kind: tutorKind,
                      world: world,
                      size: 150,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: PlayLine(l.kidCabinetEmpty),
                  ),
                ],
              )
            : Column(
                spacing: 20,
                children: [
                  for (var i = 0; i < items.length; i += 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 12,
                      children: [
                        Expanded(child: Center(child: items[i])),
                        Expanded(
                          child: i + 1 < items.length
                              ? Center(child: items[i + 1])
                              : const SizedBox(),
                        ),
                      ],
                    ),
                ],
              ),
      ),
      bottom: AuraButton(
        label: l.kidBackHome,
        onPressed: () => context.go(Paths.home),
      ),
    );
  }
}

class _Earned extends StatelessWidget {
  const _Earned({
    required this.id,
    required this.name,
    required this.world,
    this.problemId,
    this.onOpen,
  });

  final String id;
  final String name;
  final String world;
  final String? problemId;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: name,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () {
        onOpen?.call(id);
        context.push(
          problemId == null
              ? Paths.badge(id)
              : Paths.casebookCase(problemId!, badge: id),
        );
      },
      child: MaxWidth(
        maxWidth: 150,
        minHeight: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            BadgeArt(badgeId: id, world: world, size: 128),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AuraText.badgeName.copyWith(
                fontWeight: FontWeight.w900,
                fontVariations: const [FontVariation('wght', 900)],
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
