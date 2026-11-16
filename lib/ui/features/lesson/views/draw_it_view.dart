import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/journey_art.dart';
import '../../../core/parts/speak_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// W1: after an answer that isn't it, no "not yet" and the answer never
/// shown (TUT-11): the tutor, encouraging, asks Julia's "Can you draw the
/// story out?", and "Let's draw" opens the board. Fades in (the
/// prototype's `fade`, 420 ms on the screen curve).
class DrawItView extends StatelessWidget {
  const DrawItView({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title =
        vm.libraryLine('line.quiet.draw-story') ?? l.lessonDrawStoryOut;
    return Positioned.fill(
      child: Entrance(
        duration: const Duration(milliseconds: 420),
        builder: (context, t, child) =>
            Opacity(opacity: AuraCurves.screen.transform(t), child: child),
        child: Material(
          key: const Key('drawIt'),
          color: AuraColors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: SpeakButton(text: '$title ${l.lessonDrawTogether}'),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 18,
                          children: [
                            TutorFigure(
                              tutorId: vm.tutorId,
                              kind: vm.tutorKind,
                              size: 150,
                              state: TutorState.encourage,
                            ),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AuraText.playTitle.copyWith(
                                color: AuraColors.ink,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              l.lessonDrawTogether,
                              textAlign: TextAlign.center,
                              style: AuraText.play.copyWith(
                                color: AuraColors.mute,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width: double.infinity,
                              child: AuraButton(
                                key: const Key('letsDraw'),
                                label: l.lessonLetsDraw,
                                color: AuraButtonColor.blue,
                                onPressed: vm.drawItTaken,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
