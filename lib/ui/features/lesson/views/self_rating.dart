import 'package:flutter/material.dart';

import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// Three big faces (AI-08), the prototype's Rate: white tiles with a navy
/// edge and lip, popping in 80 ms apart; the one tapped presses in. No
/// wrong answer, no sad face, and nothing in the lesson changes.
class SelfRating extends StatelessWidget {
  const SelfRating({super.key, required this.vm, this.onRate});

  final LessonViewModel vm;

  /// A face tapped; by default it's only recorded.
  final ValueChanged<String>? onRate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final faces = [
      ('easy', '😎', l.lessonRateEasy),
      ('ok', '🙂', l.lessonRateOk),
      ('tricky', '🤔', l.lessonRateTricky),
    ];
    final given = vm.rating;
    return Row(
      spacing: 14,
      children: [
        for (final (i, (id, face, label)) in faces.indexed)
          Expanded(
            child: Pop(
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: 80 * i),
              child: _Face(
                face: face,
                label: label,
                pressed: given == id,
                onTap: given != null
                    ? null
                    : () {
                        AuraSound.tap();
                        (onRate ?? vm.rate)(id);
                      },
              ),
            ),
          ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.face,
    required this.label,
    required this.pressed,
    required this.onTap,
  });

  final String face;
  final String label;
  final bool pressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        // .tile:active / .pressed: down 4 onto a 2 pt lip
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AuraColors.navy, width: 3),
          boxShadow: [
            BoxShadow(
              color: AuraColors.navy,
              offset: Offset(0, pressed ? 2 : 6),
            ),
          ],
        ),
        // scaled down, never clipped, under large text
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(face, style: const TextStyle(fontSize: 58, height: 1.1)),
              Text(
                label,
                style: AuraText.standing.copyWith(
                  fontSize: 20,
                  color: AuraColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
