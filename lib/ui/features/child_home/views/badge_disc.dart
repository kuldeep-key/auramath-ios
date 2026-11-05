import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import 'play_moment.dart';

/// How a badge disc looks: earned in the list or sash, shown large, or not
/// earned yet.
enum BadgeLook { gold, blue, ghost }

/// A round badge. Figma: B1 650:233, B2 651:2, Up 651:35, Y4 648:83.
class BadgeDisc extends StatelessWidget {
  const BadgeDisc({
    super.key,
    required this.art,
    required this.size,
    this.look = BadgeLook.gold,
  });

  final String art;
  final double size;
  final BadgeLook look;

  @override
  Widget build(BuildContext context) {
    final edge = size < 100 ? 4.0 : 6.0;
    final decoration = switch (look) {
      BadgeLook.gold => _lit(
        AuraColors.badgeGoldLight,
        AuraColors.badgeGold,
        AuraColors.badgeGoldEdge,
        AuraColors.badgeGoldLip,
        edge,
      ),
      BadgeLook.blue => _lit(
        AuraColors.badgeBlueLight,
        AuraColors.badgeBlue,
        AuraColors.badgeBlueEdge,
        AuraColors.badgeBlueLip,
        edge,
      ),
      BadgeLook.ghost => BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: AuraColors.white.withValues(alpha: 0.6),
          width: 4,
        ),
      ),
    };
    return Opacity(
      opacity: look == BadgeLook.ghost ? 0.8 : 1,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: decoration,
        child: Art(art, size: size * (look == BadgeLook.ghost ? 0.4 : 0.44)),
      ),
    );
  }

  static BoxDecoration _lit(
    Color light,
    Color fill,
    Color edge,
    Color lip,
    double width,
  ) => BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 0.82,
      stops: const [0, 0.7],
      colors: [light, fill],
    ),
    border: Border.all(color: edge, width: width),
    boxShadow: [BoxShadow(color: lip, offset: const Offset(0, 8))],
  );
}

/// A badge's picture by id.
// ponytail: Figma's Fluent Emoji placeholders until packs carry badge art;
// keep in step with SolvedView's map in the lesson.
String badgeArt(String id) => switch (id) {
  'tree' => '🌳',
  'asker' => '🙋',
  _ => '⭐',
};
