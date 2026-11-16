import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/grown_up_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../setup/views/year_screen.dart' show yearLabel;
import 'parts.dart';

/// "L4" reads as "4"; a level id of another shape reads as it is.
String levelLabel(String level) =>
    RegExp(r'^L(\d+)$').firstMatch(level)?.group(1) ?? level;

/// One level change in plain words, with no level number (JRN-06, as the
/// prototype's ChildDetail). Going back is for confidence, never a
/// failure.
String levelChangeLine(AppLocalizations l, LevelChange c) => switch (c.reason) {
  'move_up' => l.guLearningMovedUpPlain,
  'down_now' || 'down_next_session' => l.guLearningWentBack,
  _ => l.guLearningChangedPlain,
};

/// ChildDetail (the prototype's, FL-17): tapping a child on the Family
/// area opens this. Their picture (tap to change), how they are doing
/// (what they are working on, from the server's learning memory), their
/// journey (each type's level changes, newest first, in words), and the
/// details to change (ACC-14). No score, count or level number, nothing
/// that judges the child (PAR-03, JRN-06).
///
/// Reads the child again when this phone changes one
/// ([FamilyRepository.childrenChanged]), so a new name shows on return.
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
    refresh: family.childrenChanged,
    fallback: Paths.grownUps,
    builder: (context, data, reload) {
      final (child, types) = data;
      final l = AppLocalizations.of(context)!;
      Future<void> edit() async {
        await context.push(Paths.editChild(child.id));
        reload();
      }

      String typeName(LearningType t) =>
          t.id == 'cmp.comparison' ? l.guLearningComparison : l.guLearningOther;
      final year = child.schoolYear;
      return AuraPage(
        top: const AuraTopBar(fallback: Paths.grownUps),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuraHeading(title: child.name),
            Center(
              child: _EditablePortrait(child: child, onTap: edit),
            ),
            PartLabel(l.guChildDoing(child.name), top: 14),
            GuCard(
              child: types.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.guLearningEmpty, style: AuraText.option),
                        const SizedBox(height: 6),
                        Text(
                          l.guLearningEmptyBody(child.name),
                          style: AuraText.cardLine,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.guChildWorkingOn, style: AuraText.kvLabel),
                        for (final t in types)
                          Text(typeName(t), style: AuraText.kvValue),
                      ],
                    ),
            ),
            if (types.isNotEmpty) ...[
              PartLabel(l.guChildJourney(child.name)),
              for (final t in types) ...[
                _TypeCard(name: typeName(t), type: t),
                const SizedBox(height: 12),
              ],
            ],
            PartLabel(l.guChildDetails, top: types.isEmpty ? 16 : 4),
            GuCard(
              child: Column(
                children: [
                  KvRow(
                    label: l.guChildFirstName,
                    value: child.name,
                    chevron: true,
                    onTap: edit,
                  ),
                  KvRow(
                    label: l.guChildAge,
                    value: child.age?.toString() ?? l.guChildNotSet,
                    chevron: true,
                    onTap: edit,
                  ),
                  KvRow(
                    label: l.guChildYear,
                    value: year == null ? l.guChildNotSet : yearLabel(l, year),
                    chevron: true,
                    divider: false,
                    onTap: edit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NavRow(
              icon: Icons.edit_rounded,
              label: l.guLearningEdit(child.name),
              detail: l.guLearningEditBody,
              onTap: edit,
            ),
          ],
        ),
      );
    },
  );
}

/// The child's picture, 110 pt, with a blue pencil badge: tapping changes
/// it (the prototype's `childlook`; here, the details screen's picker).
class _EditablePortrait extends StatelessWidget {
  const _EditablePortrait({required this.child, required this.onTap});

  final Child child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppLocalizations.of(context)!.guChildPicture(child.name),
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          children: [
            ChildAvatar(name: child.name, avatar: child.avatar, size: 110),
            Positioned(
              right: 0,
              bottom: 4,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AuraColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AuraColors.white, width: 3),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AuraColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A question type and how its level changed, in words.
class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.name, required this.type});

  final String name;
  final LearningType type;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KvRow(label: name, value: l.guChildNow, divider: false),
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
