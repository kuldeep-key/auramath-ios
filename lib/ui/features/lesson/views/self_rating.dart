import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// "How was this case?" and three big faces (AI-08), then a kind line
/// about checking work. Shown on the blue celebration.
// Draft: no Figma frame yet. Faces rather than stars: stars read as a score.
class SelfRating extends StatelessWidget {
  const SelfRating({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final faces = [
      ('easy', '😀', l.lessonRateEasy, l.lessonRateSaidEasy),
      ('ok', '🙂', l.lessonRateOk, l.lessonRateSaidOk),
      ('tricky', '🤔', l.lessonRateTricky, l.lessonRateSaidTricky),
    ];
    final given = vm.rating;
    if (given != null) {
      return Text(
        faces.firstWhere((f) => f.$1 == given).$4,
        key: const Key('ratingLine'),
        style: AuraText.play,
        textAlign: TextAlign.center,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.lessonRateAsk, style: AuraText.play),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (id, face, label, _) in faces)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _Face(
                  face: face,
                  label: label,
                  onTap: () => vm.rate(id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.face, required this.label, required this.onTap});

  final String face;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: PressScale(
      child: Material(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(AuraRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AuraRadii.card),
          onTap: onTap,
          child: SizedBox(
            width: 88,
            height: 96,
            // scaled down, never clipped, under large text
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(face, style: const TextStyle(fontSize: 40)),
                  Text(label, style: AuraText.small),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
