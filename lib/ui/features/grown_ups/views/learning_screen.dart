import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'parts.dart';

/// "L4" reads as "4"; a level id of another shape reads as it is.
String levelLabel(String level) =>
    RegExp(r'^L(\d+)$').firstMatch(level)?.group(1) ?? level;

/// One level change in plain words. Going back is for confidence, never
/// a failure.
String levelChangeLine(AppLocalizations l, LevelChange c) => switch (c.reason) {
  'move_up' => l.guLearningMovedUp(levelLabel(c.to)),
  'down_now' || 'down_next_session' => l.guLearningWentBack,
  _ => l.guLearningChanged(levelLabel(c.to)),
};

/// Where the child is (FL-17; no Figma frame yet), from the server's
/// learning memory: each question type's level and how it changed, newest
/// first. No score, count or number that judges the child. Opened from a
/// child on Family; links on to changing the child's details.
class LearningScreen extends StatelessWidget {
  const LearningScreen({
    super.key,
    required this.childId,
    required this.family,
    required this.repo,
  });

  final String childId;
  final FamilyRepository family;
  final GrownUpRepository repo;

  @override
  Widget build(BuildContext context) => Loaded<(Child, List<LearningType>)>(
    load: () => withChild(family, childId, () => repo.learning(childId)),
    fallback: Paths.family,
    builder: (context, data, reload) {
      final (child, types) = data;
      final l = AppLocalizations.of(context)!;
      return AuraPage(
        top: const AuraTopBar(fallback: Paths.family),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(
              title: l.guLearningTitle(child.name),
              subtitle: l.guLearningBody(child.name),
            ),
            if (types.isEmpty)
              GuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.guLearningEmpty, style: AuraText.option),
                    const SizedBox(height: 6),
                    Text(
                      l.guLearningEmptyBody(child.name),
                      style: AuraText.cardLine,
                    ),
                  ],
                ),
              ),
            for (final t in types) ...[
              _TypeCard(type: t),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            NavRow(
              icon: Icons.edit_outlined,
              label: l.guLearningEdit(child.name),
              detail: l.guLearningEditBody,
              onTap: () async {
                await context.push(Paths.editChild(child.id));
                reload();
              },
            ),
          ],
        ),
      );
    },
  );
}

/// A question type: its name, the level now, and its changes.
class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final LearningType type;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final level = type.level;
    return GuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.id == 'cmp.comparison'
                ? l.guLearningComparison
                : l.guLearningOther,
            style: AuraText.option,
          ),
          if (level != null) ...[
            const SizedBox(height: 4),
            KvRow(
              label: l.guLearningLevel(levelLabel(level)),
              value: l.guLearningNow,
              divider: false,
            ),
          ],
          SectionLabel(l.guLearningHistory),
          if (type.changes.isEmpty)
            Text(l.guLearningNoChanges, style: AuraText.cardLine),
          for (final c in type.changes.reversed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: AuraText.small),
                  Expanded(
                    child: Text(levelChangeLine(l, c), style: AuraText.small),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
