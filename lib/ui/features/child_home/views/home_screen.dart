import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/avatar.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/parts/journey_art.dart';
import 'play_icon_button.dart';

/// The child's home (JRN-02): their look and name small at the top (tap:
/// the Me screen), the Family area lock, their tutor large with its spoken
/// greeting (never the child's name, NFR-08), Keep going, and the Trail and
/// Badges tiles while their switches are on, and My casebook (REW-15). Figma: Home (649:2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.name,
    required this.grownUps,
    this.trail = true,
    this.badges = true,
    this.casebook = false,
    this.play = Paths.lessonNext,
    this.moment,
    this.avatar,
    this.lookId,
    this.world = 'detective',
    this.tutorId,
    this.tutorKind = 'grown_up_teacher',
    this.greeting,
    this.onGreet,
  });

  /// The child's look (`look_01` to `look_08`); with none, the avatar.
  final String? lookId;
  final String world;

  /// The child's tutor and its greeting (`line.home.greeting`, filled);
  /// none: the detective portrait, as before tutors.
  final String? tutorId;
  final String tutorKind;
  final String? greeting;

  /// Speaks the greeting: as Home opens ([tapped] false), and when the
  /// child taps the tutor (TTR-03).
  final void Function({required bool tapped})? onGreet;

  /// The detective the child picked (ACC-12); the portrait until then. The
  /// small one opens the picker.
  final String? avatar;

  /// The child's name; null shows the portrait alone.
  final String? name;

  /// Where the lock goes: the picker on a grown-up's phone, sign-in on the
  /// child's own phone.
  final String grownUps;

  /// My trail and My badges, each behind its flag (`trail`,
  /// `mastery_badges`).
  final bool trail;
  final bool badges;

  /// My casebook (REW-15), behind `casebook`: beside the other two where
  /// there is room, else under them; Home is whole without it.
  final bool casebook;

  /// Where Keep going leads: the next case, or Choose today (LES-14).
  final String play;

  /// What to celebrate on arriving (REW-01's session badge), in place of
  /// some of the big portrait.
  final Widget? moment;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.greeting != null) widget.onGreet?.call(tapped: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final HomeScreen(
      :avatar,
      :name,
      :grownUps,
      :trail,
      :badges,
      :casebook,
      :play,
      :moment,
      :lookId,
      :world,
      :tutorId,
      :greeting,
    ) = widget;
    Widget me(double size) => lookId == null
        ? AvatarDisc(avatar: avatar, size: size)
        : LookPortrait(lookId: lookId, world: world, size: size);
    return AuraPage(
      play: true,
      say: greeting ?? l.readyForNewCase,
      top: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Tooltip(
              message: lookId == null ? l.kidPickAvatar : l.kidMe,
              child: Semantics(
                button: true,
                child: GestureDetector(
                  key: const Key('pickAvatar'),
                  behavior: HitTestBehavior.opaque,
                  // JRN-02: their own look opens the Me screen
                  onTap: () =>
                      context.push(lookId == null ? Paths.avatar : Paths.me),
                  child: SizedBox.square(dimension: 56, child: me(52)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name ?? '',
                overflow: TextOverflow.ellipsis,
                style: AuraText.kidName,
              ),
            ),
            PlayIconButton(
              icon: Icons.lock_rounded,
              tooltip: l.kidForGrownUps,
              onPressed: () => context.go(grownUps),
            ),
          ],
        ),
      ),
      // the prototype's Home: the tutor large and its greeting on the
      // ribbon under it (no bubble: one line, not two)
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: moment == null ? 14 : 12,
        children: [
          if (tutorId != null)
            Semantics(
              button: true,
              label: greeting ?? l.readyForNewCase,
              excludeSemantics: true,
              child: GestureDetector(
                key: const Key('tutor'),
                onTap: () => widget.onGreet?.call(tapped: true),
                child: TutorFigure(
                  tutorId: tutorId,
                  kind: widget.tutorKind,
                  world: world,
                  size: moment == null ? 220 : 110,
                ),
              ),
            )
          else
            Float(child: me(moment == null ? 210 : 120)),
          ?moment,
          Ribbon(text: greeting ?? l.readyForNewCase),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          AuraButton(
            label: l.keepGoing,
            // the prototype's play mark sits before the words
            leading: const Icon(
              Icons.play_arrow_rounded,
              size: 26,
              color: AuraColors.buttonYellowText,
            ),
            onPressed: () => context.go(play),
          ),
          // Figma's icons don't fit beside the labels in a half-width button
          // on a phone; they show where there is room (iPad).
          if (trail || badges || casebook)
            LayoutBuilder(
              builder: (context, c) {
                final roomy = c.maxWidth >= 420;
                final tiles = [
                  if (trail)
                    AuraButton(
                      label: l.kidMyTrail,
                      icon: roomy ? Icons.route_rounded : null,
                      color: AuraButtonColor.white,
                      onPressed: () => context.push(Paths.trail),
                    ),
                  if (badges)
                    AuraButton(
                      label: l.kidMyBadges,
                      icon: roomy ? Icons.military_tech_rounded : null,
                      color: AuraButtonColor.white,
                      onPressed: () => context.push(Paths.badges),
                    ),
                  if (casebook)
                    AuraButton(
                      key: const Key('casebookTile'),
                      label: l.kidMyCasebook,
                      icon: roomy ? Icons.auto_stories_rounded : null,
                      color: AuraButtonColor.white,
                      onPressed: () => context.push(Paths.casebook),
                    ),
                ];
                // three side by side only where each keeps its width (an
                // iPad); on a phone the third goes under the first two
                Widget row(List<Widget> ts) => Row(
                  spacing: 10,
                  children: [for (final t in ts) Expanded(child: t)],
                );
                if (tiles.length < 3 || c.maxWidth >= 3 * 140 + 20) {
                  return row(tiles);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [row(tiles.sublist(0, 2)), tiles[2]],
                );
              },
            ),
        ],
      ),
    );
  }
}
