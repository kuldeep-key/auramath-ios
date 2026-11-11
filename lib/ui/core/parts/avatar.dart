import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'ribbon.dart';

/// One of the detective avatars a child picks (ACC-12): an id the server
/// stores (`^[a-z0-9_-]{1,32}$`), never a gender.
typedef AvatarChoice = ({String id, IconData icon, Color color, String name});

/// DRAFT for Design (ACC-12, D-48 closed A): gender-neutral detectives as
/// a detective's tool on a coloured disc, until Design draws the set. No
/// face, hair or clothes, so nothing implies a gender. The ids are what
/// the server keeps; Design's art can replace the look under the same ids.
const avatarChoices = <AvatarChoice>[
  (
    id: 'lens',
    icon: Icons.search_rounded,
    color: AuraColors.yellow,
    name: 'Magnifying glass',
  ),
  (
    id: 'print',
    icon: Icons.fingerprint_rounded,
    color: AuraColors.blue,
    name: 'Fingerprint',
  ),
  (id: 'key', icon: Icons.key_rounded, color: AuraColors.green, name: 'Key'),
  (
    id: 'map',
    icon: Icons.explore_rounded,
    color: AuraColors.coral,
    name: 'Compass',
  ),
  (
    id: 'idea',
    icon: Icons.lightbulb_rounded,
    color: AuraColors.badgeGold,
    name: 'Bright idea',
  ),
  (
    id: 'notes',
    icon: Icons.edit_note_rounded,
    color: AuraColors.blueInk,
    name: 'Notebook',
  ),
];

AvatarChoice? avatarById(String? id) =>
    avatarChoices.where((a) => a.id == id).firstOrNull;

/// The child's chosen avatar, or [fallback] (the detective picture, or a
/// grown-up's initial) while they have none or one this build doesn't know.
class AvatarDisc extends StatelessWidget {
  const AvatarDisc({
    super.key,
    required this.avatar,
    required this.size,
    this.fallback,
  });

  final String? avatar;
  final double size;

  /// Shown with no known avatar; the detective [Portrait] when null.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final a = avatarById(avatar);
    if (a == null) return fallback ?? Portrait(size: size);
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: a.color,
            border: Border.all(
              color: AuraColors.navy,
              width: size < 60 ? 3 : 4,
            ),
          ),
          child: Icon(a.icon, size: size * 0.55, color: AuraColors.white),
        ),
      ),
    );
  }
}

/// The avatars to choose from, the chosen one ringed. Each is a 56 pt
/// button named for screen readers.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final a in avatarChoices)
        Semantics(
          button: true,
          selected: a.id == selected,
          label: a.name,
          child: InkResponse(
            onTap: () => onPick(a.id),
            radius: 32,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: a.id == selected
                      ? AuraColors.yellowLip
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: AvatarDisc(avatar: a.id, size: 56),
            ),
          ),
        ),
    ],
  );
}
