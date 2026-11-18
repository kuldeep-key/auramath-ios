import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/casebook_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/board/case_board.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'casebook_screen.dart';
import 'play_icon_button.dart';
import 'reward_moments.dart';

/// CB2 "One case" (REW-15, Figma 1043:11315): the case's name at the top,
/// the child's final drawing on a white card (rebuilt by the server from
/// the event log, drawn with the lesson board's own bars), "Case cracked!"
/// and the case's sticker with the badges it holds: its session's badge
/// and any big badge earned in it (REW-12 opens a badge's case here).
/// The drawing's own numbers only; nothing counted about the child.
class CaseScreen extends StatelessWidget {
  const CaseScreen({
    super.key,
    required this.view,
    this.pictures = const {},
    this.world = 'detective',
  });

  final CaseView view;
  final Map<String, String> pictures;
  final String world;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = caseName(view.entry);
    final badges = [
      if (view.sessionBadge case final b?) (badgeId: b.badgeId, name: b.name),
      for (final b in view.badges) (badgeId: b.badgeId, name: b.name),
    ];
    return AuraPage(
      play: true,
      say: '$name. ${l.caseCracked}',
      top: PlayHeader(title: name),
      body: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Container(
              key: const Key('caseDrawingCard'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: AuraColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AuraColors.navy, width: 3),
                boxShadow: const [
                  BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.kidCaseDrawing.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AuraText.eyebrow.copyWith(
                            color: AuraColors.mute,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (view.drawing case final d?)
                    CaseBoard(drawing: d)
                  else
                    Text(
                      l.kidCaseInYourHead,
                      textAlign: TextAlign.center,
                      style: AuraText.caseLine,
                    ),
                ],
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                l.caseCracked,
                textAlign: TextAlign.center,
                style: AuraText.playTitle.copyWith(color: AuraColors.white),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 12,
              children: [
                _Keep(
                  art: StickerArt(
                    sticker: view.entry.sticker,
                    pictures: pictures,
                    size: 64,
                  ),
                  label: stickerName(view.entry.sticker),
                ),
                for (final b in badges)
                  _Keep(
                    art: BadgeArt(badgeId: b.badgeId, world: world, size: 72),
                    label: b.name,
                  ),
              ],
            ),
          ],
        ),
      ),
      bottom: AuraButton(
        label: l.kidBack,
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(Paths.casebook),
      ),
    );
  }
}

/// Something kept with the case: its sticker or a badge, with its name.
class _Keep extends StatelessWidget {
  const _Keep({required this.art, required this.label});

  final Widget art;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 110,
    child: Column(
      spacing: 6,
      children: [
        SizedBox(height: 72, child: Center(child: art)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AuraText.badgeName.copyWith(fontSize: 16, height: 1.15),
        ),
      ],
    ),
  );
}
